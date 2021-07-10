`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 23:02:20
// Design Name: 
// Module Name: RegHILO
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


module RegHILO(
		input wire Clk,
		input wire Rst,
		input wire W_en,
		
		input wire[31:0] High, Low,
		output reg[31:0] High_Out, Low_Out
    );
    
    always @(negedge Clk) begin
    	// 时钟下半周期修改嗷，防止时序错乱；由于用的是寄存器变量
    	// 所以不用写读取的部分
    	if (Rst) begin
    		High_Out <= 0;
    		Low_Out  <= 0;
    	end else if (W_en) begin
    		High_Out <= High;
    		Low_Out  <= Low;
    	end
    end
endmodule
