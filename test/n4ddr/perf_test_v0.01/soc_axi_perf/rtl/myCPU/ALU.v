`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 22:35:11
// Design Name: 
// Module Name: ALU
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
module ALU(
	input wire[31:0] n1, n2,
	input wire[7 :0] AluOp,
	input wire[4 :0] sa,  // 移位指令提供的sa
	input wire[31:0] HI_Read, LO_Read,
	input wire[31:0] CP0_data,
	output reg[31:0] result,
	output reg overflow,
	output reg[31:0] HI_Wrt, LO_Wrt
    );

	always @(*) begin
		case(AluOp)
			// 4 种基础逻辑运算 + 3种立即数逻辑运算 = 7条
			`EXE_AND_OP: result <= n1 & n2;
	        `EXE_OR_OP : result <= n1 | n2;
	        `EXE_XOR_OP: result <= n1 ^ n2;
	        `EXE_NOR_OP: result <= ~(n1 | n2);

			// 4种基础运算 + 2种立即数加法 + 8条访存指令 = 14条
			`EXE_ADD_OP, `EXE_ADDU_OP: result <= n1 + n2;
			`EXE_SUB_OP, `EXE_SUBU_OP: result <= n1 - n2;

			// 2条基础比较运算 + 2条立即数比较 = 4条
			`EXE_SLT_OP : result <= ($signed(n1) < $signed(n2)) ? 1 : 0;
			`EXE_SLTU_OP: result <= (n1 < n2);

			// 1条写高半字
			`EXE_LUI_OP : result <= {n2[15:0], 16'b0};

			// `EXE_MULT_OP 
			// `EXE_MULTU_OP  暂留

			// 6条移位指令
			`EXE_SLL_OP : result <= n2 << sa;
			`EXE_SRL_OP : result <= n2 >> sa;
			`EXE_SRA_OP : result <= ({32 {n2[31]}} << (6'd32 - {1'b0, sa})) | (n2 >> sa);
			`EXE_SLLV_OP: result <= n2 << n1[4:0];
			`EXE_SRLV_OP: result <= n2 >> n1[4:0];
			`EXE_SRAV_OP: result <= ({32 {n2[31]}} << (6'd32 - {1'b0, n1[4:0]})) | (n2 >> n1[4:0]);

			// 4条HILO指令
			`EXE_MFHI_OP: result <= HI_Read;
			`EXE_MFLO_OP: result <= LO_Read;

            // 此处为了防止未更改的寄存器将原本改变值的寄存器覆写，不确定是否需要这一步
			`EXE_MTHI_OP: begin HI_Wrt <= n1; LO_Wrt <= LO_Read; end
			`EXE_MTLO_OP: begin LO_Wrt <= n1; HI_Wrt <= HI_Read; end

			// 2条 CP0 存取指令
			`EXE_MTC0_OP: result <= n2;
			`EXE_MFC0_OP: result <= CP0_data; // 这里之前写反了，很尴尬

			// 共 7 + 14 + 4 + 1 + 6 + 4 + 2 = 38 条指令
			// 其他未加入指令包括：
			// 12条跳转指令 + 2条自陷指令 + 1条ERET指令 + 4条乘除法指令 = 19条
			// 19 + 38 = 57条
			default: result <= 32'b0;  // 默认情况
		endcase
	end

	always @(*) begin
		case(AluOp)
			`EXE_ADD_OP : overflow <= (n1[31] & n2[31] & ~result[31]) | (~n1[31] & ~n2[31] & result[31]);
			`EXE_SUB_OP : overflow <= (n1[31] & ~n2[31] & ~result[31]) | (~n1[31] & n2[31] & result[31]);
			`EXE_ADDU_OP: overflow <= 0; // 无符号不考虑溢出
			`EXE_SUBU_OP: overflow <= 0; // 无符号不考虑溢出
			default: overflow <= 0; 	 // 其他情况直接清空……太坑了，异常处理这里会卡住
		endcase
	end
endmodule
