`timescale 1ns / 1ps
// =============================================================
//  Cardinal CPU — 6-stage pipeline, timing-optimized
//
//    IF  : PC -> imem (async)            -> IF/ID
//    ID  : decode, regfile read, bypass   -> ID/EX
//    EX  : ALU / SFU (multi-cycle), branch resolve, address add -> EX/MEM
//    MEM : dmem / NIC request driven straight from EX/MEM flops
//    WB  : load data (dmem / NIC) captured                       -> WB/RF
//    RF  : register-file write
//
//  Timing rules this pipeline is built around:
//   * every output port is driven directly by a flip-flop
//     (imem_pc_out = PC, dmem/NIC request = EX/MEM register)
//   * every input port goes into a flip-flop through at most one mux
//     (inst_in -> IF/ID, dmem_data_out/d_out -> WB/RF register)
//   * bypassing only uses pipeline registers (EX/MEM, MEM/WB, WB/RF),
//     never the combinational ALU output; dependencies on the
//     instruction in EX, or on a load still in flight, stall in ID
//   * branches resolve in EX from the ID/EX register (2-cycle penalty)
//   * multiply/divide/sqrt run in the iterative SFU; EX stalls until done
//   * reset is re-timed locally, data-path registers carry no reset
// =============================================================
module cardinal_cpu(
    input         clk, reset,
    input  [31:0] inst_in,        // from imem
    input  [63:0] dmem_data_out,  // come from data memory
    output [31:0] imem_pc_out,    // go to imem
    output [31:0] dmem_addr_out,  // address go to datamem
    output        memEn, memWrEn, // control signal go to data memory
    output [63:0] dmem_data_in,   // data go to data memory
    // signal to NIC
    output [0:1]  addr,
    output [0:63] d_in,
    input  [0:63] d_out,
    output        nicEn,
    output        nicEnWr
);

localparam OP_RTYPE = 6'b101010, OP_VLD = 6'b100000, OP_VSD = 6'b100001,
           OP_VBEZ  = 6'b100010, OP_VBNEZ = 6'b100011;

// ============================================================
//  Local reset (one flop per core; the global reset only has to
//  reach this register, the core-wide fan-out is a reg->reg path)
// ============================================================
reg rst;
always @(posedge clk) rst <= reset;

// ============================================================
//  Pipeline registers
// ============================================================
// IF/ID
reg [31:0] PC;
reg [31:0] IF_ID_inst;

// ID/EX
reg [63:0] ID_EX_A, ID_EX_B;        // A = rA (rD for VSD/branches), B = rB (rA for VSD)
reg [15:0] ID_EX_imm;
reg [4:0]  ID_EX_rd;
reg [1:0]  ID_EX_ww;
reg [5:0]  ID_EX_func;
reg        ID_EX_regWrite, ID_EX_is_load, ID_EX_is_store, ID_EX_is_nic;
reg        ID_EX_is_branch, ID_EX_br_nez, ID_EX_is_sfu;
reg [2:0]  ID_EX_sfu_op;

// EX/MEM
reg [63:0] EX_MEM_data;             // ALU/SFU result, or store data
reg [31:0] EX_MEM_addr;
reg [4:0]  EX_MEM_rd;
reg [1:0]  EX_MEM_nic_addr;
reg        EX_MEM_regWrite, EX_MEM_is_load;
reg        EX_MEM_memEn, EX_MEM_memWrEn, EX_MEM_nicEn, EX_MEM_nicWrEn;

// MEM/WB
reg [63:0] MEM_WB_data;
reg [4:0]  MEM_WB_rd;
reg        MEM_WB_regWrite, MEM_WB_is_load, MEM_WB_is_nic;

// WB/RF
reg [63:0] WB_RF_data;
reg [4:0]  WB_RF_rd;
reg        WB_RF_regWrite;

// ============================================================
//  ID Stage: decode
// ============================================================
wire [0:31] id_inst = IF_ID_inst;
wire [0:5]  opcode  = id_inst[0:5];
wire [4:0]  rD_addr = id_inst[6:10];
wire [4:0]  rA_addr = id_inst[11:15];
wire [4:0]  rB_field= id_inst[16:20];
wire [1:0]  ww      = id_inst[24:25];
wire [5:0]  func    = id_inst[26:31];
wire [15:0] imm     = id_inst[16:31];

wire is_rtype  = (opcode == OP_RTYPE);
wire is_load   = (opcode == OP_VLD);
wire is_store  = (opcode == OP_VSD);
wire is_branch = (opcode == OP_VBEZ) || (opcode == OP_VBNEZ);
wire is_nic    = imm[15] & imm[14];

// A port reads rD for VSD / branches, B port reads rA for VSD
wire [4:0] raA  = (is_store || is_branch) ? rD_addr : rA_addr;
wire [4:0] raB  = is_store ? rA_addr : rB_field;
wire       useA = is_rtype || is_load || is_store || is_branch;
wire       useB = is_rtype || is_store;

reg       is_sfu;
reg [2:0] sfu_op;
always @(*) begin
    is_sfu = is_rtype;
    case (func)
        6'b001110: sfu_op = 3'd0;  // VDIV
        6'b001111: sfu_op = 3'd1;  // VMOD
        6'b010010: sfu_op = 3'd2;  // VSQRT
        6'b001000: sfu_op = 3'd3;  // VMULEU
        6'b001001: sfu_op = 3'd4;  // VMULOU
        6'b010000: sfu_op = 3'd5;  // VSQEU
        6'b010001: sfu_op = 3'd6;  // VSQOU
        default: begin sfu_op = 3'd0; is_sfu = 1'b0; end
    endcase
end

// r0 is never written, so folding (rd != 0) into regWrite makes every
// later rd comparison automatically ignore r0.
wire id_regWrite = (is_rtype || is_load) && (rD_addr != 5'd0);

// ============================================================
//  ID Stage: register file + bypass from pipeline registers
// ============================================================
wire [63:0] rf_A, rf_B;

register_file regfile(
    .reset (rst),
    .clk   (clk),
    .wrEn  (WB_RF_regWrite),
    .addrA (raA),
    .addrB (raB),
    .waddr (WB_RF_rd),
    .data  (WB_RF_data),
    .dataA (rf_A),
    .dataB (rf_B)
);

wire mA = EX_MEM_regWrite && (EX_MEM_rd == raA);
wire wA = MEM_WB_regWrite && (MEM_WB_rd == raA);
wire fA = WB_RF_regWrite  && (WB_RF_rd  == raA);
wire mB = EX_MEM_regWrite && (EX_MEM_rd == raB);
wire wB = MEM_WB_regWrite && (MEM_WB_rd == raB);
wire fB = WB_RF_regWrite  && (WB_RF_rd  == raB);

wire [63:0] id_A = mA ? EX_MEM_data : wA ? MEM_WB_data : fA ? WB_RF_data : rf_A;
wire [63:0] id_B = mB ? EX_MEM_data : wB ? MEM_WB_data : fB ? WB_RF_data : rf_B;

// Hazards: producer still in EX, or a load whose data is not yet in a register
wire hazA = useA && ((ID_EX_regWrite && ID_EX_rd == raA) ||
                     (mA && EX_MEM_is_load) || (wA && MEM_WB_is_load));
wire hazB = useB && ((ID_EX_regWrite && ID_EX_rd == raB) ||
                     (mB && EX_MEM_is_load) || (wB && MEM_WB_is_load));

// ============================================================
//  EX Stage
// ============================================================
wire [63:0] alu_result, sfu_result;
wire        sfu_done;

alu u_alu (
    .rA     (ID_EX_A),
    .rB     (ID_EX_B),
    .ww     (ID_EX_ww),
    .func   (ID_EX_func),
    .result (alu_result)
);

sfu u_sfu (
    .clk    (clk),
    .reset  (rst),
    .start  (ID_EX_is_sfu),
    .op     (ID_EX_sfu_op),
    .ww     (ID_EX_ww),
    .rA     (ID_EX_A),
    .rB     (ID_EX_B),
    .done   (sfu_done),
    .result (sfu_result)
);

wire ex_stall = ID_EX_is_sfu && !sfu_done;
wire id_stall = hazA || hazB || ex_stall;

wire ex_br_taken = ID_EX_is_branch && (ID_EX_br_nez ? (ID_EX_A != 64'b0) : (ID_EX_A == 64'b0));

wire [31:0] ex_base = ID_EX_is_store ? ID_EX_B[31:0] : ID_EX_A[31:0];
wire [31:0] ex_addr = ex_base + {16'b0, ID_EX_imm};
wire [63:0] ex_data = ID_EX_is_store ? ID_EX_A : (ID_EX_is_sfu ? sfu_result : alu_result);

// ============================================================
//  IF Stage / PC
// ============================================================
assign imem_pc_out = PC << 2;

always @(posedge clk) begin
    if (rst)
        PC <= 32'b0;
    else if (ex_br_taken)
        PC <= {16'b0, ID_EX_imm};
    else if (!id_stall)
        PC <= PC + 32'd1;
end

always @(posedge clk) begin
    if (rst || ex_br_taken)
        IF_ID_inst <= 32'b0;          // opcode 000000 = bubble
    else if (!id_stall)
        IF_ID_inst <= inst_in;
end

// ============================================================
//  ID/EX register
// ============================================================
wire id_bubble = id_stall || ex_br_taken;   // (when ex_stall, ID/EX holds instead)

always @(posedge clk) begin
    if (rst || (id_bubble && !ex_stall)) begin
        ID_EX_regWrite  <= 1'b0;
        ID_EX_is_load   <= 1'b0;
        ID_EX_is_store  <= 1'b0;
        ID_EX_is_branch <= 1'b0;
        ID_EX_is_sfu    <= 1'b0;
        ID_EX_rd        <= 5'b0;
    end else if (!ex_stall) begin
        ID_EX_regWrite  <= id_regWrite;
        ID_EX_is_load   <= is_load;
        ID_EX_is_store  <= is_store;
        ID_EX_is_branch <= is_branch;
        ID_EX_is_sfu    <= is_sfu;
        ID_EX_rd        <= rD_addr;
    end
end

always @(posedge clk) begin
    if (!ex_stall) begin
        ID_EX_A      <= id_A;
        ID_EX_B      <= id_B;
        ID_EX_imm    <= imm;
        ID_EX_ww     <= ww;
        ID_EX_func   <= func;
        ID_EX_is_nic <= is_nic;
        ID_EX_br_nez <= (opcode == OP_VBNEZ);
        ID_EX_sfu_op <= sfu_op;
    end
end

// ============================================================
//  EX/MEM register  (drives dmem / NIC ports directly)
// ============================================================
always @(posedge clk) begin
    if (rst || ex_stall) begin
        EX_MEM_regWrite <= 1'b0;
        EX_MEM_is_load  <= 1'b0;
        EX_MEM_memEn    <= 1'b0;
        EX_MEM_memWrEn  <= 1'b0;
        EX_MEM_nicEn    <= 1'b0;
        EX_MEM_nicWrEn  <= 1'b0;
    end else begin
        EX_MEM_regWrite <= ID_EX_regWrite;
        EX_MEM_is_load  <= ID_EX_is_load;
        EX_MEM_memEn    <= (ID_EX_is_load || ID_EX_is_store) && !ID_EX_is_nic;
        EX_MEM_memWrEn  <= ID_EX_is_store && !ID_EX_is_nic;
        EX_MEM_nicEn    <= (ID_EX_is_load || ID_EX_is_store) && ID_EX_is_nic;
        EX_MEM_nicWrEn  <= ID_EX_is_store && ID_EX_is_nic;
    end
end

always @(posedge clk) begin
    EX_MEM_data     <= ex_data;
    EX_MEM_addr     <= ex_addr;
    EX_MEM_rd       <= ID_EX_rd;
    EX_MEM_nic_addr <= ID_EX_imm[1:0];
end

assign dmem_addr_out = EX_MEM_addr;
assign memEn         = EX_MEM_memEn;
assign memWrEn       = EX_MEM_memWrEn;
assign dmem_data_in  = EX_MEM_data;

assign addr          = EX_MEM_nic_addr;
assign d_in          = EX_MEM_data;
assign nicEn         = EX_MEM_nicEn;
assign nicEnWr       = EX_MEM_nicWrEn;

// ============================================================
//  MEM/WB register
// ============================================================
always @(posedge clk) begin
    if (rst) begin
        MEM_WB_regWrite <= 1'b0;
        MEM_WB_is_load  <= 1'b0;
    end else begin
        MEM_WB_regWrite <= EX_MEM_regWrite;
        MEM_WB_is_load  <= EX_MEM_is_load;
    end
end

always @(posedge clk) begin
    MEM_WB_data   <= EX_MEM_data;
    MEM_WB_rd     <= EX_MEM_rd;
    MEM_WB_is_nic <= EX_MEM_nicEn;
end

// ============================================================
//  WB/RF register: capture load data (one mux after the input port)
// ============================================================
wire [63:0] load_data = MEM_WB_is_nic ? d_out : dmem_data_out;

always @(posedge clk) begin
    if (rst)
        WB_RF_regWrite <= 1'b0;
    else
        WB_RF_regWrite <= MEM_WB_regWrite;
end

always @(posedge clk) begin
    WB_RF_data <= MEM_WB_is_load ? load_data : MEM_WB_data;
    WB_RF_rd   <= MEM_WB_rd;
end

endmodule
