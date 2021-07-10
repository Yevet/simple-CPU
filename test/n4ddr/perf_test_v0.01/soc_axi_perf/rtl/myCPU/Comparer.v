`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/03 00:30:49
// Design Name: 
// Module Name: Comparer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

// 比较器，用于判断跳转条件是否达成
module Comparer(
    input wire[31:0] a, b,
    input wire[5 :0] op,
    input wire[4 :0] rt,
    output wire y
    );

    assign y = (op == `EXE_BEQ)  ? (a == b):
                (op == `EXE_BNE)  ? (a != b):
                (op == `EXE_BGTZ) ? ((a[31] == 1'b0) && (a != `ZeroWord)):
                (op == `EXE_BLEZ) ? ((a[31] == 1'b1) || (a == `ZeroWord)):
                ((op == `EXE_REGIMM_INST) && ((rt == `EXE_BGEZ) || (rt == `EXE_BGEZAL)))? (a[31] == 1'b0):
                ((op == `EXE_REGIMM_INST) && ((rt == `EXE_BLTZ) || (rt == `EXE_BLTZAL)))? (a[31] == 1'b1):
                1'b0;
endmodule
