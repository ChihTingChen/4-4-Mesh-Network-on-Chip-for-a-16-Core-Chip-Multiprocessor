`timescale 1ns / 1ps
// 32 x 64-bit register file, 2 async read ports, 1 sync write port.
// r0 is hard-wired to zero (writes to r0 are ignored), so it needs no flops.
module register_file(
	input reset, clk, wrEn,
	input [4:0] addrA, addrB, waddr,
	input [63:0] data,
	output [63:0] dataA, dataB
);
	reg [63:0] regfile [1:31];
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 1; i < 32; i = i + 1) begin
                regfile[i] <= 64'b0;
            end
        end
        else if (wrEn && waddr != 5'd0) begin
            regfile[waddr] <= data;
        end
    end
	assign dataA = (addrA == 5'd0) ? 64'b0 : regfile[addrA];
	assign dataB = (addrB == 5'd0) ? 64'b0 : regfile[addrB];

endmodule
