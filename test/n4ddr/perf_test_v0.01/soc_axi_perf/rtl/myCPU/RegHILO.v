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
    	// ʱ���°������޸�໣���ֹʱ����ң������õ��ǼĴ�������
    	// ���Բ���д��ȡ�Ĳ���
    	if (Rst) begin
    		High_Out <= 0;
    		Low_Out  <= 0;
    	end else if (W_en) begin
    		High_Out <= High;
    		Low_Out  <= Low;
    	end
    end
endmodule
