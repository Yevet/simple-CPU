`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	//decode stage
	input wire[5:0] opD,functD,
	input wire [4:0] rsD,
	input wire [4:0] rtD,
	input wire [4:0] rdD,
	output wire pcsrcD,branchD,
	input wire equalD,
	output wire jumpD,jrD,jalD,balD,jalrD,
	output wire brkD,callD,
	output wire invalidD,
	
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[7:0] alucontrolE,
	output wire aluhiloE,
	output wire jalE,jalrE,
    output wire balE,mfc0E,

	//mem stage
	output wire memtoregM,
	output wire [3:0]memwriteM,			
	output wire regwriteM,
	output wire memenM,
	output wire[7:0] alucontrolM,
	input wire flushM,
	output wire [1:0]hilowriteM,
	output wire mtc0M,mfc0M,

	//write back stage
	output wire memtoregW,regwriteW,
	output wire [1:0]hilowriteW,
	output wire mfc0W,mtc0W,
	input wire flushW	
    );
	
	//decode stage
	wire memtoregD;
	wire [3:0] memwriteD;
	wire alusrcD,regdstD,regwriteD;
	wire[7:0] alucontrolD;
	wire [1:0]hilowriteD;
	wire aluhiloD;
	wire mfc0D,mtc0D;
	wire memenD;
	

	//execute stage
	wire [3:0]memwriteE;
	wire [1:0]hilowriteE;
	wire mtc0E;
	wire memenE;
	//m
	wire memenM_t;
	//w
	wire memtoregW_t,regwriteW_t;
	wire [1:0] hilowriteW_t;
	wire mtc0W_t,mfc0W_t;
	
    
	maindec md(
		opD,functD,rsD,rtD,rdD,
		memtoregD,memwriteD,
		memenD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,jalD,jrD,jalrD,balD,
		aluhiloD,hilowriteD,
        mtc0D,mfc0D,
        brkD,callD,
        invalidD
		);
	aludec ad(opD,functD,rsD,rtD,alucontrolD);

    assign memenM = (flushM == 1'b1) ? 0 : memenM_t;
	assign pcsrcD = branchD & equalD;
	assign memtoregW = (flushW == 1'b1) ? 0 : memtoregW_t;
	assign regwriteW = (flushW == 1'b1) ? 0 : regwriteW_t;
	assign hilowriteW = (flushW == 1'b1) ? 2'b00 : hilowriteW_t;
	assign mtc0W = (flushW == 1'b1) ? 0 : mtc0W_t;
	assign mfc0W = (flushW == 1'b1) ? 0 : mfc0W_t;
	

	//pipeline registers
	flopenrc #(32) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,memenD,alusrcD,regdstD,regwriteD,alucontrolD,hilowriteD,aluhiloD,jalD,jalrD,balD,mtc0D,mfc0D},
		{memtoregE,memwriteE,memenE,alusrcE,regdstE,regwriteE,alucontrolE,hilowriteE,aluhiloE,jalE,jalrE,balE,mtc0E,mfc0E}
		);
	floprc #(32) regM(
		clk,rst,
		flushM,
		{memtoregE,memwriteE,memenE,regwriteE,hilowriteE,alucontrolE,mtc0E,mfc0E},
		{memtoregM,memwriteM,memenM_t,regwriteM,hilowriteM,alucontrolM,mtc0M,mfc0M}
		);
	floprc #(16) regW(
		clk,rst,
		flushW,
		{memtoregM,regwriteM,hilowriteM,mtc0M,mfc0M},
		{memtoregW_t,regwriteW_t,hilowriteW_t,mtc0W_t,mfc0W_t}
		);
endmodule