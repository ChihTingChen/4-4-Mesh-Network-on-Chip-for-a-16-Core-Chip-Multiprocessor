`timescale 1ns / 1ps
// =============================================================
//  Cardinal Processor — ALU
//  Combinational, variable-width (8/16/32/64-bit lanes) ALU.
//  Handles all single-cycle R-type instructions. The multi-cycle
//  ops (VMULEU/VMULOU/VSQEU/VSQOU/VDIV/VMOD/VSQRT) go to the SFU.
//
//  Area/timing oriented structure:
//   - VADD/VSUB share ONE 71-bit adder; guard bits between bytes
//     kill/propagate the carry according to the lane width.
//   - VSLL/VSRL/VSRA share ONE lane-aware logarithmic right shifter
//     (left shifts are done by bit-reversing in and out).
//
//  Ports:
//    rA, rB  — 64-bit source operands (from ID/EX register)
//    ww      — 2-bit word-width selector (00=8b 01=16b 10=32b 11=64b)
//    func    — 6-bit function code (bits [26:31] of instruction)
//    result  — 64-bit output
// =============================================================
module alu (
    input  [63:0] rA,
    input  [63:0] rB,
    input  [1:0]  ww,
    input  [5:0]  func,
    output reg [63:0] result
);

localparam F_AND = 6'b000001, F_OR  = 6'b000010, F_XOR = 6'b000011,
           F_NOT = 6'b000100, F_MOV = 6'b000101, F_ADD = 6'b000110,
           F_SUB = 6'b000111, F_SLL = 6'b001010, F_SRL = 6'b001011,
           F_SRA = 6'b001100, F_RTTH = 6'b001101;

integer i, k;

// -------------------------------------------------------------
// VADD / VSUB : lane-partitioned adder
// -------------------------------------------------------------
wire sub = (func == F_SUB);
reg  [70:0] ax, ay;
always @(*) begin
    for (i = 0; i < 8; i = i + 1) begin
        ax[i*9 +: 8] = rA[i*8 +: 8];
        ay[i*9 +: 8] = sub ? ~rB[i*8 +: 8] : rB[i*8 +: 8];
        if (i < 7) begin
            // guard between byte i and i+1: lane boundary -> (sub,sub), else (1,0)
            if ((ww == 2'd0) || (ww == 2'd1 && i % 2 == 1) || (ww == 2'd2 && i == 3)) begin
                ax[i*9 + 8] = sub; ay[i*9 + 8] = sub;
            end else begin
                ax[i*9 + 8] = 1'b1; ay[i*9 + 8] = 1'b0;
            end
        end
    end
end
wire [70:0] asum = ax + ay + {70'b0, sub};
reg  [63:0] addsub;
always @(*)
    for (i = 0; i < 8; i = i + 1) addsub[i*8 +: 8] = asum[i*9 +: 8];

// -------------------------------------------------------------
// VSLL / VSRL / VSRA : one lane-aware right shifter
// -------------------------------------------------------------
wire left  = (func == F_SLL);
wire arith = (func == F_SRA);

function [63:0] rev64;
    input [63:0] v;
    integer j;
    for (j = 0; j < 64; j = j + 1) rev64[j] = v[63 - j];
endfunction

// Per-bit shift amount (bit k of the lane's amount) and lane sign.
// For left shifts the vector is reversed, so bit i belongs to the
// lane that originally held bit 63-i.
reg [63:0] amt [0:5];
reg [63:0] sgn;
reg [63:0] lmask [0:5];     // 1 if bit i+2^k is still inside bit i's lane
// lane width = 8<<w ; lane base of bit i = i - i % (8<<w)
`define LBR(i, w) ((i) - (i) % (8 << (w)))
`define LBL(i, w) ((63 - (i)) - (63 - (i)) % (8 << (w)))
integer w;
always @(*) begin
    for (k = 0; k < 6; k = k + 1) begin amt[k] = 64'b0; lmask[k] = 64'b0; end
    sgn = 64'b0;
    for (w = 0; w < 4; w = w + 1)                // unrolled: all indices constant
        for (i = 0; i < 64; i = i + 1)
            if (ww == w) begin
                sgn[i] = arith & rA[`LBR(i, w) + (8 << w) - 1];
                for (k = 0; k < 6; k = k + 1) begin
                    if (k < 3 + w)
                        amt[k][i] = left ? rB[`LBL(i, w) + k] : rB[`LBR(i, w) + k];
                    lmask[k][i] = ((i % (8 << w)) + (1 << k)) < (8 << w);
                end
            end
end
`undef LBR
`undef LBL

reg [63:0] sh [0:6];
always @(*) begin
    sh[0] = left ? rev64(rA) : rA;
    for (k = 0; k < 6; k = k + 1)
        for (i = 0; i < 64; i = i + 1)
            sh[k+1][i] = !amt[k][i] ? sh[k][i] :
                         (i + (1 << k) < 64 && lmask[k][i]) ? sh[k][(i + (1 << k)) % 64] : sgn[i];
end
wire [63:0] shifted = left ? rev64(sh[6]) : sh[6];

// -------------------------------------------------------------
// VRTTH : swap halves of every lane
// -------------------------------------------------------------
reg [63:0] rtth;
always @(*) begin
    for (i = 0; i < 64; i = i + 1) begin
        case (ww)
            2'd0: rtth[i] = rA[(i - i % 8)  + (i % 8  + 4)  % 8];
            2'd1: rtth[i] = rA[(i - i % 16) + (i % 16 + 8)  % 16];
            2'd2: rtth[i] = rA[(i - i % 32) + (i % 32 + 16) % 32];
            default: rtth[i] = rA[(i + 32) % 64];
        endcase
    end
end

// -------------------------------------------------------------
// Result select
// -------------------------------------------------------------
always @(*) begin
    case (func)
        F_AND:  result = rA & rB;
        F_OR:   result = rA | rB;
        F_XOR:  result = rA ^ rB;
        F_NOT:  result = ~rA;
        F_MOV:  result = rA;
        F_ADD, F_SUB: result = addsub;
        F_SLL, F_SRL, F_SRA: result = shifted;
        F_RTTH: result = rtth;
        default: result = 64'b0;   // SFU ops are selected in the CPU
    endcase
end

endmodule
