module cardinal_mesh(
    input clk,
    input reset,

    // ================================================================================
    //                                      Row 0
    // ================================================================================
    // Node 00
    input         node00_pesi,
    output        node00_peri,
    input  [63:0] node00_pedi,
    output        node00_peso,
    input         node00_pero,
    output [63:0] node00_pedo,
    output        node00_polarity,

    // Node 01
    input         node01_pesi,
    output        node01_peri,
    input  [63:0] node01_pedi,
    output        node01_peso,
    input         node01_pero,
    output [63:0] node01_pedo,
    output        node01_polarity,

    // Node 02
    input         node02_pesi,
    output        node02_peri,
    input  [63:0] node02_pedi,
    output        node02_peso,
    input         node02_pero,
    output [63:0] node02_pedo,
    output        node02_polarity,

    // Node 03
    input         node03_pesi,
    output        node03_peri,
    input  [63:0] node03_pedi,
    output        node03_peso,
    input         node03_pero,
    output [63:0] node03_pedo,
    output        node03_polarity,

    // ================================================================================
    //                                      Row 1
    // ================================================================================
    // Node 10
    input         node10_pesi,
    output        node10_peri,
    input  [63:0] node10_pedi,
    output        node10_peso,
    input         node10_pero,
    output [63:0] node10_pedo,
    output        node10_polarity,

    // Node 11
    input         node11_pesi,
    output        node11_peri,
    input  [63:0] node11_pedi,
    output        node11_peso,
    input         node11_pero,
    output [63:0] node11_pedo,
    output        node11_polarity,

    // Node 12
    input         node12_pesi,
    output        node12_peri,
    input  [63:0] node12_pedi,
    output        node12_peso,
    input         node12_pero,
    output [63:0] node12_pedo,
    output        node12_polarity,

    // Node 13
    input         node13_pesi,
    output        node13_peri,
    input  [63:0] node13_pedi,
    output        node13_peso,
    input         node13_pero,
    output [63:0] node13_pedo,
    output        node13_polarity,

    // ================================================================================
    //                                      Row 2
    // ================================================================================
    // Node 20
    input         node20_pesi,
    output        node20_peri,
    input  [63:0] node20_pedi,
    output        node20_peso,
    input         node20_pero,
    output [63:0] node20_pedo,
    output        node20_polarity,

    // Node 21
    input         node21_pesi,
    output        node21_peri,
    input  [63:0] node21_pedi,
    output        node21_peso,
    input         node21_pero,
    output [63:0] node21_pedo,
    output        node21_polarity,

    // Node 22
    input         node22_pesi,
    output        node22_peri,
    input  [63:0] node22_pedi,
    output        node22_peso,
    input         node22_pero,
    output [63:0] node22_pedo,
    output        node22_polarity,

    // Node 23
    input         node23_pesi,
    output        node23_peri,
    input  [63:0] node23_pedi,
    output        node23_peso,
    input         node23_pero,
    output [63:0] node23_pedo,
    output        node23_polarity,

    // ================================================================================
    //                                      Row 3
    // ================================================================================
    // Node 30
    input         node30_pesi,
    output        node30_peri,
    input  [63:0] node30_pedi,
    output        node30_peso,
    input         node30_pero,
    output [63:0] node30_pedo,
    output        node30_polarity,

    // Node 31
    input         node31_pesi,
    output        node31_peri,
    input  [63:0] node31_pedi,
    output        node31_peso,
    input         node31_pero,
    output [63:0] node31_pedo,
    output        node31_polarity,

    // Node 32
    input         node32_pesi,
    output        node32_peri,
    input  [63:0] node32_pedi,
    output        node32_peso,
    input         node32_pero,
    output [63:0] node32_pedo,
    output        node32_polarity,

    // Node 33
    input         node33_pesi,
    output        node33_peri,
    input  [63:0] node33_pedi,
    output        node33_peso,
    input         node33_pero,
    output [63:0] node33_pedo,
    output        node33_polarity
);





/*

//------------------------- Node 00 -------------------------

cardinal_router node (
	.clk(clk),
	.reset(reset),
	.polarity(node_polarity),
	.pesi(node_pesi),
	.peri(node_peri),
	.pedi(node_pedi),	
	.peso(node_peso),
	.pero(node_pero),
	.pedo(node_pedo),	
	
	.nsi(),
	.nri(),
	.ndi(),
	.nso(),
	.nro(),
	.ndo(),

	.ssi(),
	.sri(),
	.sdi(),
	.sso(),
	.sro(),
	.sdo(),

	.esi(),
	.eri(),
	.edi(),
	.eso(),
	.ero(),
	.edo(),
	
	.wsi(),
	.wri(),
	.wdi(),
	.wso(),
	.wro(),
	.wdo()
	

);
*/


// ================================================================================
//                                      Row 0
// ================================================================================

//------------------------- Node 00 -------------------------

wire 		n00e_to_n01w_s;
wire 		n00e_to_n01w_r;
wire [63:0] n00e_to_n01w_d;
wire 		n01w_to_n00e_s;
wire 		n01w_to_n00e_r;
wire [63:0] n01w_to_n00e_d;

wire 		n00s_to_n10n_s;
wire 		n00s_to_n10n_r;
wire [63:0] n00s_to_n10n_d;
wire 		n10n_to_n00s_s;
wire 		n10n_to_n00s_r;
wire [63:0] n10n_to_n00s_d;

cardinal_router node00 (       
	.clk(clk),
	.reset(reset),
	.polarity(node00_polarity),
	.pesi(node00_pesi),
	.peri(node00_peri),
	.pedi(node00_pedi),
	.peso(node00_peso),
	.pero(node00_pero),
	.pedo(node00_pedo),

	.nsi(1'b0),
	.nri(),
	.ndi(64'b0),
	.nso(),
	.nro(1'b1),
	.ndo(),

	.ssi(n10n_to_n00s_s),
	.sri(n10n_to_n00s_r),
	.sdi(n10n_to_n00s_d),
	.sso(n00s_to_n10n_s),
	.sro(n00s_to_n10n_r),
	.sdo(n00s_to_n10n_d),

	.esi(n01w_to_n00e_s),
	.eri(n01w_to_n00e_r),
	.edi(n01w_to_n00e_d),
	.eso(n00e_to_n01w_s),
	.ero(n00e_to_n01w_r),
	.edo(n00e_to_n01w_d),

	.wsi(1'b0),
	.wri(),
	.wdi(64'b0),
	.wso(),
	.wro(1'b1),
	.wdo()
);


//------------------------- Node 01 -------------------------

wire 		n01e_to_n02w_s;
wire 		n01e_to_n02w_r;
wire [63:0] n01e_to_n02w_d;
wire 		n02w_to_n01e_s;
wire 		n02w_to_n01e_r;
wire [63:0] n02w_to_n01e_d;

wire 		n11n_to_n01s_s;
wire 		n11n_to_n01s_r;
wire [63:0] n11n_to_n01s_d;
wire 		n01s_to_n11n_s;
wire 		n01s_to_n11n_r;
wire [63:0] n01s_to_n11n_d;



cardinal_router node01 (
	.clk(clk),
	.reset(reset),
	.polarity(node01_polarity),
	.pesi(node01_pesi),
	.peri(node01_peri),
	.pedi(node01_pedi),	
	.peso(node01_peso),
	.pero(node01_pero),
	.pedo(node01_pedo),	
	
	.nsi(1'b0),
	.nri(),
	.ndi(64'b0),
	.nso(),
	.nro(1'b1),
	.ndo(),

	.ssi(n11n_to_n01s_s),
	.sri(n11n_to_n01s_r),
	.sdi(n11n_to_n01s_d),
	.sso(n01s_to_n11n_s),
	.sro(n01s_to_n11n_r),
	.sdo(n01s_to_n11n_d),

	.esi(n02w_to_n01e_s),
	.eri(n02w_to_n01e_r),
	.edi(n02w_to_n01e_d),
	.eso(n01e_to_n02w_s),
	.ero(n01e_to_n02w_r),
	.edo(n01e_to_n02w_d),
	
	.wsi(n00e_to_n01w_s),
	.wri(n00e_to_n01w_r),
	.wdi(n00e_to_n01w_d),
	.wso(n01w_to_n00e_s),
	.wro(n01w_to_n00e_r),
	.wdo(n01w_to_n00e_d)
	
);


//------------------------- Node 02 ------------------------- 

wire 		n03w_to_n02e_s;
wire 		n03w_to_n02e_r;
wire [63:0] n03w_to_n02e_d;
wire 		n02e_to_n03w_s;
wire 		n02e_to_n03w_r;
wire [63:0] n02e_to_n03w_d;


wire 		n12n_to_n02s_s;
wire 		n12n_to_n02s_r;
wire [63:0] n12n_to_n02s_d;
wire 		n02s_to_n12n_s;
wire 		n02s_to_n12n_r;
wire [63:0] n02s_to_n12n_d;


cardinal_router node02 (
	.clk(clk),
	.reset(reset),
	.polarity(node02_polarity),
	.pesi(node02_pesi),
	.peri(node02_peri),
	.pedi(node02_pedi),	
	.peso(node02_peso),
	.pero(node02_pero),
	.pedo(node02_pedo),	
	
	.nsi(1'b0),
	.nri(),
	.ndi(64'b0),
	.nso(),
	.nro(1'b1),
	.ndo(),

	.ssi(n12n_to_n02s_s),
	.sri(n12n_to_n02s_r),
	.sdi(n12n_to_n02s_d),
	.sso(n02s_to_n12n_s),
	.sro(n02s_to_n12n_r),
	.sdo(n02s_to_n12n_d),

	.esi(n03w_to_n02e_s),
	.eri(n03w_to_n02e_r),
	.edi(n03w_to_n02e_d),
	.eso(n02e_to_n03w_s),
	.ero(n02e_to_n03w_r),
	.edo(n02e_to_n03w_d),
	
	.wsi(n01e_to_n02w_s),
	.wri(n01e_to_n02w_r),
	.wdi(n01e_to_n02w_d),
	.wso(n02w_to_n01e_s),
	.wro(n02w_to_n01e_r),
	.wdo(n02w_to_n01e_d)

);


//------------------------- Node 03 -------------------------

wire 		n13n_to_n03s_s;
wire 		n13n_to_n03s_r;
wire [63:0] n13n_to_n03s_d;
wire 		n03s_to_n13n_s;
wire 		n03s_to_n13n_r;
wire [63:0] n03s_to_n13n_d;


cardinal_router node03 (
	.clk(clk),
	.reset(reset),
	.polarity(node03_polarity),
	.pesi(node03_pesi),
	.peri(node03_peri),
	.pedi(node03_pedi),	
	.peso(node03_peso),
	.pero(node03_pero),
	.pedo(node03_pedo),	
	
	.nsi(1'b0),
	.nri(),
	.ndi(64'b0),
	.nso(),
	.nro(1'b1),
	.ndo(),

	.ssi(n13n_to_n03s_s),
	.sri(n13n_to_n03s_r),
	.sdi(n13n_to_n03s_d),
	.sso(n03s_to_n13n_s),
	.sro(n03s_to_n13n_r),
	.sdo(n03s_to_n13n_d),

	.esi(1'b0),
	.eri(),
	.edi(64'b0),
	.eso(),
	.ero(1'b1),
	.edo(),
	
	.wsi(n02e_to_n03w_s),
	.wri(n02e_to_n03w_r),
	.wdi(n02e_to_n03w_d),
	.wso(n03w_to_n02e_s),
	.wro(n03w_to_n02e_r),
	.wdo(n03w_to_n02e_d) 
	
);


// ================================================================================
//                                      Row 1
// ================================================================================

//------------------------- Node 10 -------------------------


wire 		n10e_to_n11w_s;
wire 		n10e_to_n11w_r;
wire [63:0] n10e_to_n11w_d;
wire 		n11w_to_n10e_s;
wire 		n11w_to_n10e_r;
wire [63:0] n11w_to_n10e_d;


wire 		n10s_to_n20n_s;
wire 		n10s_to_n20n_r;
wire [63:0] n10s_to_n20n_d;
wire 		n20n_to_n10s_s;
wire 		n20n_to_n10s_r;
wire [63:0] n20n_to_n10s_d;

cardinal_router node10 (       
	.clk(clk),
	.reset(reset),
	.polarity(node10_polarity),
	.pesi(node10_pesi),
	.peri(node10_peri),
	.pedi(node10_pedi),
	.peso(node10_peso),
	.pero(node10_pero),
	.pedo(node10_pedo),

	.nsi(n00s_to_n10n_s),
	.nri(n00s_to_n10n_r),
	.ndi(n00s_to_n10n_d),
	.nso(n10n_to_n00s_s),
	.nro(n10n_to_n00s_r),
	.ndo(n10n_to_n00s_d),

	.ssi(n20n_to_n10s_s),
	.sri(n20n_to_n10s_r),
	.sdi(n20n_to_n10s_d),
	.sso(n10s_to_n20n_s),
	.sro(n10s_to_n20n_r),
	.sdo(n10s_to_n20n_d),

	.esi(n11w_to_n10e_s),
	.eri(n11w_to_n10e_r),
	.edi(n11w_to_n10e_d),
	.eso(n10e_to_n11w_s),
	.ero(n10e_to_n11w_r),
	.edo(n10e_to_n11w_d),

	.wsi(1'b0),
	.wri(),
	.wdi(64'b0),
	.wso(),
	.wro(1'b1),
	.wdo()
);


//------------------------- Node 11 -------------------------

wire 		n11e_to_n12w_s;
wire 		n11e_to_n12w_r;
wire [63:0] n11e_to_n12w_d;
wire 		n12w_to_n11e_s;
wire 		n12w_to_n11e_r;
wire [63:0] n12w_to_n11e_d;


wire 		n11s_to_n21n_s;
wire 		n11s_to_n21n_r;
wire [63:0] n11s_to_n21n_d;
wire 		n21n_to_n11s_s;
wire 		n21n_to_n11s_r;
wire [63:0] n21n_to_n11s_d;

cardinal_router node11 (
	.clk(clk),
	.reset(reset),
	.polarity(node11_polarity),
	.pesi(node11_pesi),
	.peri(node11_peri),
	.pedi(node11_pedi),	
	.peso(node11_peso),
	.pero(node11_pero),
	.pedo(node11_pedo),	
	
	.nsi(n01s_to_n11n_s),
	.nri(n01s_to_n11n_r),
	.ndi(n01s_to_n11n_d),
	.nso(n11n_to_n01s_s),
	.nro(n11n_to_n01s_r),
	.ndo(n11n_to_n01s_d),

	.ssi(n21n_to_n11s_s),
	.sri(n21n_to_n11s_r),
	.sdi(n21n_to_n11s_d),
	.sso(n11s_to_n21n_s),
	.sro(n11s_to_n21n_r),
	.sdo(n11s_to_n21n_d),

	.esi(n12w_to_n11e_s),
	.eri(n12w_to_n11e_r),
	.edi(n12w_to_n11e_d),
	.eso(n11e_to_n12w_s),
	.ero(n11e_to_n12w_r),
	.edo(n11e_to_n12w_d),
	
	.wsi(n10e_to_n11w_s),
	.wri(n10e_to_n11w_r),
	.wdi(n10e_to_n11w_d),
	.wso(n11w_to_n10e_s),
	.wro(n11w_to_n10e_r),
	.wdo(n11w_to_n10e_d)
);


//------------------------- Node 12 ------------------------- 

wire 		n12e_to_n13w_s;
wire 		n12e_to_n13w_r;
wire [63:0] n12e_to_n13w_d;
wire 		n13w_to_n12e_s;
wire 		n13w_to_n12e_r;
wire [63:0] n13w_to_n12e_d;


wire 		n12s_to_n22n_s;
wire 		n12s_to_n22n_r;
wire [63:0] n12s_to_n22n_d;
wire 		n22n_to_n12s_s;
wire 		n22n_to_n12s_r;
wire [63:0] n22n_to_n12s_d;


cardinal_router node12 (
	.clk(clk),
	.reset(reset),
	.polarity(node12_polarity),
	.pesi(node12_pesi),
	.peri(node12_peri),
	.pedi(node12_pedi),	
	.peso(node12_peso),
	.pero(node12_pero),
	.pedo(node12_pedo),	
	
	.nsi(n02s_to_n12n_s),
	.nri(n02s_to_n12n_r),
	.ndi(n02s_to_n12n_d),
	.nso(n12n_to_n02s_s),
	.nro(n12n_to_n02s_r),
	.ndo(n12n_to_n02s_d),

	.ssi(n22n_to_n12s_s),
	.sri(n22n_to_n12s_r),
	.sdi(n22n_to_n12s_d),
	.sso(n12s_to_n22n_s),
	.sro(n12s_to_n22n_r),
	.sdo(n12s_to_n22n_d),

	.esi(n13w_to_n12e_s),
	.eri(n13w_to_n12e_r),
	.edi(n13w_to_n12e_d),
	.eso(n12e_to_n13w_s),
	.ero(n12e_to_n13w_r),
	.edo(n12e_to_n13w_d),
	
	.wsi(n11e_to_n12w_s),
	.wri(n11e_to_n12w_r),
	.wdi(n11e_to_n12w_d),
	.wso(n12w_to_n11e_s),
	.wro(n12w_to_n11e_r),
	.wdo(n12w_to_n11e_d)
);


//------------------------- Node 13 -------------------------


wire 		n13s_to_n23n_s;
wire 		n13s_to_n23n_r;
wire [63:0] n13s_to_n23n_d;
wire 		n23n_to_n13s_s;
wire 		n23n_to_n13s_r;
wire [63:0] n23n_to_n13s_d;

cardinal_router node13 (
	.clk(clk),
	.reset(reset),
	.polarity(node13_polarity),
	.pesi(node13_pesi),
	.peri(node13_peri),
	.pedi(node13_pedi),	
	.peso(node13_peso),
	.pero(node13_pero),
	.pedo(node13_pedo),	
	
	.nsi(n03s_to_n13n_s),
	.nri(n03s_to_n13n_r),
	.ndi(n03s_to_n13n_d),
	.nso(n13n_to_n03s_s),
	.nro(n13n_to_n03s_r),
	.ndo(n13n_to_n03s_d),

	.ssi(n23n_to_n13s_s),
	.sri(n23n_to_n13s_r),
	.sdi(n23n_to_n13s_d),
	.sso(n13s_to_n23n_s),
	.sro(n13s_to_n23n_r),
	.sdo(n13s_to_n23n_d),

	.esi(1'b0),
	.eri(),
	.edi(64'b0),
	.eso(),
	.ero(1'b1),
	.edo(),
	
	.wsi(n12e_to_n13w_s),
	.wri(n12e_to_n13w_r),
	.wdi(n12e_to_n13w_d),
	.wso(n13w_to_n12e_s),
	.wro(n13w_to_n12e_r),
	.wdo(n13w_to_n12e_d) 
);


// ================================================================================
//                                      Row 2
// ================================================================================

//------------------------- Node 20 -------------------------

wire 		n20e_to_n21w_s;
wire 		n20e_to_n21w_r;
wire [63:0] n20e_to_n21w_d;
wire 		n21w_to_n20e_s;
wire 		n21w_to_n20e_r;
wire [63:0] n21w_to_n20e_d;


wire 		n20s_to_n30n_s;
wire 		n20s_to_n30n_r;
wire [63:0] n20s_to_n30n_d;
wire 		n30n_to_n20s_s;
wire 		n30n_to_n20s_r;
wire [63:0] n30n_to_n20s_d;

cardinal_router node20 (       
	.clk(clk),
	.reset(reset),
	.polarity(node20_polarity),
	.pesi(node20_pesi),
	.peri(node20_peri),
	.pedi(node20_pedi),
	.peso(node20_peso),
	.pero(node20_pero),
	.pedo(node20_pedo),

	.nsi(n10s_to_n20n_s),
	.nri(n10s_to_n20n_r),
	.ndi(n10s_to_n20n_d),
	.nso(n20n_to_n10s_s),
	.nro(n20n_to_n10s_r),
	.ndo(n20n_to_n10s_d),

	.ssi(n30n_to_n20s_s),
	.sri(n30n_to_n20s_r),
	.sdi(n30n_to_n20s_d),
	.sso(n20s_to_n30n_s),
	.sro(n20s_to_n30n_r),
	.sdo(n20s_to_n30n_d),

	.esi(n21w_to_n20e_s),
	.eri(n21w_to_n20e_r),
	.edi(n21w_to_n20e_d),
	.eso(n20e_to_n21w_s),
	.ero(n20e_to_n21w_r),
	.edo(n20e_to_n21w_d),

	.wsi(1'b0),
	.wri(),
	.wdi(64'b0),
	.wso(),
	.wro(1'b1),
	.wdo()
);


//------------------------- Node 21 -------------------------

wire 		n21e_to_n22w_s;
wire 		n21e_to_n22w_r;
wire [63:0] n21e_to_n22w_d;
wire 		n22w_to_n21e_s;
wire 		n22w_to_n21e_r;
wire [63:0] n22w_to_n21e_d;


wire 		n21s_to_n31n_s;
wire 		n21s_to_n31n_r;
wire [63:0] n21s_to_n31n_d;
wire 		n31n_to_n21s_s;
wire 		n31n_to_n21s_r;
wire [63:0] n31n_to_n21s_d;

cardinal_router node21 (
	.clk(clk),
	.reset(reset),
	.polarity(node21_polarity),
	.pesi(node21_pesi),
	.peri(node21_peri),
	.pedi(node21_pedi),	
	.peso(node21_peso),
	.pero(node21_pero),
	.pedo(node21_pedo),	
	
	.nsi(n11s_to_n21n_s),
	.nri(n11s_to_n21n_r),
	.ndi(n11s_to_n21n_d),
	.nso(n21n_to_n11s_s),
	.nro(n21n_to_n11s_r),
	.ndo(n21n_to_n11s_d),

	.ssi(n31n_to_n21s_s),
	.sri(n31n_to_n21s_r),
	.sdi(n31n_to_n21s_d),
	.sso(n21s_to_n31n_s),
	.sro(n21s_to_n31n_r),
	.sdo(n21s_to_n31n_d),

	.esi(n22w_to_n21e_s),
	.eri(n22w_to_n21e_r),
	.edi(n22w_to_n21e_d),
	.eso(n21e_to_n22w_s),
	.ero(n21e_to_n22w_r),
	.edo(n21e_to_n22w_d),
	
	.wsi(n20e_to_n21w_s),
	.wri(n20e_to_n21w_r),
	.wdi(n20e_to_n21w_d),
	.wso(n21w_to_n20e_s),
	.wro(n21w_to_n20e_r),
	.wdo(n21w_to_n20e_d)
);


//------------------------- Node 22 ------------------------- 


wire 		n22e_to_n23w_s;
wire 		n22e_to_n23w_r;
wire [63:0] n22e_to_n23w_d;
wire 		n23w_to_n22e_s;
wire 		n23w_to_n22e_r;
wire [63:0] n23w_to_n22e_d;


wire 		n22s_to_n32n_s;
wire 		n22s_to_n32n_r;
wire [63:0] n22s_to_n32n_d;
wire 		n32n_to_n22s_s;
wire 		n32n_to_n22s_r;
wire [63:0] n32n_to_n22s_d;

cardinal_router node22 (
	.clk(clk),
	.reset(reset),
	.polarity(node22_polarity),
	.pesi(node22_pesi),
	.peri(node22_peri),
	.pedi(node22_pedi),	
	.peso(node22_peso),
	.pero(node22_pero),
	.pedo(node22_pedo),	
	
	.nsi(n12s_to_n22n_s),
	.nri(n12s_to_n22n_r),
	.ndi(n12s_to_n22n_d),
	.nso(n22n_to_n12s_s),
	.nro(n22n_to_n12s_r),
	.ndo(n22n_to_n12s_d),

	.ssi(n32n_to_n22s_s),
	.sri(n32n_to_n22s_r),
	.sdi(n32n_to_n22s_d),
	.sso(n22s_to_n32n_s),
	.sro(n22s_to_n32n_r),
	.sdo(n22s_to_n32n_d),

	.esi(n23w_to_n22e_s),
	.eri(n23w_to_n22e_r),
	.edi(n23w_to_n22e_d),
	.eso(n22e_to_n23w_s),
	.ero(n22e_to_n23w_r),
	.edo(n22e_to_n23w_d),
	
	.wsi(n21e_to_n22w_s),
	.wri(n21e_to_n22w_r),
	.wdi(n21e_to_n22w_d),
	.wso(n22w_to_n21e_s),
	.wro(n22w_to_n21e_r),
	.wdo(n22w_to_n21e_d)
);


//------------------------- Node 23 -------------------------


wire 		n23s_to_n33n_s;
wire 		n23s_to_n33n_r;
wire [63:0] n23s_to_n33n_d;
wire 		n33n_to_n23s_s;
wire 		n33n_to_n23s_r;
wire [63:0] n33n_to_n23s_d;

cardinal_router node23 (
	.clk(clk),
	.reset(reset),
	.polarity(node23_polarity),
	.pesi(node23_pesi),
	.peri(node23_peri),
	.pedi(node23_pedi),	
	.peso(node23_peso),
	.pero(node23_pero),
	.pedo(node23_pedo),	
	
	.nsi(n13s_to_n23n_s),
	.nri(n13s_to_n23n_r),
	.ndi(n13s_to_n23n_d),
	.nso(n23n_to_n13s_s),
	.nro(n23n_to_n13s_r),
	.ndo(n23n_to_n13s_d),

	.ssi(n33n_to_n23s_s),
	.sri(n33n_to_n23s_r),
	.sdi(n33n_to_n23s_d),
	.sso(n23s_to_n33n_s),
	.sro(n23s_to_n33n_r),
	.sdo(n23s_to_n33n_d),

	.esi(1'b0),
	.eri(),
	.edi(64'b0),
	.eso(),
	.ero(1'b1),
	.edo(),
	
	.wsi(n22e_to_n23w_s),
	.wri(n22e_to_n23w_r),
	.wdi(n22e_to_n23w_d),
	.wso(n23w_to_n22e_s),
	.wro(n23w_to_n22e_r),
	.wdo(n23w_to_n22e_d) 
);


// ================================================================================
//                                      Row 3
// ================================================================================

//------------------------- Node 30 -------------------------

wire 		n30e_to_n31w_s;
wire 		n30e_to_n31w_r;
wire [63:0] n30e_to_n31w_d;
wire 		n31w_to_n30e_s;
wire 		n31w_to_n30e_r;
wire [63:0] n31w_to_n30e_d;

cardinal_router node30 (       
	.clk(clk),
	.reset(reset),
	.polarity(node30_polarity),
	.pesi(node30_pesi),
	.peri(node30_peri),
	.pedi(node30_pedi),
	.peso(node30_peso),
	.pero(node30_pero),
	.pedo(node30_pedo),

	.nsi(n20s_to_n30n_s),
	.nri(n20s_to_n30n_r),
	.ndi(n20s_to_n30n_d),
	.nso(n30n_to_n20s_s),
	.nro(n30n_to_n20s_r),
	.ndo(n30n_to_n20s_d),

	.ssi(1'b0),
	.sri(),
	.sdi(64'b0),
	.sso(),
	.sro(1'b1),
	.sdo(),

	.esi(n31w_to_n30e_s),
	.eri(n31w_to_n30e_r),
	.edi(n31w_to_n30e_d),
	.eso(n30e_to_n31w_s),
	.ero(n30e_to_n31w_r),
	.edo(n30e_to_n31w_d),

	.wsi(1'b0),
	.wri(),
	.wdi(64'b0),
	.wso(),
	.wro(1'b1),
	.wdo()
);


//------------------------- Node 31 -------------------------

wire 		n31e_to_n32w_s;
wire 		n31e_to_n32w_r;
wire [63:0] n31e_to_n32w_d;
wire 		n32w_to_n31e_s;
wire 		n32w_to_n31e_r;
wire [63:0] n32w_to_n31e_d;

cardinal_router node31 (
	.clk(clk),
	.reset(reset),
	.polarity(node31_polarity),
	.pesi(node31_pesi),
	.peri(node31_peri),
	.pedi(node31_pedi),	
	.peso(node31_peso),
	.pero(node31_pero),
	.pedo(node31_pedo),	
	
	.nsi(n21s_to_n31n_s),
	.nri(n21s_to_n31n_r),
	.ndi(n21s_to_n31n_d),
	.nso(n31n_to_n21s_s),
	.nro(n31n_to_n21s_r),
	.ndo(n31n_to_n21s_d),

	.ssi(1'b0),
	.sri(),
	.sdi(64'b0),
	.sso(),
	.sro(1'b1),
	.sdo(),

	.esi(n32w_to_n31e_s),
	.eri(n32w_to_n31e_r),
	.edi(n32w_to_n31e_d),
	.eso(n31e_to_n32w_s),
	.ero(n31e_to_n32w_r),
	.edo(n31e_to_n32w_d),
	
	.wsi(n30e_to_n31w_s),
	.wri(n30e_to_n31w_r),
	.wdi(n30e_to_n31w_d),
	.wso(n31w_to_n30e_s),
	.wro(n31w_to_n30e_r),
	.wdo(n31w_to_n30e_d)
);


//------------------------- Node 32 ------------------------- 

wire 		n32e_to_n33w_s;
wire 		n32e_to_n33w_r;
wire [63:0] n32e_to_n33w_d;
wire 		n33w_to_n32e_s;
wire 		n33w_to_n32e_r;
wire [63:0] n33w_to_n32e_d;

cardinal_router node32 (
	.clk(clk),
	.reset(reset),
	.polarity(node32_polarity),
	.pesi(node32_pesi),
	.peri(node32_peri),
	.pedi(node32_pedi),	
	.peso(node32_peso),
	.pero(node32_pero),
	.pedo(node32_pedo),	
	
	.nsi(n22s_to_n32n_s),
	.nri(n22s_to_n32n_r),
	.ndi(n22s_to_n32n_d),
	.nso(n32n_to_n22s_s),
	.nro(n32n_to_n22s_r),
	.ndo(n32n_to_n22s_d),

	.ssi(1'b0),
	.sri(),
	.sdi(64'b0),
	.sso(),
	.sro(1'b1),
	.sdo(),

	.esi(n33w_to_n32e_s),
	.eri(n33w_to_n32e_r),
	.edi(n33w_to_n32e_d),
	.eso(n32e_to_n33w_s),
	.ero(n32e_to_n33w_r),
	.edo(n32e_to_n33w_d),
	
	.wsi(n31e_to_n32w_s),
	.wri(n31e_to_n32w_r),
	.wdi(n31e_to_n32w_d),
	.wso(n32w_to_n31e_s),
	.wro(n32w_to_n31e_r),
	.wdo(n32w_to_n31e_d)
);


//------------------------- Node 33 -------------------------

cardinal_router node33 (
	.clk(clk),
	.reset(reset),
	.polarity(node33_polarity),
	.pesi(node33_pesi),
	.peri(node33_peri),
	.pedi(node33_pedi),	
	.peso(node33_peso),
	.pero(node33_pero),
	.pedo(node33_pedo),	
	
	.nsi(n23s_to_n33n_s),
	.nri(n23s_to_n33n_r),
	.ndi(n23s_to_n33n_d),
	.nso(n33n_to_n23s_s),
	.nro(n33n_to_n23s_r),
	.ndo(n33n_to_n23s_d),

	.ssi(1'b0),
	.sri(),
	.sdi(64'b0),
	.sso(),
	.sro(1'b1),
	.sdo(),

	.esi(1'b0),
	.eri(),
	.edi(64'b0),
	.eso(),
	.ero(1'b1),
	.edo(),
	
	.wsi(n32e_to_n33w_s),
	.wri(n32e_to_n33w_r),
	.wdi(n32e_to_n33w_d),
	.wso(n33w_to_n32e_s),
	.wro(n33w_to_n32e_r),
	.wdo(n33w_to_n32e_d) 
);





endmodule