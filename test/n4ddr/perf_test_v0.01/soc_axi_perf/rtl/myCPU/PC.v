`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/03 00:05:16
// Design Name: 
// Module Name: PC
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

// PC Ä£¿é
module PC #(parameter WIDTH = 32) (
    input wire clk, rst, en, clear,
	input wire[WIDTH-1:0] data,
	input wire[WIDTH-1:0] newpc,
	output reg[WIDTH-1:0] ret
    );
    initial begin
        ret <= 32'hbfc00000;
    end
    always @(posedge clk, posedge rst) begin
		if(rst) begin
			ret <= 32'hbfc00000;
		end else if(clear) begin
			ret <= newpc;
		end else if(en) begin
			ret <= data;
		end else begin
		    ret <= ret;
		end
	end
endmodule
