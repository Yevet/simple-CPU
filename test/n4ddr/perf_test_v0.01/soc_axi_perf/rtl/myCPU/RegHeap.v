`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 21:28:35
// Design Name: 
// Module Name: RegHeap
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


module RegHeap(
		input wire clk,							// 时钟信号
		input wire W_en,							// 写使能
		input wire [4:0] R_pos1, R_pos2, W_pos,	// 读写的寄存器号
		input wire [31:0] W_data,					// 写的数据
		output wire [31:0] R_data1, R_data2		// 读出的数据
    );
    
    reg [31:0] RH [31:0];

	always @(negedge clk) begin
		// 时钟后半部分写入，防止时序错乱
		if(W_en) begin
			 RH[W_pos] <= W_data;
		end
	end

	// 0号寄存器只能输出0
	assign R_data1 = (R_pos1 != 0) ? RH [R_pos1] : 0;
	assign R_data2 = (R_pos2 != 0) ? RH [R_pos2] : 0;
    
endmodule
