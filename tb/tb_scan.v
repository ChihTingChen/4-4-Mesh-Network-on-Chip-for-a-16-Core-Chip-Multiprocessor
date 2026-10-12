// ============================================================
//  tb_scan : scan-chain integrity (flush) test for the scan-
//  inserted cardinal_cmp netlist (16 chains, test_se active high)
//
//  1. test_se = 1, shift a random bit stream of CHAIN_LEN + 64 bits
//     into every test_si[k]
//  2. every test_so[k] must reproduce the stream delayed by exactly
//     CHAIN_LEN cycles (chains are non-inverting)
//  3. second pass with the complementary stream (both polarities on
//     every scan cell)
//
//  defines: CHAIN_LEN (required), CLK_HALF (shift clock / 2, ns),
//           SDF_FILE (optional back-annotation)
// ============================================================
`timescale 1ns/1ps
`ifndef CLK_HALF
  `define CLK_HALF 5.0
`endif
module tb_scan;
    localparam integer L = `CHAIN_LEN;
    localparam integer N = L + 64;
    localparam integer C = 16;

    reg clk = 0, reset = 0, test_se = 0;
    reg  [C-1:0] test_si = 0;
    wire [C-1:0] test_so;
    always #(`CLK_HALF) clk = ~clk;

    // functional inputs tied low (only the scan path is exercised)
    cardinal_cmp cmp (
        .clk(clk), .reset(reset), .test_se(test_se),
        .test_si_0_(test_si[0]), .test_so_0_(test_so[0]), .test_si_1_(test_si[1]), .test_so_1_(test_so[1]), .test_si_2_(test_si[2]), .test_so_2_(test_so[2]), .test_si_3_(test_si[3]), .test_so_3_(test_so[3]), .test_si_4_(test_si[4]), .test_so_4_(test_so[4]), .test_si_5_(test_si[5]), .test_so_5_(test_so[5]), .test_si_6_(test_si[6]), .test_so_6_(test_so[6]), .test_si_7_(test_si[7]), .test_so_7_(test_so[7]), .test_si_8_(test_si[8]), .test_so_8_(test_so[8]), .test_si_9_(test_si[9]), .test_so_9_(test_so[9]), .test_si_10_(test_si[10]), .test_so_10_(test_so[10]), .test_si_11_(test_si[11]), .test_so_11_(test_so[11]), .test_si_12_(test_si[12]), .test_so_12_(test_so[12]), .test_si_13_(test_si[13]), .test_so_13_(test_so[13]), .test_si_14_(test_si[14]), .test_so_14_(test_so[14]), .test_si_15_(test_si[15]), .test_so_15_(test_so[15]),
        .imem_data_00(32'd0), .dmem_data_out_00(64'd0), .imem_data_01(32'd0), .dmem_data_out_01(64'd0),
        .imem_data_02(32'd0), .dmem_data_out_02(64'd0), .imem_data_03(32'd0), .dmem_data_out_03(64'd0),
        .imem_data_10(32'd0), .dmem_data_out_10(64'd0), .imem_data_11(32'd0), .dmem_data_out_11(64'd0),
        .imem_data_12(32'd0), .dmem_data_out_12(64'd0), .imem_data_13(32'd0), .dmem_data_out_13(64'd0),
        .imem_data_20(32'd0), .dmem_data_out_20(64'd0), .imem_data_21(32'd0), .dmem_data_out_21(64'd0),
        .imem_data_22(32'd0), .dmem_data_out_22(64'd0), .imem_data_23(32'd0), .dmem_data_out_23(64'd0),
        .imem_data_30(32'd0), .dmem_data_out_30(64'd0), .imem_data_31(32'd0), .dmem_data_out_31(64'd0),
        .imem_data_32(32'd0), .dmem_data_out_32(64'd0), .imem_data_33(32'd0), .dmem_data_out_33(64'd0)
    );

`ifdef SDF_FILE
    initial $sdf_annotate(`SDF_FILE, cmp, , "sdf_annotate.log", "MAXIMUM");
`endif

    reg [C-1:0] stream [0:N-1];
    integer i, k, errors, checked, pass;
    integer seed = 577;

    initial begin
        errors = 0; checked = 0;
        for (pass = 0; pass < 2; pass = pass + 1) begin
            for (i = 0; i < N; i = i + 1)
                stream[i] = (pass == 0) ? $random(seed) : ~stream[i];
            @(negedge clk); test_se = 1;
            for (i = 0; i < N + L; i = i + 1) begin
                // drive on the falling edge, sample test_so just before the next rise
                test_si = (i < N) ? stream[i] : {C{1'b0}};
                @(posedge clk); #(`CLK_HALF * 0.9);
                // after the rising edge of shift cycle i the bit shifted in at
                // cycle (i - L + 1) is in the last flop and drives test_so
                if (i >= L - 1 && i - L + 1 < N) begin
                    for (k = 0; k < C; k = k + 1) begin
                        checked = checked + 1;
                        if (test_so[k] !== stream[i - L + 1][k]) begin
                            errors = errors + 1;
                            if (errors <= 20)
                                $display("ERROR pass %0d chain %0d bit %0d: got %b exp %b @%0t",
                                         pass, k, i - L + 1, test_so[k], stream[i - L + 1][k], $time);
                        end
                    end
                end
                @(negedge clk);
            end
        end
        $display("SCAN FLUSH TEST: chains=%0d length=%0d checked=%0d errors=%0d  => %s",
                 C, L, checked, errors, (errors == 0) ? "PASS" : "FAIL");
        $finish;
    end
endmodule
