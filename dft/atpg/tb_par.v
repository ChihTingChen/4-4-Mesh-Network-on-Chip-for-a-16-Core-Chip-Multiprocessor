// Parallel-load validation of ATPG patterns on the post-route scan netlist:
// flop states are loaded directly (force D + one clock), chip inputs applied,
// one capture clock, all flop Q values read back. Scan-chain integrity is
// covered separately by the flush test.
`timescale 1ns/1ps
module tb_par;
  localparam NPI = 1554;
  reg clk = 0; always #5 clk = ~clk;
  reg [NPI-1:0] piv; reg [15:0] si; wire [15:0] so; reg se;
  wire [31:0] imem [0:15]; wire [63:0] dmem [0:15];
  genvar g;
  generate for (g = 0; g < 16; g = g + 1) begin : pm
    assign imem[g] = piv[NPI-1 - 32*g -: 32];
    assign dmem[g] = piv[NPI-1 - 512 - 64*g -: 64];
  end endgenerate
  wire reset_pi = piv[17];
  `include "tb_inst.vh"
`ifdef SDF_FILE
  initial $sdf_annotate(`SDF_FILE, cmp, , "sdf.log", "MAXIMUM");
`endif
  reg [`NFF_W-1:0] ldv; wire [`NFF_W-1:0] capv;
  `include `FLOPFILE
`ifdef INJECT
  `include `FAULTFILE
`endif
  reg [`NFF_W-1:0] lmem [0:`NPAT-1];
  reg [NPI-1:0] pmem [0:`NPAT-1];
  integer t, fd, n, pt;
  initial begin
    $readmemb(`LOADFILE, lmem); $readmemb(`PIFILE, pmem);
    fd = $fopen(`CAPFILE, "w");
    piv = 0; se = 0; si = 0;
    repeat (2) @(posedge clk);
`ifdef INJECT
    n = `NFLT;
`else
    n = `NPAT;
`endif
    for (t = 0; t < n; t = t + 1) begin
`ifdef INJECT
      pt = fpat(t);
`else
      pt = t;
`endif
      @(negedge clk); ldv = lmem[pt]; se = 0; load_all;
      @(posedge clk); #2 unload_all;
      @(negedge clk); piv = pmem[pt]; se = piv[16]; si = piv[15:0];
`ifdef INJECT
      inject(t);
`endif
      @(posedge clk); #2;
`ifdef INJECT
      release_all(t);
`endif
      $fdisplay(fd, "CAP %0d %b", t, capv);
    end
    $fclose(fd); $finish;
  end
endmodule
