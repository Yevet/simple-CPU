`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
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


module mips(
	input wire clk,rst,
	input wire [5:0] int,
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire [3:0]memwriteM,
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM,
	output wire memen,
	output wire[7:0] alucontrolM,
	input wire ADEL,ADES,
	input wire [31:0] badadr,
	output wire [31:0] pcW,
	output wire regwriteW,
	output wire [4:0] writeregW,
	output wire [31:0] result2W
    );
	
	wire [5:0] opD,functD;
	wire [4:0] rtD,rdD;
	wire [4:0] rsD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM;
	wire [7:0] alucontrolE;
	wire flushE,equalD;
	wire jumpD,jrD,jalD,jalrD;
	wire jalE,jalrE,balE;
	wire [1:0]hilowriteW,hilowriteM;
	wire aluhiloE;
	wire balD;
	wire brkD,callD;
	wire invalidD;
	wire mfc0E,mfc0M,mfc0W,mtc0W,mtc0M;
	wire stallE;
	wire branchD;
	wire flushM;
	wire flushW;

	controller c(
		clk,rst,
		//decode stage
		opD,functD,rsD,rtD,rdD,
		pcsrcD,branchD,
		equalD,jumpD,jrD,jalD,balD,jalrD,
		brkD,callD,
		invalidD,
		//execute stage
		flushE,stallE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	
		alucontrolE,aluhiloE,
		jalE,jalrE,
        balE,mfc0E,

		//mem stage
		memtoregM,memwriteM,
		regwriteM,
		memen,alucontrolM,
		flushM,
		hilowriteM,
		mtc0M,mfc0M,
		//write back stage
		memtoregW,regwriteW,
		hilowriteW,
		mfc0W,mtc0W,
		flushW
		);
	datapath dp(
		clk,rst,int,
		//fetch stage
		pcF,
		instrF,
		//decode stage
		pcsrcD,branchD,
		jumpD,jrD,balD,jalD,jalrD,
		equalD,
		opD,functD,
		rsD,rtD,rdD,
		brkD,callD,
		invalidD,
		//execute stage
		memtoregE,
		alusrcE,regdstE,
		regwriteE,
		alucontrolE,
		aluhiloE,
		flushE,
		jalE,jalrE,
        balE,
        stallE,
        mfc0E,
		//mem stage
		memtoregM,
		regwriteM,
		aluoutM,writedataM,
		readdataM,
		ADEL,ADES,
		badadr,
		flushM,
		hilowriteM,
		mtc0M,mfc0M,
		//writeback stage
		memtoregW,
		regwriteW,
		hilowriteW,
		mfc0W,mtc0W,
		pcW,
		writeregW,
		result2W,
		flushW
	    );
	
endmodule
