`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 13:50:53
// Design Name: 
// Module Name: top
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
	input clk,
	input resetn,
	input[5:0]  int, 
	//cpu inst sram
    output wire        inst_sram_en,
    output wire [3 :0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input wire [31:0] inst_sram_rdata,
    //cpu data sram
    output wire        data_sram_en,
    output wire [3 :0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input wire [31:0] data_sram_rdata,
    //debug
    output wire [31:0] debug_wb_pc,
    output wire [3 :0] debug_wb_rf_wen,
    output wire [4 :0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
    
    );

	wire[31:0] pc,instr,readdata,dataadr,writedata,finalwrite,aluoutM;
	wire memen;
	wire [7:0]alucontrolM;
	wire ADEL,ADES;
	wire [31:0] badadr;
	wire [3:0] memwriteM,memwrite;
	wire [4:0] writeregW;
	wire [31:0] pcW;
	wire [31:0] result2W;
	wire regwriteW;
	
	assign inst_sram_en = 1'b1;
	assign inst_sram_wen = 4'b0000;
	assign inst_sram_addr = pc;
	assign inst_sram_wdata = 32'h00000000;
	assign instr = inst_sram_rdata;
	
	assign data_sram_en = memen;
	assign data_sram_wen = memwrite;
	assign data_sram_addr = (aluoutM[31:16] != 16'hbfaf) ? aluoutM : {16'h1faf,aluoutM[15:0]};
	assign data_sram_wdata = finalwrite;
	
	assign debug_wb_pc = pcW;
	assign debug_wb_rf_wen = {4{regwriteW}};
	assign debug_wb_rf_wnum = writeregW;
	assign debug_wb_rf_wdata = result2W;
	
   
	mips mips(~clk,~resetn,int,pc,instr,memwriteM,aluoutM,writedata,readdata,memen,alucontrolM,ADEL,ADES,badadr,pcW,regwriteW,writeregW,result2W);
	memsel dmem(data_sram_rdata,memwriteM,aluoutM,writedata,readdata,alucontrolM,ADEL,ADES,badadr,finalwrite,memwrite);
	
	
	
endmodule
