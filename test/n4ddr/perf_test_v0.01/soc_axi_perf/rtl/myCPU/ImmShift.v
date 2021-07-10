`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/04 16:57:39
// Design Name: 
// Module Name: ImmShift
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

module ImmShift(
    input wire[31:0] Imm,
	output wire[31:0] y
    );
    
    assign y = {Imm[29:0], 2'b00};
endmodule
