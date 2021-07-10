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
		input wire clk,							// ʱ���ź�
		input wire W_en,							// дʹ��
		input wire [4:0] R_pos1, R_pos2, W_pos,	// ��д�ļĴ�����
		input wire [31:0] W_data,					// д������
		output wire [31:0] R_data1, R_data2		// ����������
    );
    
    reg [31:0] RH [31:0];

	always @(negedge clk) begin
		// ʱ�Ӻ�벿��д�룬��ֹʱ�����
		if(W_en) begin
			 RH[W_pos] <= W_data;
		end
	end

	// 0�żĴ���ֻ�����0
	assign R_data1 = (R_pos1 != 0) ? RH [R_pos1] : 0;
	assign R_data2 = (R_pos2 != 0) ? RH [R_pos2] : 0;
    
endmodule
