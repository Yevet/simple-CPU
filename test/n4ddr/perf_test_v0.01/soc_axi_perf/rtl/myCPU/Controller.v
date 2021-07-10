`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 22:30:02
// Design Name: 
// Module Name: Controller
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


//|  Controller 用于解码出指令对应的控制信号
//|  然后输出控制信号，控制信号将会传递给数据
//|  通路中的各模块

module Controller(
		input wire clk, rst,
		
		// DE 阶段
		input wire[31:0] DE_Inst, // DE阶段的输入
		input wire DE_Cmp, // DE阶段比较器结果
		input wire DE_Stall, DE_Flush, // 是否暂停流水线
    	output wire DE_PcSelecter, DE_ImmExSg, // PC选择子, 立即数符号扩展
    	output wire DE_Branch, DE_Jump,
    	output wire DE_Jal, DE_Jr, DE_Bal,
    	output wire DE_Invalid, DE_syscall, DE_break, DE_eret,

    	// EX 阶段
    	input wire EX_Flush, EX_Stall,
        output wire EX_Jal, EX_Bal,
    	output wire EX_AluSelecter,
    	output wire EX_RegWrite, EX_Mem2Reg, 
    	output wire EX_WtRegSelecter, // 写寄存器号选择子
    	output wire EX_HILOWrt, EX_CP0Read, 
    	output wire[7:0] EX_AluCtrl,
    	
    	// ME 阶段 
        input ME_Stall, ME_Flush,
    	output wire ME_Mem2Reg, ME_MemWrite, ME_MemEn, 
		output wire[1:0] ME_MemSeg,
    	output wire ME_ExSign, ME_RegWrite, ME_CP0Wen, 
        // 精确异常，CP0放到访存结束后处理
    	
    	// WB 阶段
        input wire WB_Stall, WB_Flush,
    	output wire WB_Mem2Reg, WB_RegWrite
    );

    wire Mem2RegD, MemEnD, MemWriteD, 
         MemExSignD, AluSelecterD, WtRegSelecterD,
         RegWriteD, HILOWrtD, Wrt_CP0D, Read_CP0D;
    wire [1:0] MemSegD;

    MainDecoder MD (
        DE_Inst, 
        Mem2RegD,
        MemEnD,
        MemWriteD,
        MemExSignD,
        MemSegD,
        DE_Branch,
        AluSelecterD,
        DE_ImmExSg,
        WtRegSelecterD,
        RegWriteD,
        HILOWrtD,
        DE_Jump,
        DE_Jal,
        DE_Jr,
        DE_Bal,
        Wrt_CP0D,
		Read_CP0D,
        DE_Invalid,
		DE_syscall, 
		DE_break, 
		DE_eret
    );


    wire [5:0] opD, functD;
    wire [4:0] CP0D;
    assign opD = DE_Inst[31:26];
    assign functD = DE_Inst[5:0];
    assign CP0D = DE_Inst[25:21];
    wire [7:0] ALUCtrlD;

    ALU_Decoder ALuDE(
        opD,
        functD,
        CP0D,  // inst[25:21] 用于判断是否为 CP0 相关指令
        ALUCtrlD
    );

    assign DE_PcSelecter = (DE_Jump | DE_Jal | DE_Jr) | (DE_Branch & DE_Cmp); // cmpD 为比较器返回结果
    

    //  EX
    wire MemEnE, MemWriteE, 
         MemExSignE, Wrt_CP0E;
    wire [1:0] MemSegE;
    PipeReg #(14) PipeEX (
        clk, rst, ~EX_Stall, EX_Flush,
        {DE_Jal, DE_Bal, Mem2RegD, MemEnD, MemWriteD, MemSegD, MemExSignD, AluSelecterD, WtRegSelecterD, RegWriteD, HILOWrtD, Wrt_CP0D, Read_CP0D},
        {EX_Jal, EX_Bal, EX_Mem2Reg, MemEnE, MemWriteE, MemSegE, MemExSignE, EX_AluSelecter, EX_WtRegSelecter, EX_RegWrite, EX_HILOWrt, Wrt_CP0E, EX_CP0Read}
    );

    PipeReg #(8) PipeEX_ALU (
        clk, rst, ~EX_Stall, EX_Flush,
        ALUCtrlD,
        EX_AluCtrl
    );


    // ME
    wire Mem2RegM, RegWriteM;
    PipeReg #(8) PipeME (
        clk, rst, ~ME_Stall, ME_Flush,
        {EX_Mem2Reg, MemEnE, MemWriteE, MemSegE, MemExSignE, EX_RegWrite, Wrt_CP0E},
        {Mem2RegM, ME_MemEn, ME_MemWrite, ME_MemSeg, ME_ExSign, RegWriteM, ME_CP0Wen}
    );
    assign ME_Mem2Reg = Mem2RegM;
    assign ME_RegWrite = RegWriteM;

    // WB

    PipeReg #(2) PipeWB (
        clk, rst, 1'b1, WB_Flush,
        {Mem2RegM, RegWriteM},
        {WB_Mem2Reg, WB_RegWrite}
    );


endmodule
