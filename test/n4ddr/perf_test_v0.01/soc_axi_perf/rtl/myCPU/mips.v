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
    input wire[5:0] int,                    // �ж�

    output wire inst_sram_en,               // 1
    output wire[3 :0] inst_sram_wen,        // 1��
    output wire[31:0] inst_sram_addr,       // FI_PC
    output wire[31:0] inst_sram_wdata,      // Ĭ��Ϊ0
    input  wire[31:0] inst_sram_rdata,      // FI_Instr

    output wire data_sram_en,               // ME_MenEn
    output wire[3 :0] data_sram_wen,        // 4 λдʹ��
    output wire[31:0] data_sram_addr,       // ME_AluOut
    output wire[31:0] data_sram_wdata,      // ME_WrtData
    input  wire[31:0] data_sram_rdata,      // ME_ReadDate

    //debug
    output wire[31:0] debug_wb_pc,                // WB �׶ε�PC
    output wire[3 :0] debug_wb_rf_wen,      // WB �Ĵ���дʹ��
    output wire[4 :0] debug_wb_rf_wnum,     // WB д�Ĵ�����
    output wire[31:0] debug_wb_rf_wdata    // WB д�Ĵ�������
    );
    assign inst_sram_en = 1;
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'b0;
    wire rst, clk_t;
    assign rst = ~resetn; // ����Ҫ�� low active
    assign clk_t = ~clk; // ����Ҫ�� low active

    wire[39:0] DEBUG_Instr_ascii;
    InstAsciiDecoder IAD(inst_sram_rdata, DEBUG_Instr_ascii); // DEBUGʹ��

    wire[31:0] DE_Inst; // ����DataPath
    wire DE_Cmp;        // ����DataPath

    // ��ˮ�߿��ƣ�����DataPath
    wire DE_Stall, DE_Flush, EX_Stall, EX_Flush, ME_Stall, ME_Flush, WB_Stall, WB_Flush;

    // DE�׶����
    wire DE_PcSelecter, DE_ImmExSg, DE_Branch, DE_Jump,
         DE_Jal, DE_Jr, DE_Bal, DE_Invalid, DE_syscall, DE_break, DE_eret;

    // EX�׶����
    wire EX_Jal, EX_Bal, EX_AluSelecter, EX_RegWrite,
		 EX_Mem2Reg, EX_WtRegSelecter, EX_HILOWrt, EX_CP0Read;
    wire [7:0] EX_AluCtrl;

    // ME�׶����
    wire ME_Mem2Reg, ME_MemWrite, ME_ExSign, 
         ME_RegWrite, ME_CP0Wen;
    wire[1:0] ME_MemSeg;

    // WB�׶����
    wire WB_Mem2Reg, WB_RegWrite;
    wire Except_Flush;
    wire [31:0] WB_PC, WB_WrtData;
    wire [4 :0] WB_WrtRegPos;
    
    wire[31:0] ME_AluOut;
    assign data_sram_addr = (ME_AluOut[31:16] != 16'hbfaf) ? ME_AluOut : {16'h1faf, ME_AluOut[15:0]};
    
    assign debug_wb_rf_wen = {4{WB_RegWrite}};

    Controller ctrl(
        clk_t, rst,

        // DE �׶�
		DE_Inst, // DE�׶ε�����
		DE_Cmp, // DE�׶αȽ���������Լ��Ƿ���ͣ
		DE_Stall, DE_Flush, 
    	DE_PcSelecter, DE_ImmExSg, // PCѡ����, ������������չ
    	DE_Branch, DE_Jump,
    	DE_Jal, DE_Jr, DE_Bal,
    	DE_Invalid, DE_syscall, DE_break, DE_eret,

    	// EX �׶�
    	EX_Flush, EX_Stall,
		EX_Jal, EX_Bal, 
    	EX_AluSelecter,
		EX_RegWrite, EX_Mem2Reg, 
    	EX_WtRegSelecter, // д�Ĵ�����ѡ����
    	EX_HILOWrt, EX_CP0Read,
    	EX_AluCtrl,
    	
    	// ME �׶�
        ME_Stall, ME_Flush,
    	ME_Mem2Reg, ME_MemWrite, data_sram_en, ME_MemSeg,
    	ME_ExSign, ME_RegWrite, ME_CP0Wen, 
        // ��ȷ�쳣��CP0�ŵ��ô��������
    	
    	// WB �׶�
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
        DE_Inst,      // DE�׶�ָ���͸�CTRLers
	    DE_Cmp, DE_Stall, DE_Flush,  // �Ƚ������

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
	    ME_AluOut, data_sram_wdata, // ALU��� �� д����
	    data_sram_rdata,   // ���������
        ME_Stall, ME_Flush,      // ��ˮ�߿���

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
