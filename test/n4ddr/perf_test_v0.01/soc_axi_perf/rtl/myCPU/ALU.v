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
	input wire[4 :0] sa,  // ��λָ���ṩ��sa
	input wire[31:0] HI_Read, LO_Read,
	input wire[31:0] CP0_data,
	output reg[31:0] result,
	output reg overflow,
	output reg[31:0] HI_Wrt, LO_Wrt
    );

	always @(*) begin
		case(AluOp)
			// 4 �ֻ����߼����� + 3���������߼����� = 7��
			`EXE_AND_OP: result <= n1 & n2;
	        `EXE_OR_OP : result <= n1 | n2;
	        `EXE_XOR_OP: result <= n1 ^ n2;
	        `EXE_NOR_OP: result <= ~(n1 | n2);

			// 4�ֻ������� + 2���������ӷ� + 8���ô�ָ�� = 14��
			`EXE_ADD_OP, `EXE_ADDU_OP: result <= n1 + n2;
			`EXE_SUB_OP, `EXE_SUBU_OP: result <= n1 - n2;

			// 2�������Ƚ����� + 2���������Ƚ� = 4��
			`EXE_SLT_OP : result <= ($signed(n1) < $signed(n2)) ? 1 : 0;
			`EXE_SLTU_OP: result <= (n1 < n2);

			// 1��д�߰���
			`EXE_LUI_OP : result <= {n2[15:0], 16'b0};

			// `EXE_MULT_OP 
			// `EXE_MULTU_OP  ����

			// 6����λָ��
			`EXE_SLL_OP : result <= n2 << sa;
			`EXE_SRL_OP : result <= n2 >> sa;
			`EXE_SRA_OP : result <= ({32 {n2[31]}} << (6'd32 - {1'b0, sa})) | (n2 >> sa);
			`EXE_SLLV_OP: result <= n2 << n1[4:0];
			`EXE_SRLV_OP: result <= n2 >> n1[4:0];
			`EXE_SRAV_OP: result <= ({32 {n2[31]}} << (6'd32 - {1'b0, n1[4:0]})) | (n2 >> n1[4:0]);

			// 4��HILOָ��
			`EXE_MFHI_OP: result <= HI_Read;
			`EXE_MFLO_OP: result <= LO_Read;

            // �˴�Ϊ�˷�ֹδ���ĵļĴ�����ԭ���ı�ֵ�ļĴ�����д����ȷ���Ƿ���Ҫ��һ��
			`EXE_MTHI_OP: begin HI_Wrt <= n1; LO_Wrt <= LO_Read; end
			`EXE_MTLO_OP: begin LO_Wrt <= n1; HI_Wrt <= HI_Read; end

			// 2�� CP0 ��ȡָ��
			`EXE_MTC0_OP: result <= n2;
			`EXE_MFC0_OP: result <= CP0_data; // ����֮ǰд���ˣ�������

			// �� 7 + 14 + 4 + 1 + 6 + 4 + 2 = 38 ��ָ��
			// ����δ����ָ�������
			// 12����תָ�� + 2������ָ�� + 1��ERETָ�� + 4���˳���ָ�� = 19��
			// 19 + 38 = 57��
			default: result <= 32'b0;  // Ĭ�����
		endcase
	end

	always @(*) begin
		case(AluOp)
			`EXE_ADD_OP : overflow <= (n1[31] & n2[31] & ~result[31]) | (~n1[31] & ~n2[31] & result[31]);
			`EXE_SUB_OP : overflow <= (n1[31] & ~n2[31] & ~result[31]) | (~n1[31] & n2[31] & result[31]);
			`EXE_ADDU_OP: overflow <= 0; // �޷��Ų��������
			`EXE_SUBU_OP: overflow <= 0; // �޷��Ų��������
			default: overflow <= 0; 	 // �������ֱ����ա���̫���ˣ��쳣��������Ῠס
		endcase
	end
endmodule
