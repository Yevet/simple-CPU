`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/03 21:14:12
// Design Name: 
// Module Name: DataPath
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

// {DE_Branch, DE_Jump, DE_Jal, DE_Jr, DE_Bal};
`define Branch_J 				5'b01000
`define Branch_Jal 				5'b00100
`define Branch_Jr 				5'b01010
`define Branch_Jalr 			5'b00110
`define Branch_branch 			5'b10000
`define Branch_branchal 		5'b10001

`include "defines.vh"
module DataPath(
	input wire clk, rst,

	// FI stage
	output wire[31:0] FI_PC,
	input wire[31:0] FI_instr,

	// DE stage
	input wire DE_PcSelecter, DE_ImmExSg,
	input wire DE_Branch, DE_Jump,
	input wire DE_Jal, DE_Jr, DE_Bal,
	input wire DE_Invalid, DE_syscall, DE_break, DE_eret,
    output wire[31:0] DE_Inst,      				// DE�׶�ָ���͸�CTRLer
	output wire DE_Cmp,   							// �Ƚ������
	output wire DE_Stall, DE_Flush, 				// ��ˮ�߿���

	// EX stage
	input wire EX_Jal, EX_Bal,
	input wire EX_AluSelecter,
	input wire EX_RegWrite, EX_Mem2Reg, 
	input wire EX_WtRegSelecter,
	input wire EX_HILOWrt, EX_CP0Read, 
	input wire[7:0] EX_AluCtrl,
	output wire EX_Flush, EX_Stall,

	// ME stage
	input wire ME_Mem2Reg, ME_MemWrite,  			// ME ���źţ�MEд�ź�
	input wire[1:0] ME_MemSeg,						// ME ��д �ֽڿ����ź�
    input wire ME_ExSign, ME_RegWrite, ME_CP0Wen, 	// ME ������չ�źţ�ME�׶�д�ؿ����źţ�ME CP0дʹ��
	output wire[3:0] ME_MenWrtEnable, 				// MEM дʹ�ܿ����ź�
	output wire[31:0] ME_AluOut, ME_WrtData, 		// ALU��� �� д����
	input wire[31:0] ME_ReadDate,   				// MEM ��ȡ������
    output wire ME_Stall, ME_Flush,      			// ��ˮ�߿���

	// WB stage
	input wire WB_Mem2Reg, WB_RegWrite,
    output wire WB_Stall, WB_Flush, Except_Flush,

	input FI_ReqStall, ME_ReqStall,
	output wire[4 :0] WB_WrtRegPos, // д�ؼĴ���
	output wire[31:0] WB_PC, WB_Wrtdata 
    );

	// �����쳣���
	wire is_in_delayslotF, is_in_delayslotD, is_in_delayslotE, is_in_delayslotM;
	wire WB_CP0Wen;
	wire [7:0] FI_except, DE_except, EX_except, ME_except;
	wire [31:0] ME_BadAddr, ME_ExceptType, ME_NewPC;
	wire [31:0] CP0_StatusW, CP0_CauseW, CP0_EpcW, CP0_EX_ReadData, CP0_EX_ReadDataFD;
	wire [31:0] CP0_CountW, CP0_CompareW, CP0_ConfigW, CP0_PridW, CP0_BadVaddrW;
	wire [1:0] CP0_Forward;

	// ===================================================
	// ������� 
	wire FI_Stall, FI_FLush;
	wire [31:0] FI_PCadd4, FI_PCNext;

	wire [31:0] DE_PCadd4, DE_PC;
	wire DE_Forward_1, DE_Forward_2;
	wire[5:0] DE_OP;
	wire[4:0] DE_regPos1, DE_regPos2, DE_regPos3; // �Ĵ������
	wire[31:0] DE_RegRdData1, DE_RegRdData2;
	wire[31:0] DE_HazardRegRdData1, DE_HazardRegRdData2;
	// wire[4:0] WB_WrtRegPos;   // д�ؼĴ���
	wire[15:0] DE_Imm; // ������
	wire[31:0] DE_ImmExtend, DE_ImmExShifted;
	wire[27:0] InstrIndex;
	wire[31:0] PCAdd4_AddImmExShifted, PCInstrIdxConcat, PCFromReg; // PC + 4 + ��������PC��4λ��InstrIndex�ϲ�
	wire[4:0] BJState; // ��ת�����źźϲ��������ж�
	wire[31:0] DE_PCBranchNext;
	wire[4:0] DE_RdSelected; // Jal �� Bal �� RegD ��Ϊ 31��Jalr��Ϊ rd or 31 when rd == 0
	wire DE_regPos3EqZero;
	wire [4:0] DE_SA; // ��λ�Ĵ���������
	wire [2:0] DE_Sel;


	wire[4:0] EX_regPos1, EX_regPos2, EX_regPos3, EX_SA, EX_WrtRegPos;
	wire[2:0] EX_Sel;
	wire[1:0] EX_Forward_1, EX_Forward_2;
	wire[31:0] EX_RegData1, EX_RegData2, EX_Imm, EX_RegFord, EX_PC;
	wire[31:0] EX_HI_Read, EX_LO_Read, EX_AluHI_Wrt, EX_AluLO_Wrt;
	wire[31:0] EX_ALUop1, EX_ALUop2, EX_AluY, EX_AluResult;
	// EX_AluY ֮��Ҫ��ȥ��PC+8��2ѡ1
	wire[31:0] EX_PCAdd8;
	wire EX_Overflow;
	wire EX_MULDIV_Stall; 				// �˳�������ˮ����ͣ�ź�
	wire MulMode, DivMode;
	wire MD_SignMode;
	wire MD_Stop; 						// Stop�źţ��ݲ�֪��������õ����������쳣����
	wire MUL_Ready, DIV_Ready; 			// �����������ź�
	wire[63:0] MUL_Result, DIV_Result;  // �����������Ľ��
	wire[31:0] EX_DMHI_Wrt, EX_MDLO_Wrt;
	wire[31:0] EX_HI_Wrt, EX_LO_Wrt;


	wire[31:0] ME_AluResult, ME_MemWrtData, ME_PC;
	wire[4:0] ME_WrtRegPos, ME_regPos3;
	wire[2:0] ME_Sel;
	wire[3:0] ME_SB_WEN;
	wire[3:0] ME_SH_WEN; 	// ����ʹ��
	wire ME_AddrInvalid;
	wire[7 :0] ReadByte; 	// �ֽ�
	wire[15:0] ReadHfWd; 	// ����
	wire[31:0] LB_Data, LH_Data; // LW_data = ME_ReadDate
	wire[31:0] ME_DataWrtBack;  	// ���ݸ�д�ؽ׶ε����� 
	wire ME_ADEL, ME_ADES;


	wire[4:0] WB_regPos3;
	wire[31:0] WB_AluResult, WB_MemReadData;
	// ===============================================================================
	// ==================================== F I ======================================
	// ===============================================================================
	
	// FI �׶�
	PC #(32) PcReg(clk, rst, ~FI_Stall, FI_FLush, FI_PCNext, ME_NewPC, FI_PC);  // PC ��ˮ�߼Ĵ���
	PCAdd PcAdd_4(FI_PC, 32'b100, FI_PCadd4);  // PC + 4
	assign is_in_delayslotF = (DE_Jump | DE_Jal | DE_Jr | DE_Branch | DE_Bal);
	assign FI_except = (FI_PC[1:0] == 2'b00)? 8'b00000000 : 8'b01000000;
	
	// ��¼��ǰָ���Ƿ����ӳٲ�(����--2����Ȩ�ƶ�ָ���Ƿ����ӳٲ�)

	// Ҫ�õ�PC����תѡ��Ҳ����ȷ��PC_next������Ҫ�Ƚ��������ǱȽ���
	// ����Ҫ����DE�׶εļĴ���������PCûд�꣬��дde

	// ===============================================================================
	// ==================================== D E ======================================
	// ===============================================================================

	// DE �׶�
	assign DE_regPos1 = DE_Inst[25:21];
	assign DE_regPos2 = DE_Inst[20:16];
	assign DE_regPos3 = DE_Inst[15:11];
	assign DE_OP = DE_Inst[31:26];
	
	// Ψһ��DE�׶εļ���WB����
	RegHeap regHP (
		clk, WB_RegWrite, /* дʹ����ʱ������WB�׶β��ܻ�� */
		DE_regPos1, DE_regPos2, WB_WrtRegPos, /* ͬ�� */
		WB_Wrtdata,  /* ͬ�� */
		DE_RegRdData1, DE_RegRdData2
	);

	Mux_21 #(32) Ex_Ford_1(
		DE_Forward_1,
		DE_RegRdData1,
		ME_AluOut,
		DE_HazardRegRdData1
	);
	Mux_21 #(32) Ex_Ford_2(
		DE_Forward_2,
		DE_RegRdData2,
		ME_AluOut,
		DE_HazardRegRdData2
	);

	Comparer cmp( // �Ƚ���
		DE_HazardRegRdData1, DE_HazardRegRdData2, 
    	DE_OP,
    	DE_regPos2,
    	DE_Cmp
	);

	assign DE_Imm = DE_Inst[15:0];
	
	Imm_Extend #(16, 32) ImmEx(  // ��������������չ 
		DE_Imm,
        DE_ImmExSg,
        DE_ImmExtend
	);
	ImmShift ImmShift2( // ��������չ������2λ
		DE_ImmExtend,
		DE_ImmExShifted
	);

	assign InstrIndex = {DE_Inst[25:0], 2'b00}; // J��ָ��� InstrIndex ������ 2 λ
	assign BJState = {DE_Branch, DE_Jump, DE_Jal, DE_Jr, DE_Bal};
	assign PCInstrIdxConcat = {DE_PC[31:28], InstrIndex};
	assign PCFromReg = DE_HazardRegRdData1; 

	PCAdd PcAddImm(DE_PCadd4, DE_ImmExShifted, PCAdd4_AddImmExShifted);  // PC + 4 + ImmExShifted
	// ���е� reg[31 or xx] = PC + 8 ͳһ�ŵ�EX�׶�
	assign DE_PCBranchNext = ((BJState == `Branch_J		)||(BJState == `Branch_Jal		))? PCInstrIdxConcat:
							 ((BJState == `Branch_Jr	)||(BJState == `Branch_Jalr		))? PCFromReg:
							 ((BJState == `Branch_branch)||(BJState == `Branch_branchal	))? PCAdd4_AddImmExShifted:
							 DE_PCadd4;
	
	Mux_21 #(32) PC_Select (
	   DE_PcSelecter,
		FI_PCadd4, DE_PCBranchNext,
		FI_PCNext
	);

	// ��Ϊ Bal��JalҪ��д31�żĴ�������JalrҪ��дrd�Ĵ��������ڿ������У�Bal��Jal��
	// д��Ĵ����Ŷ�Ĭ����rd�����ֻ��Ҫ��rd�����޸ļ���
	assign DE_regPos3EqZero = DE_regPos3 == 5'b0 ? 1'b1 : 1'b0;
	Mux_21 #(5) Rd_Select (
		((DE_Jal & ~DE_Jr) | DE_Bal | (DE_Jal & DE_Jr & DE_regPos3EqZero)),
		DE_regPos3, 5'd31,	  // 31�żĴ���
		DE_RdSelected
	);

	assign DE_SA = DE_Inst[10:6];
	assign DE_Sel = DE_Inst[2:0]; // CP0


	// ===============================================================================
	// ==================================== E X ======================================
	// ===============================================================================

	Mux_41 #(32) EX_Ford1(
		EX_Forward_1,
		EX_RegData1,
		ME_AluOut,
		WB_Wrtdata,
		EX_RegData1,
		EX_ALUop1
	);
	Mux_41 #(32) EX_Ford2(
		EX_Forward_2,
		EX_RegData2,
		ME_AluOut,
		WB_Wrtdata,
		EX_RegData2,
		EX_RegFord
	);

	assign EX_PCAdd8 = DE_PCadd4;
	// DE�׶ε�PC+4�����EX�׶ξ���PC+8

	Mux_21 #(32) AluOp2Select(
		EX_AluSelecter,
		EX_RegFord, 
		EX_Imm,
		EX_ALUop2
	);


	// CP0 Read Data ǰ��
	Mux_41 #(32) CP0_Ford(
		CP0_Forward,
		CP0_EX_ReadData,
		ME_AluResult,
		WB_AluResult,
		CP0_EX_ReadData,
		CP0_EX_ReadDataFD
	);

	ALU AluModel(
		EX_ALUop1, EX_ALUop2,
		EX_AluCtrl,
		EX_SA,  						// ��λָ���ṩ��sa
		EX_HI_Read, EX_LO_Read,
		CP0_EX_ReadDataFD,  			// CP0_Data����֪��զ�� (���ڼ���CP0ģ��)
		EX_AluY,
		EX_Overflow,
		EX_AluHI_Wrt, EX_AluLO_Wrt 		// ALU�����HILOд����
    );

	Mux_21 #(32) AluResultSelect(  		// ѡ�� �Ƿ��� PC + 8
		(EX_Jal | EX_Bal),
		EX_AluY, 
		EX_PCAdd8,
		EX_AluResult
	);

	// �����Ǹ��� EX_WtRegSelecter ȷ��д�Ĵ����� EX_WrtRegPos
	Mux_21 #(5) WrtRegPosSelect(  		// ѡ��Ҫд�ļĴ�����
		EX_WtRegSelecter,
		EX_regPos2,
		EX_regPos3,
		EX_WrtRegPos
	);

	// �˳�������

	assign MD_Stop = 1'b0;  			// ��ͳ���ܣ���֪���ľ�����Ĭ��ֵ���Ժ����Ÿ�


	assign MulMode = (EX_AluCtrl == `EXE_MULT_OP) || (EX_AluCtrl == `EXE_MULTU_OP);
	assign DivMode = (EX_AluCtrl == `EXE_DIV_OP)  || (EX_AluCtrl == `EXE_DIVU_OP);
	assign MD_SignMode = ~((EX_AluCtrl == `EXE_MULTU_OP)||(EX_AluCtrl == `EXE_DIVU_OP));

	// ��Ϊ�˳�����ģʽʱ���ҽ��δ׼������ʱ������ˮ��

	MUL mul__(  						// �˷�  MULT rs, rt
    	clk, rst,
    	MD_SignMode,

    	EX_ALUop1, EX_RegFord,
    	MulMode, MD_Stop,

    	MUL_Result,
    	MUL_Ready
    );
	DIV div__(  // ����
    	clk, rst,
    	MD_SignMode,

    	EX_ALUop1, EX_RegFord,
    	DivMode, MD_Stop,

    	DIV_Result,
    	DIV_Ready
    );

	assign EX_MULDIV_Stall = ((MulMode | DivMode) & ~(MUL_Ready | DIV_Ready));

	// ȷ��HILOд��ֵ
	assign {EX_DMHI_Wrt, EX_MDLO_Wrt} = (MulMode && ~DivMode) ? MUL_Result:
										(~MulMode && DivMode) ? DIV_Result:
										64'b0;

	// EX_HILO_Wrt ͨ��EX_HILOWrt�ź��ж���д��ALU�Ľ�����ǳ˳����Ľ��
	assign EX_HI_Wrt = (EX_HILOWrt == 1'b1) ? EX_AluHI_Wrt : EX_DMHI_Wrt;
	assign EX_LO_Wrt = (EX_HILOWrt == 1'b1) ? EX_AluLO_Wrt : EX_MDLO_Wrt;

	// HILO �Ĵ�����д���������֣�һ����ALU�����д�źţ���һ���ǳ˳�����д�ź�
	// ����Ϊ (EX_HILOWrt | MUL_Ready | DIV_Ready)
	// ����ALUCtrl�Ļ����ԣ���3���ź�Ӧ�ò���ͬʱ����
	RegHILO HILO(
		clk, rst,
		(EX_HILOWrt | (MUL_Ready & MulMode) | (DIV_Ready & DivMode)),
		EX_HI_Wrt, EX_LO_Wrt,
		EX_HI_Read, EX_LO_Read
	);

	// ===============================================================================
	// ==================================== M E ======================================
	// ===============================================================================


	// ��������ǰ�ж�Wʹ��
	Mux_41 #(4) SB_WEN(		// д�ֽ�ʹ��
		ME_AluResult[1:0],
		4'b0001,  			// ��ַ��00��β 
		4'b0010,			// ��ַ��01��β 
		4'b0100,			// ��ַ��10��β 
		4'b1000,			// ��ַ��11��β 
		ME_SB_WEN
	);

	Mux_21 #(4) SH_WEN(
		ME_AluResult[1],
		4'b0011,  			// ��ַ��00��β 
		4'b1100,			// ��ַ��10��β 
		ME_SH_WEN
	);

	// �������ж� MEM��ַ�Ƿ�Ƿ�
	assign ME_AddrInvalid = ((ME_AluResult[0] == 1'b1 && 
							(ME_MemSeg == 2'b01 || ME_MemSeg == 2'b10)) ||
							(ME_MemSeg == 2'b10 && ME_AluResult[1] == 1'b1));

	assign ME_AluOut = ME_AluResult; 				// MEM �ĵ�ַ

	wire[7:0] ME_WrtByte;
	wire[15:0] ME_WrtHalfWord;
	assign ME_WrtByte = ME_MemWrtData[7:0];			// �����λ��ʼȡ
	assign ME_WrtHalfWord = ME_MemWrtData[15:0];	// �����λ��ʼȡ
	// MEM��ַ���Զ�4λ���룬����Ҫ�ֶ����洢�����ݽ�����λ����͸

	assign ME_MenWrtEnable = (ME_MemWrite == 1'b0 || ME_AddrInvalid) ? 4'b0000  :  // ��дģʽ���쳣
							 (ME_MemSeg == 2'b00 ) ? ME_SB_WEN:  // д�ֽ�
							 (ME_MemSeg == 2'b01 ) ? ME_SH_WEN:  // д����
							 (ME_MemSeg == 2'b10 ) ? 4'b1111  : 4'b0000;

	assign ME_WrtData = (ME_MenWrtEnable == 4'b1000) ? {ME_WrtByte, 24'b0} 			:
						(ME_MenWrtEnable == 4'b0100) ? {8'b0, ME_WrtByte, 16'b0} 	:
						(ME_MenWrtEnable == 4'b0010) ? {16'b0, ME_WrtByte, 8'b0} 	:
						(ME_MenWrtEnable == 4'b0001) ? {24'b0, ME_WrtByte} 			:
						(ME_MenWrtEnable == 4'b1100) ? {ME_WrtHalfWord, 16'b0} 		:
						(ME_MenWrtEnable == 4'b0011) ? {16'b0, ME_WrtHalfWord} 		:
						(ME_MenWrtEnable == 4'b1111) ? ME_MemWrtData 				:
						32'b0;

	// ��Ҫ�ǵð� ReadData �ж����Ͳ�����
	// �ȸ��� Addr �Ѷ�Ӧ�Ĳ���ȡ����
	Mux_41 #(8) ByteSelect(
		ME_AluResult[1:0],
		ME_ReadDate[7 : 0],  		// ��ַ��00��β
		ME_ReadDate[15: 8],			// ��ַ��01��β
		ME_ReadDate[23:16],			// ��ַ��10��β
		ME_ReadDate[31:24],			// ��ַ��11��β
		ReadByte
	);
	Mux_21 #(16) HfWdSelect(
		ME_AluResult[1],
		ME_ReadDate[15: 0],  		// ��ַ��00��β 
		ME_ReadDate[31:16],			// ��ַ��10��β 
		ReadHfWd
	);

	// �ٽ����ݽ�����չ�����32λ
	Imm_Extend #(8, 32) LB_Ext(
		ReadByte,
		ME_ExSign, 
        LB_Data
    );
	Imm_Extend #(16, 32) LH_Ext(
		ReadHfWd,
		ME_ExSign, 
        LH_Data
    );

	// ������ ME_MemSeg �����ݽ���ѡ��
	Mux_41 #(32) DataWB_Select(
		ME_MemSeg,
		LB_Data,  				// �ֽ�
		LH_Data,				// ����
		ME_ReadDate,			// ȫ��
		ME_ReadDate,			// other
		ME_DataWrtBack
	);

	assign ME_ADEL = ME_Mem2Reg  && ME_AddrInvalid;  	// Load ��ַ�쳣�жϣ����ڴ�
	assign ME_ADES = ME_MemWrite && ME_AddrInvalid;  	// Save ��ַ�쳣�жϣ�д�ڴ�
	// ��TMд���ˣ�Fuck��

	assign ME_BadAddr = (ME_except[6])		? ME_PC		:
					    (ME_ADEL | ME_ADES) ? ME_AluOut : 32'b0;

	// wire ME_ADEL, ME_ADES;
	// CP0  ���������������Ȳ�ʵ�֣���ͳ����������
	// �����뻹�Ƿŵ�д���ˣ���Ϊ�쳣������Ҫʹ�ܣ������쳣������ME�׶νӹ�ȥҲûɶ����

	exception except(
		rst,
    	WB_CP0Wen,
    	WB_regPos3,
    	WB_AluResult,
    	ME_ADEL, ME_ADES,
		ME_except,
		CP0_StatusW, CP0_CauseW, CP0_EpcW,
		ME_ExceptType, ME_NewPC
    );
	//

	// ===============================================================================
	// ==================================== W B ======================================
	// ===============================================================================
	Mux_21 #(32) WB_WrtDataSelete(
		WB_Mem2Reg,			// �Ƿ���MEMд���Ĵ���
		WB_AluResult,		// ALU�Ľ��
		WB_MemReadData,		// Mem��������
		WB_Wrtdata			// д�ؼĴ�������
	);

	cp0_reg CP0(
		.clk					(clk),
		.rst					(rst),
		.we_i					(WB_CP0Wen),
		.waddr_i				(WB_regPos3),
		.raddr_i				(EX_regPos3),
		.data_i					(WB_AluResult),
		.int_i					(6'b000000),
		.excepttype_i			(ME_ExceptType),
		.current_inst_addr_i	(ME_PC),
		.is_in_delayslot_i		(is_in_delayslotM),
		.bad_addr_i				(ME_BadAddr),
		.data_o					(CP0_EX_ReadData),
		.count_o				(CP0_CountW),
		.compare_o				(CP0_CompareW),
		.status_o				(CP0_StatusW),
		.cause_o				(CP0_CauseW),
		.epc_o					(CP0_EpcW),
		.config_o				(CP0_ConfigW),
		.prid_o					(CP0_PridW),
		.badvaddr				(CP0_BadVaddrW)
	);
	// ===============================================================================
	// ================================ ��ˮ�߼Ĵ��� ==================================
	// ===============================================================================
	PipeReg #(32) DE_r1(clk, rst, ~DE_Stall, DE_Flush, FI_PC, DE_PC);
	PipeReg #(32) DE_r2(clk, rst, ~DE_Stall, DE_Flush, FI_PCadd4, DE_PCadd4);
	PipeReg #(32) DE_r3(clk, rst, ~DE_Stall, DE_Flush, FI_instr, DE_Inst);


	PipeReg #(5)  EX_r1(clk, rst, ~EX_Stall, EX_Flush, DE_regPos1, EX_regPos1);
	PipeReg #(5)  EX_r2(clk, rst, ~EX_Stall, EX_Flush, DE_regPos2, EX_regPos2);
	PipeReg #(5)  EX_r3(clk, rst, ~EX_Stall, EX_Flush, DE_RdSelected, EX_regPos3);
	PipeReg #(5)  EX_r4(clk, rst, ~EX_Stall, EX_Flush, DE_SA, EX_SA);
	PipeReg #(32) EX_r5(clk, rst, ~EX_Stall, EX_Flush, DE_RegRdData1, EX_RegData1);
	PipeReg #(32) EX_r6(clk, rst, ~EX_Stall, EX_Flush, DE_RegRdData2, EX_RegData2);
	PipeReg #(32) EX_r7(clk, rst, ~EX_Stall, EX_Flush, DE_ImmExtend, EX_Imm);
	PipeReg #(3)  EX_r8(clk, rst, ~EX_Stall, EX_Flush, DE_Sel, EX_Sel);


	PipeReg #(32) ME_r1(clk, rst, ~ME_Stall, ME_Flush, EX_AluResult, ME_AluResult);
	PipeReg #(32) ME_r2(clk, rst, ~ME_Stall, ME_Flush, EX_RegFord, ME_MemWrtData); 
	PipeReg #(5)  ME_r3(clk, rst, ~ME_Stall, ME_Flush, EX_WrtRegPos, ME_WrtRegPos);
	PipeReg #(3)  ME_r4(clk, rst, ~ME_Stall, ME_Flush, EX_Sel, ME_Sel);


	PipeReg #(32) WB_r1(clk, rst, ~WB_Stall, WB_Flush, ME_AluResult, WB_AluResult);
	PipeReg #(32) WB_r2(clk, rst, ~WB_Stall, WB_Flush, ME_DataWrtBack, WB_MemReadData);
	PipeReg #(5 ) WB_r3(clk, rst, ~WB_Stall, WB_Flush, ME_WrtRegPos, WB_WrtRegPos);

	// ===============================================================================
	// ================================== ð��ģ�� ====================================
	// ===============================================================================
	
	// �ܽ᣺
	/*
	|| 1. ��99~100�д��������Ĵ�����ȡֵ��Ҫ��������ǰ��
	|| 2. ��153�д��� PC����������תûд��������Ҫ�쳣�������
	|| 3. ��185�д���ALU������������������Ҫ����ǰ��
	*/
	
	hazard h(
	    FI_Stall, FI_FLush,
        DE_Stall, DE_Flush,             // 
        EX_Stall, EX_Flush,             // 
        ME_Stall, ME_Flush,             // 
        WB_Stall, WB_Flush,             // ��ˮ�߿����ź�
        Except_Flush,

        DE_Forward_1, DE_Forward_2,     // 
        EX_Forward_1, EX_Forward_2,  	// ����ǰ��ѡ���ź�
        CP0_Forward,                	// CP0����ǰ��ѡ���ź�

        FI_ReqStall, ME_ReqStall,

        DE_regPos1, DE_regPos2,     	// 
        EX_regPos1, EX_regPos2,     	// �����Ĵ�����λ��
        EX_regPos3, ME_regPos3, WB_regPos3,
        EX_WrtRegPos,               	//
        ME_WrtRegPos,               	//
        WB_WrtRegPos,               	// �����Ĵ���дλ��

        EX_RegWrite ,                   // EX �Ĵ���дʹ��
        EX_Mem2Reg  ,                   // EX �ڴ�д�Ĵ���
        ME_RegWrite ,                   // ME �Ĵ���дʹ��
        ME_Mem2Reg  ,                   // ME �ڴ�д�Ĵ���
        WB_RegWrite ,                   // WB �Ĵ���дʹ��
        
		EX_MULDIV_Stall,				// �˳���
		DE_Branch, DE_Jr,
		EX_CP0Read, ME_CP0Wen, WB_CP0Wen,
		ME_ExceptType
    );

	// ===============================================================================
	// =============================== �쳣״̬�Ĵ��� =================================
	// ===============================================================================
	PipeReg #(1)  DE_Er1(clk, rst, ~DE_Stall, DE_Flush, is_in_delayslotF, is_in_delayslotD);
	PipeReg #(8)  DE_Er2(clk, rst, ~DE_Stall, DE_Flush, FI_except, DE_except);
	
	
	PipeReg #(1)  EX_Er1(clk, rst, ~EX_Stall, EX_Flush, is_in_delayslotD, is_in_delayslotE);
	PipeReg #(32) EX_Er2(clk, rst, ~EX_Stall, EX_Flush, DE_PC, EX_PC);
	PipeReg #(8)  EX_Er3(clk, rst, ~EX_Stall, EX_Flush, 
		{DE_except[7:5], DE_syscall, DE_break, DE_eret, DE_Invalid, DE_except[0]}, EX_except);
	
	
	PipeReg #(1)  ME_Er1(clk, rst, ~ME_Stall, ME_Flush, is_in_delayslotE, is_in_delayslotM);
	PipeReg #(32) ME_Er2(clk, rst, ~ME_Stall, ME_Flush, EX_PC, ME_PC);
	PipeReg #(8)  ME_Er3(clk, rst, ~ME_Stall, ME_Flush, {EX_except[7:1], EX_Overflow}, ME_except);
	PipeReg #(5)  ME_Er4(clk, rst, ~ME_Stall, ME_Flush, EX_regPos3, ME_regPos3);	
	

	PipeReg #(1)  WB_Er1(clk, rst, ~WB_Stall, WB_Flush, ME_CP0Wen, WB_CP0Wen);
	PipeReg #(32)  WB_Er2(clk, rst, ~WB_Stall, WB_Flush, ME_PC, WB_PC);
	PipeReg #(5)  WB_Er3(clk, rst, ~WB_Stall, WB_Flush, ME_regPos3, WB_regPos3);

	// ����CP0Ҳ���ܴ�������ð�գ���Ҫ����ǰ�ƣ�����ò�ƿ��Կ�����ͨ�ļĴ���ȡֵð�գ�������
	// ͬһ�׷�������
endmodule
