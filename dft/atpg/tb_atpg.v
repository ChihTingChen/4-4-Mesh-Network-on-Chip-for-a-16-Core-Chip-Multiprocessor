// Gate-level validation of ATPG patterns on the post-route scan netlist.
// Per pattern: shift-load 16 chains (test_se=1), apply chip inputs, one capture
// clock, shift-unload; captured chain contents are printed as "CAP t k bits".
// With +define+INJECT, entries of faults.vh are applied: force a cell pin
// during capture only, then release before unload.
`timescale 1ns/1ps
module tb_atpg;
  localparam L = 4144, NPI = 1554;
  reg clk = 0; always #5 clk = ~clk;
  reg  [NPI-1:0] piv;
  reg  [15:0] si; wire [15:0] so; reg se;
  wire [31:0] imem [0:15]; wire [63:0] dmem [0:15];
  genvar g;
  generate for (g = 0; g < 16; g = g + 1) begin : pm
    assign imem[g] = piv[NPI-1 - 32*g -: 32];
    assign dmem[g] = piv[NPI-1 - 512 - 64*g -: 64];
  end endgenerate
  wire reset_pi = piv[17];
  `include "tb_inst.vh"
`ifdef INJECT
  `include `FAULTFILE
`endif
`ifdef SDF_FILE
  initial $sdf_annotate(`SDF_FILE, cmp, , "sdf.log", "MAXIMUM");
`endif
  reg [L-1:0] ld [0:16*`NPAT-1];
  reg [NPI-1:0] pmem [0:`NPAT-1];
  reg [L-1:0] cap [0:15];
  integer t, k, c, fd, tt, kk;
  reg [8*L+64:0] line;
  task run_pattern(input integer t, input integer f);
    begin
      se = 1;
      for (c = 0; c < L; c = c + 1) begin
        @(negedge clk);
        for (k = 0; k < 16; k = k + 1) si[k] = ld[16*t + k][c];   // bit c of string = position L-1-c? see note
        @(posedge clk);
      end
      @(negedge clk); piv = pmem[t]; se = piv[16]; si = piv[15:0];
`ifdef INJECT
      if (f >= 0) inject(f);
`endif
      @(posedge clk); #1;
`ifdef INJECT
      if (f >= 0) release_all(f);
`endif
      @(negedge clk); se = 1;
      for (c = 0; c < L; c = c + 1) begin
        #3; for (k = 0; k < 16; k = k + 1) cap[k][c] = so[k];   // position L-1-c
        @(posedge clk); @(negedge clk);
      end
    end
  endtask
  initial begin
    $readmemb(`LOADFILE, ld); $readmemb(`PIFILE, pmem);
    fd = $fopen(`CAPFILE, "w");
    piv = 0; se = 1; si = 0;
    repeat (3) @(posedge clk);
`ifdef INJECT
    for (t = 0; t < `NFLT; t = t + 1) begin
      run_pattern(fpat(t), t);
      for (k = 0; k < 16; k = k + 1) $fdisplay(fd, "CAP %0d %0d %b", t, k, cap[k]);
    end
`else
    for (t = 0; t < `NPAT; t = t + 1) begin
      run_pattern(t, -1);
      for (k = 0; k < 16; k = k + 1) $fdisplay(fd, "CAP %0d %0d %b", t, k, cap[k]);
    end
`endif
    $fclose(fd); $finish;
  end
endmodule
