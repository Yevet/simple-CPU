`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/10 08:56:45
// Design Name: 
// Module Name: hilo_reg
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

module hilo_reg(
	input wire clk,rst,
	input wire[1:0]we,
	input wire[31:0] hi,lo,
	output reg[31:0] hi_o,lo_o
    );
	
	always @(negedge clk) begin
		if(rst) begin
			hi_o <= 0;
			lo_o <= 0;
		end else if (we==2'b11) begin
			hi_o <= hi;
			lo_o <= lo;
		end else if (we==2'b10) begin
		    hi_o <= hi;
		end else if(we==2'b01) begin
		    lo_o <= lo;
		end
	end
endmodule
