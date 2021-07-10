`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/03 20:46:46
// Design Name: 
// Module Name: mips
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


module mycpu_top(
    input wire clk,
    input wire resetn,
    input wire[5:0] int,                    // 中断

    output wire inst_sram_en,               // 1
    output wire[3 :0] inst_sram_wen,        // 1？
    output wire[31:0] inst_sram_addr,       // FI_PC
    output wire[31:0] inst_sram_wdata,      // 默认为0
    input  wire[31:0] inst_sram_rdata,      // FI_Instr

    output wire data_sram_en,               // ME_MenEn
    output wire[3 :0] data_sram_wen,        // 4 位写使能
    output wire[31:0] data_sram_addr,       // ME_AluOut
    output wire[31:0] data_sram_wdata,      // ME_WrtData
    input  wire[31:0] data_sram_rdata,      // ME_ReadDate

    //debug
    output wire[31:0] debug_wb_pc,                // WB 阶段的PC
    output wire[3 :0] debug_wb_rf_wen,      // WB 寄存器写使能
    output wire[4 :0] debug_wb_rf_wnum,     // WB 写寄存器号
    output wire[31:0] debug_wb_rf_wdata    // WB 写寄存器数据
    );
    assign inst_sram_en = 1;
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'b0;
    wire rst, clk_t;
    assign rst = ~resetn; // 顶层要求 low active
    assign clk_t = ~clk; // 顶层要求 low active

    wire[39:0] DEBUG_Instr_ascii;
    InstAsciiDecoder IAD(inst_sram_rdata, DEBUG_Instr_ascii); // DEBUG使用

    wire[31:0] DE_Inst; // 来自DataPath
    wire DE_Cmp;        // 来自DataPath

    // 流水线控制，来自DataPath
    wire DE_Stall, DE_Flush, EX_Stall, EX_Flush, ME_Stall, ME_Flush, WB_Stall, WB_Flush;

    // DE阶段相关
    wire DE_PcSelecter, DE_ImmExSg, DE_Branch, DE_Jump,
         DE_Jal, DE_Jr, DE_Bal, DE_Invalid, DE_syscall, DE_break, DE_eret;

    // EX阶段相关
    wire EX_Jal, EX_Bal, EX_AluSelecter, EX_RegWrite,
		 EX_Mem2Reg, EX_WtRegSelecter, EX_HILOWrt, EX_CP0Read;
    wire [7:0] EX_AluCtrl;

    // ME阶段相关
    wire ME_Mem2Reg, ME_MemWrite, ME_ExSign, 
         ME_RegWrite, ME_CP0Wen;
    wire[1:0] ME_MemSeg;

    // WB阶段相关
    wire WB_Mem2Reg, WB_RegWrite;
    wire Except_Flush;
    wire [31:0] WB_PC, WB_WrtData;
    wire [4 :0] WB_WrtRegPos;
    
    wire[31:0] ME_AluOut;
    assign data_sram_addr = (ME_AluOut[31:16] != 16'hbfaf) ? ME_AluOut : {16'h1faf, ME_AluOut[15:0]};
    
    assign debug_wb_rf_wen = {4{WB_RegWrite}};

    Controller ctrl(
        clk_t, rst,

        // DE 阶段
		DE_Inst, // DE阶段的输入
		DE_Cmp, // DE阶段比较器结果，以及是否暂停
		DE_Stall, DE_Flush, 
    	DE_PcSelecter, DE_ImmExSg, // PC选择子, 立即数符号扩展
    	DE_Branch, DE_Jump,
    	DE_Jal, DE_Jr, DE_Bal,
    	DE_Invalid, DE_syscall, DE_break, DE_eret,

    	// EX 阶段
    	EX_Flush, EX_Stall,
		EX_Jal, EX_Bal, 
    	EX_AluSelecter,
		EX_RegWrite, EX_Mem2Reg, 
    	EX_WtRegSelecter, // 写寄存器号选择子
    	EX_HILOWrt, EX_CP0Read,
    	EX_AluCtrl,
    	
    	// ME 阶段
        ME_Stall, ME_Flush,
    	ME_Mem2Reg, ME_MemWrite, data_sram_en, ME_MemSeg,
    	ME_ExSign, ME_RegWrite, ME_CP0Wen, 
        // 精确异常，CP0放到访存结束后处理
    	
    	// WB 阶段
        WB_Stall, WB_Flush,
    	WB_Mem2Reg, WB_RegWrite
    );

    DataPath DP(
	    clk_t, rst,

	    // FI stage
	    inst_sram_addr,
	    inst_sram_rdata,

	    //DE stage
	    DE_PcSelecter, DE_ImmExSg,
	    DE_Branch, DE_Jump,
	    DE_Jal, DE_Jr, DE_Bal,
	    DE_Invalid, DE_syscall, DE_break, DE_eret,
        DE_Inst,      // DE阶段指令送给CTRLers
	    DE_Cmp, DE_Stall, DE_Flush,  // 比较器结果

	    //EX stage
		EX_Jal, EX_Bal, 
	    EX_AluSelecter,
		EX_RegWrite, EX_Mem2Reg, 
	    EX_WtRegSelecter,
	    EX_HILOWrt, EX_CP0Read,
	    EX_AluCtrl,
	    EX_Flush, EX_Stall,

	    //ME stage
	    ME_Mem2Reg, ME_MemWrite, 
	    ME_MemSeg,
        ME_ExSign, ME_RegWrite, ME_CP0Wen, 
		data_sram_wen, 
	    ME_AluOut, data_sram_wdata, // ALU结果 和 写数据
	    data_sram_rdata,   // 读入的数据
        ME_Stall, ME_Flush,      // 流水线控制

	    //WB stage
	    WB_Mem2Reg, WB_RegWrite,
        WB_Stall, WB_Flush, Except_Flush,
        
        // FI ME Stall Request
        0, 0,
        
        debug_wb_rf_wnum, 
        debug_wb_pc,
        debug_wb_rf_wdata
    );
endmodule
