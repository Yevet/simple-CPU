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
    output wire[31:0] DE_Inst,      				// DE阶段指令送给CTRLer
	output wire DE_Cmp,   							// 比较器结果
	output wire DE_Stall, DE_Flush, 				// 流水线控制

	// EX stage
	input wire EX_Jal, EX_Bal,
	input wire EX_AluSelecter,
	input wire EX_RegWrite, EX_Mem2Reg, 
	input wire EX_WtRegSelecter,
	input wire EX_HILOWrt, EX_CP0Read, 
	input wire[7:0] EX_AluCtrl,
	output wire EX_Flush, EX_Stall,

	// ME stage
	input wire ME_Mem2Reg, ME_MemWrite,  			// ME 读信号，ME写信号
	input wire[1:0] ME_MemSeg,						// ME 读写 字节控制信号
    input wire ME_ExSign, ME_RegWrite, ME_CP0Wen, 	// ME 符号扩展信号，ME阶段写回控制信号，ME CP0写使能
	output wire[3:0] ME_MenWrtEnable, 				// MEM 写使能控制信号
	output wire[31:0] ME_AluOut, ME_WrtData, 		// ALU结果 和 写数据
	input wire[31:0] ME_ReadDate,   				// MEM 读取的数据
    output wire ME_Stall, ME_Flush,      			// 流水线控制

	// WB stage
	input wire WB_Mem2Reg, WB_RegWrite,
    output wire WB_Stall, WB_Flush, Except_Flush,

	input FI_ReqStall, ME_ReqStall,
	output wire[4 :0] WB_WrtRegPos, // 写回寄存器
	output wire[31:0] WB_PC, WB_Wrtdata 
    );

	// 定义异常相关
	wire is_in_delayslotF, is_in_delayslotD, is_in_delayslotE, is_in_delayslotM;
	wire WB_CP0Wen;
	wire [7:0] FI_except, DE_except, EX_except, ME_except;
	wire [31:0] ME_BadAddr, ME_ExceptType, ME_NewPC;
	wire [31:0] CP0_StatusW, CP0_CauseW, CP0_EpcW, CP0_EX_ReadData, CP0_EX_ReadDataFD;
	wire [31:0] CP0_CountW, CP0_CompareW, CP0_ConfigW, CP0_PridW, CP0_BadVaddrW;
	wire [1:0] CP0_Forward;

	// ===================================================
	// 定义变量 
	wire FI_Stall, FI_FLush;
	wire [31:0] FI_PCadd4, FI_PCNext;

	wire [31:0] DE_PCadd4, DE_PC;
	wire DE_Forward_1, DE_Forward_2;
	wire[5:0] DE_OP;
	wire[4:0] DE_regPos1, DE_regPos2, DE_regPos3; // 寄存器结果
	wire[31:0] DE_RegRdData1, DE_RegRdData2;
	wire[31:0] DE_HazardRegRdData1, DE_HazardRegRdData2;
	// wire[4:0] WB_WrtRegPos;   // 写回寄存器
	wire[15:0] DE_Imm; // 立即数
	wire[31:0] DE_ImmExtend, DE_ImmExShifted;
	wire[27:0] InstrIndex;
	wire[31:0] PCAdd4_AddImmExShifted, PCInstrIdxConcat, PCFromReg; // PC + 4 + 立即数，PC高4位与InstrIndex合并
	wire[4:0] BJState; // 跳转控制信号合并，方便判断
	wire[31:0] DE_PCBranchNext;
	wire[4:0] DE_RdSelected; // Jal 与 Bal 将 RegD 改为 31，Jalr改为 rd or 31 when rd == 0
	wire DE_regPos3EqZero;
	wire [4:0] DE_SA; // 移位寄存器立即数
	wire [2:0] DE_Sel;


	wire[4:0] EX_regPos1, EX_regPos2, EX_regPos3, EX_SA, EX_WrtRegPos;
	wire[2:0] EX_Sel;
	wire[1:0] EX_Forward_1, EX_Forward_2;
	wire[31:0] EX_RegData1, EX_RegData2, EX_Imm, EX_RegFord, EX_PC;
	wire[31:0] EX_HI_Read, EX_LO_Read, EX_AluHI_Wrt, EX_AluLO_Wrt;
	wire[31:0] EX_ALUop1, EX_ALUop2, EX_AluY, EX_AluResult;
	// EX_AluY 之后要拿去和PC+8做2选1
	wire[31:0] EX_PCAdd8;
	wire EX_Overflow;
	wire EX_MULDIV_Stall; 				// 乘除法的流水线暂停信号
	wire MulMode, DivMode;
	wire MD_SignMode;
	wire MD_Stop; 						// Stop信号，暂不知道哪里会用到，可能是异常处理？
	wire MUL_Ready, DIV_Ready; 			// 运算结果就绪信号
	wire[63:0] MUL_Result, DIV_Result;  // 两个运算器的结果
	wire[31:0] EX_DMHI_Wrt, EX_MDLO_Wrt;
	wire[31:0] EX_HI_Wrt, EX_LO_Wrt;


	wire[31:0] ME_AluResult, ME_MemWrtData, ME_PC;
	wire[4:0] ME_WrtRegPos, ME_regPos3;
	wire[2:0] ME_Sel;
	wire[3:0] ME_SB_WEN;
	wire[3:0] ME_SH_WEN; 	// 半字使能
	wire ME_AddrInvalid;
	wire[7 :0] ReadByte; 	// 字节
	wire[15:0] ReadHfWd; 	// 半字
	wire[31:0] LB_Data, LH_Data; // LW_data = ME_ReadDate
	wire[31:0] ME_DataWrtBack;  	// 传递给写回阶段的数据 
	wire ME_ADEL, ME_ADES;


	wire[4:0] WB_regPos3;
	wire[31:0] WB_AluResult, WB_MemReadData;
	// ===============================================================================
	// ==================================== F I ======================================
	// ===============================================================================
	
	// FI 阶段
	PC #(32) PcReg(clk, rst, ~FI_Stall, FI_FLush, FI_PCNext, ME_NewPC, FI_PC);  // PC 流水线寄存器
	PCAdd PcAdd_4(FI_PC, 32'b100, FI_PCadd4);  // PC + 4
	assign is_in_delayslotF = (DE_Jump | DE_Jal | DE_Jr | DE_Branch | DE_Bal);
	assign FI_except = (FI_PC[1:0] == 2'b00)? 8'b00000000 : 8'b01000000;
	
	// 记录当前指令是否是延迟槽(疑问--2条特权移动指令是否有延迟槽)

	// 要得到PC的跳转选择，也就是确定PC_next，那需要比较器，但是比较器
	// 输入要来自DE阶段的寄存器变量，PC没写完，先写de

	// ===============================================================================
	// ==================================== D E ======================================
	// ===============================================================================

	// DE 阶段
	assign DE_regPos1 = DE_Inst[25:21];
	assign DE_regPos2 = DE_Inst[20:16];
	assign DE_regPos3 = DE_Inst[15:11];
	assign DE_OP = DE_Inst[31:26];
	
	// 唯一在DE阶段的几个WB变量
	RegHeap regHP (
		clk, WB_RegWrite, /* 写使能暂时保留，WB阶段才能获得 */
		DE_regPos1, DE_regPos2, WB_WrtRegPos, /* 同理 */
		WB_Wrtdata,  /* 同理 */
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

	Comparer cmp( // 比较器
		DE_HazardRegRdData1, DE_HazardRegRdData2, 
    	DE_OP,
    	DE_regPos2,
    	DE_Cmp
	);

	assign DE_Imm = DE_Inst[15:0];
	
	Imm_Extend #(16, 32) ImmEx(  // 对立即数进行扩展 
		DE_Imm,
        DE_ImmExSg,
        DE_ImmExtend
	);
	ImmShift ImmShift2( // 立即数扩展后左移2位
		DE_ImmExtend,
		DE_ImmExShifted
	);

	assign InstrIndex = {DE_Inst[25:0], 2'b00}; // J型指令的 InstrIndex 并左移 2 位
	assign BJState = {DE_Branch, DE_Jump, DE_Jal, DE_Jr, DE_Bal};
	assign PCInstrIdxConcat = {DE_PC[31:28], InstrIndex};
	assign PCFromReg = DE_HazardRegRdData1; 

	PCAdd PcAddImm(DE_PCadd4, DE_ImmExShifted, PCAdd4_AddImmExShifted);  // PC + 4 + ImmExShifted
	// 所有的 reg[31 or xx] = PC + 8 统一放到EX阶段
	assign DE_PCBranchNext = ((BJState == `Branch_J		)||(BJState == `Branch_Jal		))? PCInstrIdxConcat:
							 ((BJState == `Branch_Jr	)||(BJState == `Branch_Jalr		))? PCFromReg:
							 ((BJState == `Branch_branch)||(BJState == `Branch_branchal	))? PCAdd4_AddImmExShifted:
							 DE_PCadd4;
	
	Mux_21 #(32) PC_Select (
	   DE_PcSelecter,
		FI_PCadd4, DE_PCBranchNext,
		FI_PCNext
	);

	// 因为 Bal与Jal要求写31号寄存器，而Jalr要求写rd寄存器，我在控制器中，Bal与Jal的
	// 写入寄存器号都默认是rd，因此只需要对rd进行修改即可
	assign DE_regPos3EqZero = DE_regPos3 == 5'b0 ? 1'b1 : 1'b0;
	Mux_21 #(5) Rd_Select (
		((DE_Jal & ~DE_Jr) | DE_Bal | (DE_Jal & DE_Jr & DE_regPos3EqZero)),
		DE_regPos3, 5'd31,	  // 31号寄存器
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
	// DE阶段的PC+4相对于EX阶段就是PC+8

	Mux_21 #(32) AluOp2Select(
		EX_AluSelecter,
		EX_RegFord, 
		EX_Imm,
		EX_ALUop2
	);


	// CP0 Read Data 前推
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
		EX_SA,  						// 移位指令提供的sa
		EX_HI_Read, EX_LO_Read,
		CP0_EX_ReadDataFD,  			// CP0_Data还不知道咋搞 (现在加入CP0模块)
		EX_AluY,
		EX_Overflow,
		EX_AluHI_Wrt, EX_AluLO_Wrt 		// ALU输出的HILO写数据
    );

	Mux_21 #(32) AluResultSelect(  		// 选择 是否保留 PC + 8
		(EX_Jal | EX_Bal),
		EX_AluY, 
		EX_PCAdd8,
		EX_AluResult
	);

	// 下面是根据 EX_WtRegSelecter 确定写寄存器号 EX_WrtRegPos
	Mux_21 #(5) WrtRegPosSelect(  		// 选择要写的寄存器号
		EX_WtRegSelecter,
		EX_regPos2,
		EX_regPos3,
		EX_WrtRegPos
	);

	// 乘除法部分

	assign MD_Stop = 1'b0;  			// 传统艺能，不知道的就设置默认值，以后留着改


	assign MulMode = (EX_AluCtrl == `EXE_MULT_OP) || (EX_AluCtrl == `EXE_MULTU_OP);
	assign DivMode = (EX_AluCtrl == `EXE_DIV_OP)  || (EX_AluCtrl == `EXE_DIVU_OP);
	assign MD_SignMode = ~((EX_AluCtrl == `EXE_MULTU_OP)||(EX_AluCtrl == `EXE_DIVU_OP));

	// 当为乘除运算模式时，且结果未准备就绪时阻塞流水线

	MUL mul__(  						// 乘法  MULT rs, rt
    	clk, rst,
    	MD_SignMode,

    	EX_ALUop1, EX_RegFord,
    	MulMode, MD_Stop,

    	MUL_Result,
    	MUL_Ready
    );
	DIV div__(  // 除法
    	clk, rst,
    	MD_SignMode,

    	EX_ALUop1, EX_RegFord,
    	DivMode, MD_Stop,

    	DIV_Result,
    	DIV_Ready
    );

	assign EX_MULDIV_Stall = ((MulMode | DivMode) & ~(MUL_Ready | DIV_Ready));

	// 确定HILO写入值
	assign {EX_DMHI_Wrt, EX_MDLO_Wrt} = (MulMode && ~DivMode) ? MUL_Result:
										(~MulMode && DivMode) ? DIV_Result:
										64'b0;

	// EX_HILO_Wrt 通过EX_HILOWrt信号判断是写入ALU的结果还是乘除法的结果
	assign EX_HI_Wrt = (EX_HILOWrt == 1'b1) ? EX_AluHI_Wrt : EX_DMHI_Wrt;
	assign EX_LO_Wrt = (EX_HILOWrt == 1'b1) ? EX_AluLO_Wrt : EX_MDLO_Wrt;

	// HILO 寄存器，写会有两部分，一个是ALU输出的写信号，另一个是乘除法的写信号
	// 表现为 (EX_HILOWrt | MUL_Ready | DIV_Ready)
	// 由于ALUCtrl的互斥性，这3个信号应该不会同时出现
	RegHILO HILO(
		clk, rst,
		(EX_HILOWrt | (MUL_Ready & MulMode) | (DIV_Ready & DivMode)),
		EX_HI_Wrt, EX_LO_Wrt,
		EX_HI_Read, EX_LO_Read
	);

	// ===============================================================================
	// ==================================== M E ======================================
	// ===============================================================================


	// 下面是提前判断W使能
	Mux_41 #(4) SB_WEN(		// 写字节使能
		ME_AluResult[1:0],
		4'b0001,  			// 地址以00结尾 
		4'b0010,			// 地址以01结尾 
		4'b0100,			// 地址以10结尾 
		4'b1000,			// 地址以11结尾 
		ME_SB_WEN
	);

	Mux_21 #(4) SH_WEN(
		ME_AluResult[1],
		4'b0011,  			// 地址以00结尾 
		4'b1100,			// 地址以10结尾 
		ME_SH_WEN
	);

	// 下面是判断 MEM地址是否非法
	assign ME_AddrInvalid = ((ME_AluResult[0] == 1'b1 && 
							(ME_MemSeg == 2'b01 || ME_MemSeg == 2'b10)) ||
							(ME_MemSeg == 2'b10 && ME_AluResult[1] == 1'b1));

	assign ME_AluOut = ME_AluResult; 				// MEM 的地址

	wire[7:0] ME_WrtByte;
	wire[15:0] ME_WrtHalfWord;
	assign ME_WrtByte = ME_MemWrtData[7:0];			// 从最低位开始取
	assign ME_WrtHalfWord = ME_MemWrtData[15:0];	// 从最低位开始取
	// MEM地址会自动4位对齐，并且要手动将存储的数据进行移位……透

	assign ME_MenWrtEnable = (ME_MemWrite == 1'b0 || ME_AddrInvalid) ? 4'b0000  :  // 非写模式或异常
							 (ME_MemSeg == 2'b00 ) ? ME_SB_WEN:  // 写字节
							 (ME_MemSeg == 2'b01 ) ? ME_SH_WEN:  // 写半字
							 (ME_MemSeg == 2'b10 ) ? 4'b1111  : 4'b0000;

	assign ME_WrtData = (ME_MenWrtEnable == 4'b1000) ? {ME_WrtByte, 24'b0} 			:
						(ME_MenWrtEnable == 4'b0100) ? {8'b0, ME_WrtByte, 16'b0} 	:
						(ME_MenWrtEnable == 4'b0010) ? {16'b0, ME_WrtByte, 8'b0} 	:
						(ME_MenWrtEnable == 4'b0001) ? {24'b0, ME_WrtByte} 			:
						(ME_MenWrtEnable == 4'b1100) ? {ME_WrtHalfWord, 16'b0} 		:
						(ME_MenWrtEnable == 4'b0011) ? {16'b0, ME_WrtHalfWord} 		:
						(ME_MenWrtEnable == 4'b1111) ? ME_MemWrtData 				:
						32'b0;

	// 还要记得把 ReadData 判断类型并扩充
	// 先根据 Addr 把对应的部分取出来
	Mux_41 #(8) ByteSelect(
		ME_AluResult[1:0],
		ME_ReadDate[7 : 0],  		// 地址以00结尾
		ME_ReadDate[15: 8],			// 地址以01结尾
		ME_ReadDate[23:16],			// 地址以10结尾
		ME_ReadDate[31:24],			// 地址以11结尾
		ReadByte
	);
	Mux_21 #(16) HfWdSelect(
		ME_AluResult[1],
		ME_ReadDate[15: 0],  		// 地址以00结尾 
		ME_ReadDate[31:16],			// 地址以10结尾 
		ReadHfWd
	);

	// 再将数据进行扩展，变成32位
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

	// 最后根据 ME_MemSeg 对数据进行选择
	Mux_41 #(32) DataWB_Select(
		ME_MemSeg,
		LB_Data,  				// 字节
		LH_Data,				// 半字
		ME_ReadDate,			// 全字
		ME_ReadDate,			// other
		ME_DataWrtBack
	);

	assign ME_ADEL = ME_Mem2Reg  && ME_AddrInvalid;  	// Load 地址异常判断，读内存
	assign ME_ADES = ME_MemWrite && ME_AddrInvalid;  	// Save 地址异常判断，写内存
	// 又TM写反了，Fuck！

	assign ME_BadAddr = (ME_except[6])		? ME_PC		:
					    (ME_ADEL | ME_ADES) ? ME_AluOut : 32'b0;

	// wire ME_ADEL, ME_ADES;
	// CP0  打算放在这里，但是先不实现，传统艺能留着先
	// 想了想还是放到写回了？因为异常处理不需要使能，所以异常处理在ME阶段接过去也没啥问题

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
		WB_Mem2Reg,			// 是否是MEM写到寄存器
		WB_AluResult,		// ALU的结果
		WB_MemReadData,		// Mem读的数据
		WB_Wrtdata			// 写回寄存器数据
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
	// ================================ 流水线寄存器 ==================================
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
	// ================================== 冒险模块 ====================================
	// ===============================================================================
	
	// 总结：
	/*
	|| 1. 于99~100行处，两个寄存器的取值需要考虑数据前推
	|| 2. 于153行处， PC的另两个跳转没写，估计需要异常处理参与
	|| 3. 于185行处，ALU的两个运算数可能需要数据前推
	*/
	
	hazard h(
	    FI_Stall, FI_FLush,
        DE_Stall, DE_Flush,             // 
        EX_Stall, EX_Flush,             // 
        ME_Stall, ME_Flush,             // 
        WB_Stall, WB_Flush,             // 流水线控制信号
        Except_Flush,

        DE_Forward_1, DE_Forward_2,     // 
        EX_Forward_1, EX_Forward_2,  	// 数据前推选择信号
        CP0_Forward,                	// CP0数据前推选择信号

        FI_ReqStall, ME_ReqStall,

        DE_regPos1, DE_regPos2,     	// 
        EX_regPos1, EX_regPos2,     	// 两个寄存器读位置
        EX_regPos3, ME_regPos3, WB_regPos3,
        EX_WrtRegPos,               	//
        ME_WrtRegPos,               	//
        WB_WrtRegPos,               	// 三个寄存器写位置

        EX_RegWrite ,                   // EX 寄存器写使能
        EX_Mem2Reg  ,                   // EX 内存写寄存器
        ME_RegWrite ,                   // ME 寄存器写使能
        ME_Mem2Reg  ,                   // ME 内存写寄存器
        WB_RegWrite ,                   // WB 寄存器写使能
        
		EX_MULDIV_Stall,				// 乘除法
		DE_Branch, DE_Jr,
		EX_CP0Read, ME_CP0Wen, WB_CP0Wen,
		ME_ExceptType
    );

	// ===============================================================================
	// =============================== 异常状态寄存器 =================================
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

	// 关于CP0也可能存在数据冒险，需要数据前推，但是貌似可以看作普通的寄存器取值冒险，可以用
	// 同一套方法处理
endmodule
