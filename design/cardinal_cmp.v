module cardinal_cmp(
    input clk,
    input reset,


    // Node 00
    output [31:0] imem_addr_00, input  [31:0] imem_data_00,
    output [31:0] dmem_addr_00, input  [63:0] dmem_data_out_00, 
	output [63:0] dmem_data_in_00, output dmem_wrEn_00, output dmem_en_00,
	
    // Node 01
    output [31:0] imem_addr_01, input  [31:0] imem_data_01,
    output [31:0] dmem_addr_01, input  [63:0] dmem_data_out_01, 
	output [63:0] dmem_data_in_01, output dmem_wrEn_01, output dmem_en_01,
	
    // Node 02
    output [31:0] imem_addr_02, input  [31:0] imem_data_02,
    output [31:0] dmem_addr_02, input  [63:0] dmem_data_out_02, 
	output [63:0] dmem_data_in_02, output dmem_wrEn_02, output dmem_en_02,
	
    // Node 03
    output [31:0] imem_addr_03, input  [31:0] imem_data_03,
    output [31:0] dmem_addr_03, input  [63:0] dmem_data_out_03, 
	output [63:0] dmem_data_in_03, output dmem_wrEn_03, output dmem_en_03,

    // Node 10
    output [31:0] imem_addr_10, input  [31:0] imem_data_10,
    output [31:0] dmem_addr_10, input  [63:0] dmem_data_out_10, 
	output [63:0] dmem_data_in_10, output dmem_wrEn_10, output dmem_en_10,
	
    // Node 11
    output [31:0] imem_addr_11, input  [31:0] imem_data_11,
    output [31:0] dmem_addr_11, input  [63:0] dmem_data_out_11, 
	output [63:0] dmem_data_in_11, output dmem_wrEn_11, output dmem_en_11,
	
    // Node 12
    output [31:0] imem_addr_12, input  [31:0] imem_data_12,
    output [31:0] dmem_addr_12, input  [63:0] dmem_data_out_12, 
	output [63:0] dmem_data_in_12, output dmem_wrEn_12, output dmem_en_12,
	
    // Node 13
    output [31:0] imem_addr_13, input  [31:0] imem_data_13,
    output [31:0] dmem_addr_13, input  [63:0] dmem_data_out_13, 
	output [63:0] dmem_data_in_13, output dmem_wrEn_13, output dmem_en_13,

    // Node 20
    output [31:0] imem_addr_20, input  [31:0] imem_data_20,
    output [31:0] dmem_addr_20, input  [63:0] dmem_data_out_20, 
	output [63:0] dmem_data_in_20, output dmem_wrEn_20, output dmem_en_20,
	
    // Node 21
    output [31:0] imem_addr_21, input  [31:0] imem_data_21,
    output [31:0] dmem_addr_21, input  [63:0] dmem_data_out_21, 
	output [63:0] dmem_data_in_21, output dmem_wrEn_21, output dmem_en_21,
	
    // Node 22
    output [31:0] imem_addr_22, input  [31:0] imem_data_22,
    output [31:0] dmem_addr_22, input  [63:0] dmem_data_out_22, 
	output [63:0] dmem_data_in_22, output dmem_wrEn_22, output dmem_en_22,
	
    // Node 23
    output [31:0] imem_addr_23, input  [31:0] imem_data_23,
    output [31:0] dmem_addr_23, input  [63:0] dmem_data_out_23, 
	output [63:0] dmem_data_in_23, output dmem_wrEn_23, output dmem_en_23,

    // Node 30
    output [31:0] imem_addr_30, input  [31:0] imem_data_30,
    output [31:0] dmem_addr_30, input  [63:0] dmem_data_out_30, 
	output [63:0] dmem_data_in_30, output dmem_wrEn_30, output dmem_en_30,
	
    // Node 31
    output [31:0] imem_addr_31, input  [31:0] imem_data_31,
    output [31:0] dmem_addr_31, input  [63:0] dmem_data_out_31, 
	output [63:0] dmem_data_in_31, output dmem_wrEn_31, output dmem_en_31,
	
    // Node 32
    output [31:0] imem_addr_32, input  [31:0] imem_data_32,
    output [31:0] dmem_addr_32, input  [63:0] dmem_data_out_32, 
	output [63:0] dmem_data_in_32, output dmem_wrEn_32, output dmem_en_32,
	
    // Node 33
    output [31:0] imem_addr_33, input  [31:0] imem_data_33,
    output [31:0] dmem_addr_33, input  [63:0] dmem_data_out_33, 
	output [63:0] dmem_data_in_33, output dmem_wrEn_33, output dmem_en_33
);


    wire n00_pesi, n00_peri, n00_peso, n00_pero, n00_pol; wire [63:0] n00_pedi, n00_pedo; wire [1:0] nic_a_00; wire [63:0] nic_din_00, nic_dout_00; wire nic_en_00, nic_wen_00;
    wire n01_pesi, n01_peri, n01_peso, n01_pero, n01_pol; wire [63:0] n01_pedi, n01_pedo; wire [1:0] nic_a_01; wire [63:0] nic_din_01, nic_dout_01; wire nic_en_01, nic_wen_01;
    wire n02_pesi, n02_peri, n02_peso, n02_pero, n02_pol; wire [63:0] n02_pedi, n02_pedo; wire [1:0] nic_a_02; wire [63:0] nic_din_02, nic_dout_02; wire nic_en_02, nic_wen_02;
    wire n03_pesi, n03_peri, n03_peso, n03_pero, n03_pol; wire [63:0] n03_pedi, n03_pedo; wire [1:0] nic_a_03; wire [63:0] nic_din_03, nic_dout_03; wire nic_en_03, nic_wen_03;
		 
    wire n10_pesi, n10_peri, n10_peso, n10_pero, n10_pol; wire [63:0] n10_pedi, n10_pedo; wire [1:0] nic_a_10; wire [63:0] nic_din_10, nic_dout_10; wire nic_en_10, nic_wen_10;
    wire n11_pesi, n11_peri, n11_peso, n11_pero, n11_pol; wire [63:0] n11_pedi, n11_pedo; wire [1:0] nic_a_11; wire [63:0] nic_din_11, nic_dout_11; wire nic_en_11, nic_wen_11;
    wire n12_pesi, n12_peri, n12_peso, n12_pero, n12_pol; wire [63:0] n12_pedi, n12_pedo; wire [1:0] nic_a_12; wire [63:0] nic_din_12, nic_dout_12; wire nic_en_12, nic_wen_12;
    wire n13_pesi, n13_peri, n13_peso, n13_pero, n13_pol; wire [63:0] n13_pedi, n13_pedo; wire [1:0] nic_a_13; wire [63:0] nic_din_13, nic_dout_13; wire nic_en_13, nic_wen_13;
		 
    wire n20_pesi, n20_peri, n20_peso, n20_pero, n20_pol; wire [63:0] n20_pedi, n20_pedo; wire [1:0] nic_a_20; wire [63:0] nic_din_20, nic_dout_20; wire nic_en_20, nic_wen_20;
    wire n21_pesi, n21_peri, n21_peso, n21_pero, n21_pol; wire [63:0] n21_pedi, n21_pedo; wire [1:0] nic_a_21; wire [63:0] nic_din_21, nic_dout_21; wire nic_en_21, nic_wen_21;
    wire n22_pesi, n22_peri, n22_peso, n22_pero, n22_pol; wire [63:0] n22_pedi, n22_pedo; wire [1:0] nic_a_22; wire [63:0] nic_din_22, nic_dout_22; wire nic_en_22, nic_wen_22;
    wire n23_pesi, n23_peri, n23_peso, n23_pero, n23_pol; wire [63:0] n23_pedi, n23_pedo; wire [1:0] nic_a_23; wire [63:0] nic_din_23, nic_dout_23; wire nic_en_23, nic_wen_23;
		 
    wire n30_pesi, n30_peri, n30_peso, n30_pero, n30_pol; wire [63:0] n30_pedi, n30_pedo; wire [1:0] nic_a_30; wire [63:0] nic_din_30, nic_dout_30; wire nic_en_30, nic_wen_30;
    wire n31_pesi, n31_peri, n31_peso, n31_pero, n31_pol; wire [63:0] n31_pedi, n31_pedo; wire [1:0] nic_a_31; wire [63:0] nic_din_31, nic_dout_31; wire nic_en_31, nic_wen_31;
    wire n32_pesi, n32_peri, n32_peso, n32_pero, n32_pol; wire [63:0] n32_pedi, n32_pedo; wire [1:0] nic_a_32; wire [63:0] nic_din_32, nic_dout_32; wire nic_en_32, nic_wen_32;
    wire n33_pesi, n33_peri, n33_peso, n33_pero, n33_pol; wire [63:0] n33_pedi, n33_pedo; wire [1:0] nic_a_33; wire [63:0] nic_din_33, nic_dout_33; wire nic_en_33, nic_wen_33;



    cardinal_mesh mesh (
        .clk(clk), .reset(reset),
        
        .node00_pesi(n00_pesi), .node00_peri(n00_peri), .node00_pedi(n00_pedi), .node00_peso(n00_peso), .node00_pero(n00_pero), .node00_pedo(n00_pedo), .node00_polarity(n00_pol),
        .node01_pesi(n01_pesi), .node01_peri(n01_peri), .node01_pedi(n01_pedi), .node01_peso(n01_peso), .node01_pero(n01_pero), .node01_pedo(n01_pedo), .node01_polarity(n01_pol),
        .node02_pesi(n02_pesi), .node02_peri(n02_peri), .node02_pedi(n02_pedi), .node02_peso(n02_peso), .node02_pero(n02_pero), .node02_pedo(n02_pedo), .node02_polarity(n02_pol),
        .node03_pesi(n03_pesi), .node03_peri(n03_peri), .node03_pedi(n03_pedi), .node03_peso(n03_peso), .node03_pero(n03_pero), .node03_pedo(n03_pedo), .node03_polarity(n03_pol),

        .node10_pesi(n10_pesi), .node10_peri(n10_peri), .node10_pedi(n10_pedi), .node10_peso(n10_peso), .node10_pero(n10_pero), .node10_pedo(n10_pedo), .node10_polarity(n10_pol),
        .node11_pesi(n11_pesi), .node11_peri(n11_peri), .node11_pedi(n11_pedi), .node11_peso(n11_peso), .node11_pero(n11_pero), .node11_pedo(n11_pedo), .node11_polarity(n11_pol),
        .node12_pesi(n12_pesi), .node12_peri(n12_peri), .node12_pedi(n12_pedi), .node12_peso(n12_peso), .node12_pero(n12_pero), .node12_pedo(n12_pedo), .node12_polarity(n12_pol),
        .node13_pesi(n13_pesi), .node13_peri(n13_peri), .node13_pedi(n13_pedi), .node13_peso(n13_peso), .node13_pero(n13_pero), .node13_pedo(n13_pedo), .node13_polarity(n13_pol),

        .node20_pesi(n20_pesi), .node20_peri(n20_peri), .node20_pedi(n20_pedi), .node20_peso(n20_peso), .node20_pero(n20_pero), .node20_pedo(n20_pedo), .node20_polarity(n20_pol),
        .node21_pesi(n21_pesi), .node21_peri(n21_peri), .node21_pedi(n21_pedi), .node21_peso(n21_peso), .node21_pero(n21_pero), .node21_pedo(n21_pedo), .node21_polarity(n21_pol),
        .node22_pesi(n22_pesi), .node22_peri(n22_peri), .node22_pedi(n22_pedi), .node22_peso(n22_peso), .node22_pero(n22_pero), .node22_pedo(n22_pedo), .node22_polarity(n22_pol),
        .node23_pesi(n23_pesi), .node23_peri(n23_peri), .node23_pedi(n23_pedi), .node23_peso(n23_peso), .node23_pero(n23_pero), .node23_pedo(n23_pedo), .node23_polarity(n23_pol),

        .node30_pesi(n30_pesi), .node30_peri(n30_peri), .node30_pedi(n30_pedi), .node30_peso(n30_peso), .node30_pero(n30_pero), .node30_pedo(n30_pedo), .node30_polarity(n30_pol),
        .node31_pesi(n31_pesi), .node31_peri(n31_peri), .node31_pedi(n31_pedi), .node31_peso(n31_peso), .node31_pero(n31_pero), .node31_pedo(n31_pedo), .node31_polarity(n31_pol),
        .node32_pesi(n32_pesi), .node32_peri(n32_peri), .node32_pedi(n32_pedi), .node32_peso(n32_peso), .node32_pero(n32_pero), .node32_pedo(n32_pedo), .node32_polarity(n32_pol),
        .node33_pesi(n33_pesi), .node33_peri(n33_peri), .node33_pedi(n33_pedi), .node33_peso(n33_peso), .node33_pero(n33_pero), .node33_pedo(n33_pedo), .node33_polarity(n33_pol)
    );



    // -------------------------------- Node 00 --------------------------------
    cardinal_nic nic_00 (.clk(clk), .reset(reset), .addr(nic_a_00), .d_in(nic_din_00), .nicEn(nic_en_00), .nicWrEn(nic_wen_00), .d_out(nic_dout_00),
        .net_so(n00_pesi), .net_ro(n00_peri), .net_do(n00_pedi), .net_polarity(n00_pol), .net_si(n00_peso), .net_ri(n00_pero), .net_di(n00_pedo));
    cardinal_cpu cpu_00 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_00), .inst_in(imem_data_00), .dmem_addr_out(dmem_addr_00), .dmem_data_out(dmem_data_out_00), .dmem_data_in(dmem_data_in_00), .memWrEn(dmem_wrEn_00), .memEn(dmem_en_00),
        .addr(nic_a_00), .d_in(nic_din_00), .nicEn(nic_en_00), .nicEnWr(nic_wen_00), .d_out(nic_dout_00));

    // -------------------------------- Node 01 --------------------------------
    cardinal_nic nic_01 (.clk(clk), .reset(reset), .addr(nic_a_01), .d_in(nic_din_01), .nicEn(nic_en_01), .nicWrEn(nic_wen_01), .d_out(nic_dout_01),
        .net_so(n01_pesi), .net_ro(n01_peri), .net_do(n01_pedi), .net_polarity(n01_pol), .net_si(n01_peso), .net_ri(n01_pero), .net_di(n01_pedo));
    cardinal_cpu cpu_01 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_01), .inst_in(imem_data_01), .dmem_addr_out(dmem_addr_01), .dmem_data_out(dmem_data_out_01), .dmem_data_in(dmem_data_in_01), .memWrEn(dmem_wrEn_01), .memEn(dmem_en_01),
        .addr(nic_a_01), .d_in(nic_din_01), .nicEn(nic_en_01), .nicEnWr(nic_wen_01), .d_out(nic_dout_01));

    // -------------------------------- Node 02 --------------------------------
    cardinal_nic nic_02 (.clk(clk), .reset(reset), .addr(nic_a_02), .d_in(nic_din_02), .nicEn(nic_en_02), .nicWrEn(nic_wen_02), .d_out(nic_dout_02),
        .net_so(n02_pesi), .net_ro(n02_peri), .net_do(n02_pedi), .net_polarity(n02_pol), .net_si(n02_peso), .net_ri(n02_pero), .net_di(n02_pedo));
    cardinal_cpu cpu_02 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_02), .inst_in(imem_data_02), .dmem_addr_out(dmem_addr_02), .dmem_data_out(dmem_data_out_02), .dmem_data_in(dmem_data_in_02), .memWrEn(dmem_wrEn_02), .memEn(dmem_en_02),
        .addr(nic_a_02), .d_in(nic_din_02), .nicEn(nic_en_02), .nicEnWr(nic_wen_02), .d_out(nic_dout_02));

    // -------------------------------- Node 03 --------------------------------
    cardinal_nic nic_03 (.clk(clk), .reset(reset), .addr(nic_a_03), .d_in(nic_din_03), .nicEn(nic_en_03), .nicWrEn(nic_wen_03), .d_out(nic_dout_03),
        .net_so(n03_pesi), .net_ro(n03_peri), .net_do(n03_pedi), .net_polarity(n03_pol), .net_si(n03_peso), .net_ri(n03_pero), .net_di(n03_pedo));
    cardinal_cpu cpu_03 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_03), .inst_in(imem_data_03), .dmem_addr_out(dmem_addr_03), .dmem_data_out(dmem_data_out_03), .dmem_data_in(dmem_data_in_03), .memWrEn(dmem_wrEn_03), .memEn(dmem_en_03),
        .addr(nic_a_03), .d_in(nic_din_03), .nicEn(nic_en_03), .nicEnWr(nic_wen_03), .d_out(nic_dout_03));

    // -------------------------------- Node 10 --------------------------------
    cardinal_nic nic_10 (.clk(clk), .reset(reset), .addr(nic_a_10), .d_in(nic_din_10), .nicEn(nic_en_10), .nicWrEn(nic_wen_10), .d_out(nic_dout_10),
        .net_so(n10_pesi), .net_ro(n10_peri), .net_do(n10_pedi), .net_polarity(n10_pol), .net_si(n10_peso), .net_ri(n10_pero), .net_di(n10_pedo));
    cardinal_cpu cpu_10 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_10), .inst_in(imem_data_10), .dmem_addr_out(dmem_addr_10), .dmem_data_out(dmem_data_out_10), .dmem_data_in(dmem_data_in_10), .memWrEn(dmem_wrEn_10), .memEn(dmem_en_10),
        .addr(nic_a_10), .d_in(nic_din_10), .nicEn(nic_en_10), .nicEnWr(nic_wen_10), .d_out(nic_dout_10));

    // -------------------------------- Node 11 --------------------------------
    cardinal_nic nic_11 (.clk(clk), .reset(reset), .addr(nic_a_11), .d_in(nic_din_11), .nicEn(nic_en_11), .nicWrEn(nic_wen_11), .d_out(nic_dout_11),
        .net_so(n11_pesi), .net_ro(n11_peri), .net_do(n11_pedi), .net_polarity(n11_pol), .net_si(n11_peso), .net_ri(n11_pero), .net_di(n11_pedo));
    cardinal_cpu cpu_11 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_11), .inst_in(imem_data_11), .dmem_addr_out(dmem_addr_11), .dmem_data_out(dmem_data_out_11), .dmem_data_in(dmem_data_in_11), .memWrEn(dmem_wrEn_11), .memEn(dmem_en_11),
        .addr(nic_a_11), .d_in(nic_din_11), .nicEn(nic_en_11), .nicEnWr(nic_wen_11), .d_out(nic_dout_11));

    // -------------------------------- Node 12 --------------------------------
    cardinal_nic nic_12 (.clk(clk), .reset(reset), .addr(nic_a_12), .d_in(nic_din_12), .nicEn(nic_en_12), .nicWrEn(nic_wen_12), .d_out(nic_dout_12),
        .net_so(n12_pesi), .net_ro(n12_peri), .net_do(n12_pedi), .net_polarity(n12_pol), .net_si(n12_peso), .net_ri(n12_pero), .net_di(n12_pedo));
    cardinal_cpu cpu_12 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_12), .inst_in(imem_data_12), .dmem_addr_out(dmem_addr_12), .dmem_data_out(dmem_data_out_12), .dmem_data_in(dmem_data_in_12), .memWrEn(dmem_wrEn_12), .memEn(dmem_en_12),
        .addr(nic_a_12), .d_in(nic_din_12), .nicEn(nic_en_12), .nicEnWr(nic_wen_12), .d_out(nic_dout_12));

    // -------------------------------- Node 13 --------------------------------
    cardinal_nic nic_13 (.clk(clk), .reset(reset), .addr(nic_a_13), .d_in(nic_din_13), .nicEn(nic_en_13), .nicWrEn(nic_wen_13), .d_out(nic_dout_13),
        .net_so(n13_pesi), .net_ro(n13_peri), .net_do(n13_pedi), .net_polarity(n13_pol), .net_si(n13_peso), .net_ri(n13_pero), .net_di(n13_pedo));
    cardinal_cpu cpu_13 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_13), .inst_in(imem_data_13), .dmem_addr_out(dmem_addr_13), .dmem_data_out(dmem_data_out_13), .dmem_data_in(dmem_data_in_13), .memWrEn(dmem_wrEn_13), .memEn(dmem_en_13),
        .addr(nic_a_13), .d_in(nic_din_13), .nicEn(nic_en_13), .nicEnWr(nic_wen_13), .d_out(nic_dout_13));

    // -------------------------------- Node 20 --------------------------------
    cardinal_nic nic_20 (.clk(clk), .reset(reset), .addr(nic_a_20), .d_in(nic_din_20), .nicEn(nic_en_20), .nicWrEn(nic_wen_20), .d_out(nic_dout_20),
        .net_so(n20_pesi), .net_ro(n20_peri), .net_do(n20_pedi), .net_polarity(n20_pol), .net_si(n20_peso), .net_ri(n20_pero), .net_di(n20_pedo));
    cardinal_cpu cpu_20 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_20), .inst_in(imem_data_20), .dmem_addr_out(dmem_addr_20), .dmem_data_out(dmem_data_out_20), .dmem_data_in(dmem_data_in_20), .memWrEn(dmem_wrEn_20), .memEn(dmem_en_20),
        .addr(nic_a_20), .d_in(nic_din_20), .nicEn(nic_en_20), .nicEnWr(nic_wen_20), .d_out(nic_dout_20));

    // -------------------------------- Node 21 --------------------------------
    cardinal_nic nic_21 (.clk(clk), .reset(reset), .addr(nic_a_21), .d_in(nic_din_21), .nicEn(nic_en_21), .nicWrEn(nic_wen_21), .d_out(nic_dout_21),
        .net_so(n21_pesi), .net_ro(n21_peri), .net_do(n21_pedi), .net_polarity(n21_pol), .net_si(n21_peso), .net_ri(n21_pero), .net_di(n21_pedo));
    cardinal_cpu cpu_21 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_21), .inst_in(imem_data_21), .dmem_addr_out(dmem_addr_21), .dmem_data_out(dmem_data_out_21), .dmem_data_in(dmem_data_in_21), .memWrEn(dmem_wrEn_21), .memEn(dmem_en_21),
        .addr(nic_a_21), .d_in(nic_din_21), .nicEn(nic_en_21), .nicEnWr(nic_wen_21), .d_out(nic_dout_21));

    // -------------------------------- Node 22 --------------------------------
    cardinal_nic nic_22 (.clk(clk), .reset(reset), .addr(nic_a_22), .d_in(nic_din_22), .nicEn(nic_en_22), .nicWrEn(nic_wen_22), .d_out(nic_dout_22),
        .net_so(n22_pesi), .net_ro(n22_peri), .net_do(n22_pedi), .net_polarity(n22_pol), .net_si(n22_peso), .net_ri(n22_pero), .net_di(n22_pedo));
    cardinal_cpu cpu_22 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_22), .inst_in(imem_data_22), .dmem_addr_out(dmem_addr_22), .dmem_data_out(dmem_data_out_22), .dmem_data_in(dmem_data_in_22), .memWrEn(dmem_wrEn_22), .memEn(dmem_en_22),
        .addr(nic_a_22), .d_in(nic_din_22), .nicEn(nic_en_22), .nicEnWr(nic_wen_22), .d_out(nic_dout_22));

    // -------------------------------- Node 23 --------------------------------
    cardinal_nic nic_23 (.clk(clk), .reset(reset), .addr(nic_a_23), .d_in(nic_din_23), .nicEn(nic_en_23), .nicWrEn(nic_wen_23), .d_out(nic_dout_23),
        .net_so(n23_pesi), .net_ro(n23_peri), .net_do(n23_pedi), .net_polarity(n23_pol), .net_si(n23_peso), .net_ri(n23_pero), .net_di(n23_pedo));
    cardinal_cpu cpu_23 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_23), .inst_in(imem_data_23), .dmem_addr_out(dmem_addr_23), .dmem_data_out(dmem_data_out_23), .dmem_data_in(dmem_data_in_23), .memWrEn(dmem_wrEn_23), .memEn(dmem_en_23),
        .addr(nic_a_23), .d_in(nic_din_23), .nicEn(nic_en_23), .nicEnWr(nic_wen_23), .d_out(nic_dout_23));

    // -------------------------------- Node 30 --------------------------------
    cardinal_nic nic_30 (.clk(clk), .reset(reset), .addr(nic_a_30), .d_in(nic_din_30), .nicEn(nic_en_30), .nicWrEn(nic_wen_30), .d_out(nic_dout_30),
        .net_so(n30_pesi), .net_ro(n30_peri), .net_do(n30_pedi), .net_polarity(n30_pol), .net_si(n30_peso), .net_ri(n30_pero), .net_di(n30_pedo));
    cardinal_cpu cpu_30 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_30), .inst_in(imem_data_30), .dmem_addr_out(dmem_addr_30), .dmem_data_out(dmem_data_out_30), .dmem_data_in(dmem_data_in_30), .memWrEn(dmem_wrEn_30), .memEn(dmem_en_30),
        .addr(nic_a_30), .d_in(nic_din_30), .nicEn(nic_en_30), .nicEnWr(nic_wen_30), .d_out(nic_dout_30));

    // -------------------------------- Node 31 --------------------------------
    cardinal_nic nic_31 (.clk(clk), .reset(reset), .addr(nic_a_31), .d_in(nic_din_31), .nicEn(nic_en_31), .nicWrEn(nic_wen_31), .d_out(nic_dout_31),
        .net_so(n31_pesi), .net_ro(n31_peri), .net_do(n31_pedi), .net_polarity(n31_pol), .net_si(n31_peso), .net_ri(n31_pero), .net_di(n31_pedo));
    cardinal_cpu cpu_31 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_31), .inst_in(imem_data_31), .dmem_addr_out(dmem_addr_31), .dmem_data_out(dmem_data_out_31), .dmem_data_in(dmem_data_in_31), .memWrEn(dmem_wrEn_31), .memEn(dmem_en_31),
        .addr(nic_a_31), .d_in(nic_din_31), .nicEn(nic_en_31), .nicEnWr(nic_wen_31), .d_out(nic_dout_31));

    // -------------------------------- Node 32 --------------------------------
    cardinal_nic nic_32 (.clk(clk), .reset(reset), .addr(nic_a_32), .d_in(nic_din_32), .nicEn(nic_en_32), .nicWrEn(nic_wen_32), .d_out(nic_dout_32),
        .net_so(n32_pesi), .net_ro(n32_peri), .net_do(n32_pedi), .net_polarity(n32_pol), .net_si(n32_peso), .net_ri(n32_pero), .net_di(n32_pedo));
    cardinal_cpu cpu_32 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_32), .inst_in(imem_data_32), .dmem_addr_out(dmem_addr_32), .dmem_data_out(dmem_data_out_32), .dmem_data_in(dmem_data_in_32), .memWrEn(dmem_wrEn_32), .memEn(dmem_en_32),
        .addr(nic_a_32), .d_in(nic_din_32), .nicEn(nic_en_32), .nicEnWr(nic_wen_32), .d_out(nic_dout_32));

    // -------------------------------- Node 33 --------------------------------
    cardinal_nic nic_33 (.clk(clk), .reset(reset), .addr(nic_a_33), .d_in(nic_din_33), .nicEn(nic_en_33), .nicWrEn(nic_wen_33), .d_out(nic_dout_33),
        .net_so(n33_pesi), .net_ro(n33_peri), .net_do(n33_pedi), .net_polarity(n33_pol), .net_si(n33_peso), .net_ri(n33_pero), .net_di(n33_pedo));
    cardinal_cpu cpu_33 (.clk(clk), .reset(reset), 
        .imem_pc_out(imem_addr_33), .inst_in(imem_data_33), .dmem_addr_out(dmem_addr_33), .dmem_data_out(dmem_data_out_33), .dmem_data_in(dmem_data_in_33), .memWrEn(dmem_wrEn_33), .memEn(dmem_en_33),
        .addr(nic_a_33), .d_in(nic_din_33), .nicEn(nic_en_33), .nicEnWr(nic_wen_33), .d_out(nic_dout_33));

endmodule