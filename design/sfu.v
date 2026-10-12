`timescale 1ns / 1ps
// =============================================================
//  Cardinal Processor — SFU (Special Function Unit)
//  Iterative, sub-word-parallel (SIMD) multi-cycle unit.
//  Handles VDIV / VMOD / VSQRT and VMULEU / VMULOU / VSQEU / VSQOU.
//
//  One shared 64-bit lane-partitioned add/sub datapath (radix-2):
//    divide  : restoring division,  1 quotient bit / cycle / lane
//    sqrt    : digit-by-digit,      1 root bit     / cycle / lane
//    multiply: shift-and-add,       1 multiplier bit / cycle / lane
//  All lanes of the selected width are processed in parallel, so the
//  latency only depends on the lane width (8..64 iterations).
//
//  Handshake: the CPU holds rA/rB/op/ww stable in ID/EX while the
//  unit is busy, keeps `start` high, and advances when `done` = 1.
// =============================================================
module sfu (
    input             clk,
    input             reset,
    input             start,    // SFU instruction is waiting in EX
    input      [2:0]  op,       // see OP_* below
    input      [1:0]  ww,       // 00=8b 01=16b 10=32b 11=64b
    input      [63:0] rA,
    input      [63:0] rB,
    output            done,     // result valid this cycle
    output reg [63:0] result
);

localparam OP_DIV  = 3'd0;  // VDIV
localparam OP_MOD  = 3'd1;  // VMOD
localparam OP_SQRT = 3'd2;  // VSQRT
localparam OP_MULE = 3'd3;  // VMULEU
localparam OP_MULO = 3'd4;  // VMULOU
localparam OP_SQE  = 3'd5;  // VSQEU
localparam OP_SQO  = 3'd6;  // VSQOU

localparam S_IDLE = 2'd0, S_BUSY = 2'd1, S_DONE = 2'd2;

reg  [1:0]  state;
reg  [5:0]  cnt;
reg  [63:0] R;   // remainder / accumulator
reg  [63:0] Q;   // dividend / radicand / multiplier shift register (quotient enters at lsb)
reg  [63:0] S;   // square root

// Op decode (used in the load cycle)
wire d_div   = (op == OP_DIV) || (op == OP_MOD);
wire d_sqrt  = (op == OP_SQRT);
wire d_mul   = !d_div && !d_sqrt;                 // MULE/MULO/SQE/SQO
wire d_odd   = (op == OP_MULO) || (op == OP_SQO);
wire square  = (op == OP_SQE)  || (op == OP_SQO);

// Lane partition of the datapath: div/sqrt use the operand width,
// multiplies produce double-width lanes.
wire [1:0] d_pw = d_mul ? (ww + 2'd1) : ww;

// The decode is registered at load time so the per-iteration path
// starts from flops instead of going through the op decode.
reg       c_div, c_sqrt, c_mul, c_odd;
reg [1:0] c_pw;
always @(posedge clk)
    if (state == S_IDLE) begin
        c_div <= d_div; c_sqrt <= d_sqrt; c_mul <= d_mul; c_odd <= d_odd; c_pw <= d_pw;
    end

// Iteration datapath: registered controls only
wire       is_div  = c_div;
wire       is_sqrt = c_sqrt;
wire       is_mul  = c_mul;
wire       odd     = c_odd;
wire [1:0] pw      = c_pw;

// -------------------------------------------------------------
// Lane masks for the active partition
// -------------------------------------------------------------
reg [63:0] lsbm, msbm, lowm;   // lane LSB bits, lane MSB bits, lower half of each lane
integer i;
always @(*) begin
    for (i = 0; i < 64; i = i + 1) begin
        case (pw)
            2'd0: begin lsbm[i] = (i % 8)  == 0; msbm[i] = (i % 8)  == 7;  lowm[i] = (i % 8)  < 4;  end
            2'd1: begin lsbm[i] = (i % 16) == 0; msbm[i] = (i % 16) == 15; lowm[i] = (i % 16) < 8;  end
            2'd2: begin lsbm[i] = (i % 32) == 0; msbm[i] = (i % 32) == 31; lowm[i] = (i % 32) < 16; end
            default: begin lsbm[i] = (i == 0); msbm[i] = (i == 63); lowm[i] = (i < 32); end
        endcase
    end
end

// Move each lane's MSB-side bit(s) of v down to that lane's LSB position.
function [63:0] lane_top_to_lsb;   // bit (lane_msb - off) -> lane_lsb
    input [63:0] v;
    input [1:0]  w;
    input        off;
    integer j;
    begin
        lane_top_to_lsb = 64'b0;
        for (j = 0; j < 64; j = j + 8) begin
            case (w)
                2'd0: lane_top_to_lsb[j] = v[j + 7 - off];
                2'd1: if (j % 16 == 0) lane_top_to_lsb[j] = v[j + 15 - off];
                2'd2: if (j % 32 == 0) lane_top_to_lsb[j] = v[j + 31 - off];
                default: if (j == 0)   lane_top_to_lsb[j] = v[63 - off];
            endcase
        end
    end
endfunction

// Expand a per-lane flag (held at lane MSB-byte separator) to every bit of its lane.
function [63:0] lane_fill;
    input [7:0] f;      // f[k] = flag of the lane whose top byte is k
    input [1:0] w;
    integer k;
    begin
        for (k = 0; k < 8; k = k + 1) begin
            case (w)
                2'd0: lane_fill[k*8 +: 8] = {8{f[k]}};
                2'd1: lane_fill[k*8 +: 8] = {8{f[k | 1]}};
                2'd2: lane_fill[k*8 +: 8] = {8{f[k | 3]}};
                default: lane_fill[k*8 +: 8] = {8{f[7]}};
            endcase
        end
    end
endfunction

// -------------------------------------------------------------
// Operand preparation
// -------------------------------------------------------------
wire [63:0] rlo = ~lsbm;                  // clears lane LSB after <<1
wire [63:0] rlo2 = ~(lsbm | (lsbm << 1)); // clears 2 lane LSBs after <<2

// Multiply: multiplicand X = selected half, zero-extended in its lane;
// multiplier half is pre-aligned to the lane MSB side of Q.
wire [63:0] mul_b = square ? rA : rB;
reg  [63:0] X, Qmul;
always @(*) begin
    case (pw)   // shift by half a lane (pw >= 1 for valid multiplies)
        2'd1:    X = odd ? rA : (rA >> 8);
        2'd2:    X = odd ? rA : (rA >> 16);
        default: X = odd ? rA : (rA >> 32);
    endcase
    X = X & lowm;
end

// load cycle: uses the live decode
integer qi;
always @(*) begin
    case (d_pw)
        2'd1:    Qmul = d_odd ? (mul_b << 8)  : mul_b;
        2'd2:    Qmul = d_odd ? (mul_b << 16) : mul_b;
        default: Qmul = d_odd ? (mul_b << 32) : mul_b;
    endcase
    for (qi = 0; qi < 64; qi = qi + 1)   // keep the upper half of each lane
        case (d_pw)
            2'd1:    if ((qi % 16) < 8)  Qmul[qi] = 1'b0;
            2'd2:    if ((qi % 32) < 16) Qmul[qi] = 1'b0;
            default: if (qi < 32)        Qmul[qi] = 1'b0;
        endcase
end

// Shifted remainder (R1) and subtrahend/addend (Y)
wire [63:0] q_msb  = lane_top_to_lsb(Q, pw, 1'b0);
wire [63:0] q_msb2 = lane_top_to_lsb(Q, pw, 1'b1);
wire [63:0] r_ovf  = R & msbm;  // bit lost by R << 1 (division)

wire [63:0] R1_div = ((R << 1) & rlo) | (is_div ? q_msb : 64'b0);
wire [63:0] R1_sq  = ((R << 2) & rlo2) | (q_msb << 1) | q_msb2;
wire [63:0] R1     = is_sqrt ? R1_sq : R1_div;

wire [63:0] T      = ((S << 2) & rlo2) | lsbm;          // sqrt trial (root<<2)|1
wire [63:0] bmask  = lane_fill_msb(Q & msbm, pw);       // multiplier bit of each lane
wire [63:0] Y      = is_div ? rB : is_sqrt ? T : (X & bmask);

function [63:0] lane_fill_msb;  // replicate each lane's MSB bit over the lane
    input [63:0] v;
    input [1:0]  w;
    reg   [7:0]  f;
    integer k;
    begin
        for (k = 0; k < 8; k = k + 1) f[k] = v[k*8 + 7];
        lane_fill_msb = lane_fill(f, w);
    end
endfunction

// -------------------------------------------------------------
// Lane-partitioned adder: 8 byte slices separated by guard bits.
//   boundary guard (sub,sub): kills carry from below and injects +1
//   inner    guard (1,0)    : propagates carry
//   guard sum bit           : carry-out of the byte below it
// -------------------------------------------------------------
wire sub = !is_mul;
reg [71:0] ax, ay;
integer b;
always @(*) begin
    for (b = 0; b < 8; b = b + 1) begin
        ax[b*9 +: 8] = R1[b*8 +: 8];
        ay[b*9 +: 8] = sub ? ~Y[b*8 +: 8] : Y[b*8 +: 8];
        if (b == 7 || (pw == 2'd0) || (pw == 2'd1 && b % 2 == 1) || (pw == 2'd2 && b % 4 == 3)) begin
            ax[b*9 + 8] = sub; ay[b*9 + 8] = sub;
        end else begin
            ax[b*9 + 8] = 1'b1; ay[b*9 + 8] = 1'b0;
        end
    end
end
wire [71:0] asum = ax + ay + {71'b0, sub};

reg [63:0] D;
reg [7:0]  cout;   // carry-out of each byte (valid at lane-top bytes)
always @(*) begin
    for (b = 0; b < 8; b = b + 1) begin
        D[b*8 +: 8] = asum[b*9 +: 8];
        cout[b]     = asum[b*9 + 8];
    end
end

// take = (R1 >= Y) for this lane; division also takes on R<<1 overflow
wire [63:0] ovf_fill = lane_fill_msb(r_ovf, pw);
wire [63:0] take     = lane_fill(cout, pw) | (is_div ? ovf_fill : 64'b0);
wire [63:0] take_lsb = take & lsbm;

// -------------------------------------------------------------
// Iteration control
// -------------------------------------------------------------
wire mul_unsupported = is_mul && (ww == 2'b11);
reg [5:0] n_iter;
always @(*) begin
    case (ww)
        2'd0: n_iter = d_sqrt ? 6'd3  : 6'd7;
        2'd1: n_iter = d_sqrt ? 6'd7  : 6'd15;
        2'd2: n_iter = d_sqrt ? 6'd15 : 6'd31;
        default: n_iter = d_sqrt ? 6'd31 : (d_mul ? 6'd0 : 6'd63);
    endcase
end

assign done = (state == S_DONE);

always @(posedge clk) begin
    if (reset)
        state <= S_IDLE;
    else case (state)
        S_IDLE: if (start) state <= S_BUSY;
        S_BUSY: if (cnt == 6'd0) state <= S_DONE;
        default: state <= S_IDLE;
    endcase
end

// Datapath registers need no reset: they are always loaded before use.
always @(posedge clk) begin
    if (state == S_IDLE) begin
        cnt <= n_iter;
        R   <= 64'b0;
        S   <= 64'b0;
        Q   <= d_mul ? Qmul : rA;
    end else if (state == S_BUSY) begin
        cnt <= cnt - 6'd1;
        if (is_mul) begin
            R <= D;
            Q <= (Q << 1) & rlo;
        end else if (is_sqrt) begin
            R <= (take & D) | (~take & R1);
            Q <= (Q << 2) & rlo2;
            S <= ((S << 1) & rlo) | take_lsb;
        end else begin
            R <= (take & D) | (~take & R1);
            Q <= ((Q << 1) & rlo) | take_lsb;
        end
    end
end

always @(*) begin
    case (op)
        OP_DIV:  result = Q;
        OP_MOD:  result = R;
        OP_SQRT: result = S;
        default: result = mul_unsupported ? 64'b0 : R;
    endcase
end

endmodule
