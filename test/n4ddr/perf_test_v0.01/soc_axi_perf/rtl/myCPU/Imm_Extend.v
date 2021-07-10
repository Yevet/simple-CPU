`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 18:50:01
// Design Name: 
// Module Name: Imm_Extend
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

module Imm_Extend #(parameter INPUT_WIDTH = 16, OUTPUT_WIDTH = 32) (
        input  wire [INPUT_WIDTH-1:0] Din,
        input  wire ExSign,
        output wire [OUTPUT_WIDTH-1:0] Dout
    );
    wire HiBit;
    assign HiBit = Din[INPUT_WIDTH-1] & ExSign;
    assign Dout = {{(OUTPUT_WIDTH - INPUT_WIDTH){ HiBit }}, Din};
endmodule
