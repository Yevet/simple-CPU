`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 21:48:50
// Design Name: 
// Module Name: PipeReg
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

// Á÷Ë®Ïß¼Ä´æÆ÷
module PipeReg #( parameter WIDTH = 8) (
        input wire clk, rst, en , clear,
        input wire [WIDTH-1:0] data ,
        output reg [WIDTH-1:0] ret
    );
    always @(posedge clk, posedge rst) begin
		if(rst) begin
			ret <= 0;
		end else if(clear) begin
			ret <= 0;
		end else if(en) begin
			ret <= data;
		end
	end
endmodule