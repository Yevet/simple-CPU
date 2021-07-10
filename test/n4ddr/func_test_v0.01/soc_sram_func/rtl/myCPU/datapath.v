`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 15:12:22
// Design Name: 
// Module Name: datapath
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
module datapath(
	input wire clk,rst,
	input wire [5:0] int,
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	//decode stage
	input wire pcsrcD,branchD,
	input wire jumpD,jrD,balD,jalD,jalrD,
	output wire equalD,
	output wire[5:0] opD,functD,
	output wire [4:0] rsD,
	output wire [4:0] rtD,
	output 	wire [4:0] rdD,
	input wire brkD,callD,
	input wire invalidD,
	//execute stage
	input wire memtoregE,
	input wire alusrcE,regdstE,
	input wire regwriteE,
	input wire[7:0] alucontrolE,
	input wire aluhiloE,
	output wire flushE,
	input wire jalE,jalrE,
    input wire balE,
    output wire stallE,
    input wire mfc0E,
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM,
	input wire ADEL,ADES,
	input wire [31:0] badadr,
	output wire flushM,
	input wire [1:0]hilowriteM,
	input wire mtc0M,mfc0M,
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	input wire [1:0]hilowriteW,
	input wire mfc0W,mtc0W,
	output wire [31:0] pcW,
	output wire [4:0] writeregW,
	output wire [31:0] result2W,
	output wire flushW
    );
	
	//fetch stage
	wire stallF,flushF;
	wire pcexceptF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcnext2FD,pcplus4F,pcbranchD;
	//decode stage
	wire [31:0] pcplus4D,instrD;
	wire [31:0] pcplus8D;
	wire [1:0] forwardaD,forwardbD;
	wire flushD,stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire [31:0] srca2D_1,srcb2D_1;
	wire [63:0] hilo_oD;
	wire eretD;
	wire pcexceptD;
	wire [1:0] forwardcpaD,forwardcpbD;
	//execute stage
	wire [1:0] forwardaE,forwardbE;
	wire [1:0]forwardhiloE;
	wire [4:0] rsE,rtE,rdE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] srca2E_1,srca2E_2,srca2E_3,srcb3E_1;
	wire [31:0] aluoutE,aluout2E;
	wire [31:0] pcplus8E;
	wire [63:0] hilo_iE,hilo_oE;
	wire eretE,invalidE,brkE,callE;
	wire overflowE;
	wire pcexceptE;
	wire [4:0] writereg2E,writereg3E;
	wire [63:0] mul_oE,div_oE;
	wire [63:0] hilosrcE;
	wire [1:0] forwardcp0;
	wire [1:0] forwardcpaE,forwardcpbE;
	//mem stage
	wire [4:0] writeregM;
	wire [63:0] hilo_iM;
	wire eretM,invalidM,brkM,callM;
    wire overflowM;
    wire pcexceptM;
	//writeback stage
	
	wire [31:0] aluoutW,readdataW,resultW;
	wire [1:0] typeD;
	wire [4:0] saD,saE;
	wire [63:0] hilo_iW;
	wire div_ready,div_stall,div_start,div_signed;
	
	
	//cp0
	wire [31:0] excepttype_i_M,excepttype_i_W;
	wire is_in_delayslot_i_F,is_in_delayslot_i_D,is_in_delayslot_i_E,is_in_delayslot_i_M,is_in_delayslot_i_W;
    wire [31:0]cp0_status;
    wire [31:0]cp0_cause;
    wire [31:0]epc;
	wire [31:0] data_oE,data_o2E,data_oM,data_oW;
	wire [31:0] srcb3M,srcb3W;
	wire [31:0] finpc;
	wire [31:0] pcD,pcE,pcM;
	wire [31:0] badadrW;
	wire pcexceptW,ADELW;
	wire [31:0] finalbadadr;

	//hazard detection
	hazard h(
		//fetch stage
		stallF,flushF,
		//decode stage
		rsD,rtD,
		opD,
		branchD,jrD,jalrD,
		forwardaD,forwardbD,
		stallD,
		balD,equalD,
		flushD,
		forwardcpaD,forwardcpbD,
		//execute stage
		alucontrolE,
		div_stall,
		rsE,rtE,rdE,
		writeregE,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,
		flushE,stallE,
		forwardhiloE,
		forwardcp0,
		mfc0E,
		forwardcpaE,forwardcpbE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		excepttype_i_M,
		hilowriteM,
		flushM,
		mtc0M,mfc0M,
		//write back stage
		writeregW,
		regwriteW,
		mtc0W,mfc0W,
		hilowriteW,
		flushW,
		excepttype_i_W
		);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD || jalD ,pcnextFD);
	mux2 #(32) jrmux(pcnextFD,srca2D,jrD || jalrD,pcnext2FD);
	exceptpc finalpc(excepttype_i_W,epc,pcnext2FD,finpc);
 
	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,result2W,srcaD,srcbD);
    hilo_reg hilo(clk,rst,hilowriteW,hilo_iW[63:32],hilo_iW[31:0],hilo_oD[63:32],hilo_oD[31:0]);

	//fetch stage logic
	pc pcreg(clk,rst,~stallF,finpc,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);
	assign pcexceptF= (pcF[1:0] == 2'b00) ? 0:1;
	assign is_in_delayslot_i_F = branchD || jalD || jumpD || jrD|| jalrD;
	
	//decode stage
	flopenr #(32) r1D(clk,rst,~stallD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(1) r3D(clk,rst,~stallD,flushD,pcexceptF,pcexceptD);
	flopenrc #(32) r4D(clk,rst,~stallD,flushD,pcF,pcD);
	flopenrc #(1) r5D(clk,rst,~stallD,flushD,is_in_delayslot_i_F,is_in_delayslot_i_D);
	signext se(instrD[15:0],typeD,signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcplus8(pcplus4D,32'b100,pcplus8D);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	
	mux4 forwardamux(srcaD,aluoutE,aluoutM,readdataM,forwardaD,srca2D_1);
	mux4 forwardbmux(srcbD,aluoutE,aluoutM,readdataM,forwardbD,srcb2D_1);
	mux3 #(32) forwardcpaDmux(srca2D_1,data_o2E,data_oM,forwardcpaD,srca2D);
	mux3 #(32) forwardcpbDmux(srcb2D_1,data_o2E,data_oM,forwardcpbD,srcb2D);
	
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign typeD = instrD[29:28];
	assign saD = instrD[10:6];
	assign eretD = (instrD==32'b01000010000000000000000000011000)? 1:0 ;

	//execute stage
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(5) r7E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(64) r8E(clk,rst,~stallE,flushE,hilo_oD,hilo_oE);
	flopenrc #(32) r9E(clk,rst,~stallE,flushE,pcplus8D,pcplus8E);
	flopenrc #(1) r10E(clk,rst,~stallE,flushE,eretD,eretE);
	flopenrc #(1) r11E(clk,rst,~stallE,flushE,brkD,brkE);
	flopenrc #(1) r12E(clk,rst,~stallE,flushE,callD,callE);
	flopenrc #(1) r13E(clk,rst,~stallE,flushE,invalidD,invalidE);
	flopenrc #(1) r14E(clk,rst,~stallE,flushE,pcexceptD,pcexceptE);
	flopenrc #(32) r16E(clk,rst,~stallE,flushE,pcD,pcE);
	flopenrc #(1) r17E(clk,rst,~stallE,flushE,is_in_delayslot_i_D,is_in_delayslot_i_E);
	
    mux3 #(32) forwardcp(data_oE,srcb3W,srcb3M,forwardcp0,data_o2E);
	mux3 #(32) forwardaemux(srcaE,result2W,aluoutM,forwardaE,srca2E_1);
	mux3 #(64) forwardhilo(hilo_oE,hilo_iM,hilo_iW,forwardhiloE,hilosrcE);
	mux2 #(32) hilosrc1(srca2E_1,hilosrcE[63:32],(alucontrolE==`EXE_MFHI_OP),srca2E_2);
	mux2 #(32) hilosrc2(srca2E_2,hilosrcE[31:0],(alucontrolE==`EXE_MFLO_OP),srca2E_3);
	mux3 #(32) forwardbemux(srcbE,result2W,aluoutM,forwardbE,srcb2E);
	
	mux3 #(32) forwardcpaEmux(srca2E_3,data_oM,data_oW,forwardcpaE,srca2E);
	mux3 #(32) forwardcpbEmux(srcb2E,data_oM,data_oW,forwardcpbE,srcb3E_1);
	
	mux2 #(32) srcbmux(srcb3E_1,signimmE,alusrcE,srcb3E);
	
	
	alu alu(srca2E,srcb3E,alucontrolE,saE,aluoutE,mul_oE,overflowE);
	div_state divstate(alucontrolE,div_ready,div_stall,div_start,div_signed);
	div d(clk,rst,div_signed,srca2E,srcb3E,div_start,1'b0,div_oE,div_ready);
	
	mux2 #(64) hilomux(mul_oE,div_oE,(alucontrolE==`EXE_DIV_OP || alucontrolE==`EXE_DIVU_OP),hilo_iE);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);
	mux2 #(5) regmux(writeregE,5'b11111, jalE || balE ,writereg2E);
	mux2 #(5) jalrmux(writereg2E,5'b11111, jalrE && (!rdD) ,writereg3E);
	mux2 #(32) alumux(aluoutE,pcplus8E, jalE || balE || jalrE, aluout2E);
	

	//mem stage
	floprc #(32) r1M(clk,rst,flushM,srcb2E,writedataM);
	floprc #(32) r2M(clk,rst,flushM,aluout2E,aluoutM);
	floprc #(5) r3M(clk,rst,flushM,writereg3E,writeregM);
	floprc #(64) r4M(clk,rst,flushM,hilo_iE,hilo_iM);
	floprc #(1) r5M(clk,rst,flushM,eretE,eretM);
    floprc #(1) r6M(clk,rst,flushM,brkE,brkM);
    floprc #(1) r7M(clk,rst,flushM,callE,callM);
    floprc #(1) r8M(clk,rst,flushM,invalidE,invalidM);
    floprc #(1) r9M(clk,rst,flushM,pcexceptE,pcexceptM);
    floprc #(1) r10M(clk,rst,flushM,overflowE,overflowM);
    floprc #(32) r11M(clk,rst,flushM,pcE,pcM);
    floprc #(1) r12M(clk,rst,flushM,is_in_delayslot_i_E,is_in_delayslot_i_M);
    floprc #(32) r13M(clk,rst,flushM,data_o2E,data_oM);
    floprc #(32) r14M(clk,rst,flushM,srcb3E,srcb3M);
    
    exception exp(rst,pcexceptM,eretM,brkM,callM,invalidM,overflowM,ADEL,ADES,cp0_status,cp0_cause,excepttype_i_M);

	//writeback stage
	floprc #(32) r1W(clk,rst,flushW,aluoutM,aluoutW);
	floprc #(32) r2W(clk,rst,flushW,readdataM,readdataW);
	floprc #(5) r3W(clk,rst,flushW,writeregM,writeregW);
	floprc #(64) r4W(clk,rst,flushW,hilo_iM,hilo_iW);
    floprc #(32) r5W(clk,rst,flushW,data_oM,data_oW);
    floprc #(32) r6W(clk,rst,flushW,srcb3M,srcb3W);
    floprc #(32) r7W(clk,rst,flushW,pcM,pcW);
    floprc #(32) r8W(clk,rst,flushW,excepttype_i_M,excepttype_i_W);
    floprc #(1) r9W(clk,rst,flushW,is_in_delayslot_i_M,is_in_delayslot_i_W);
    floprc #(32) r10W(clk,rst,flushW,badadr,badadrW);
    floprc #(1) r11W(clk,rst,flushW,pcexceptM,pcexceptW);
    floprc #(1) r12W(clk,rst,flushW,ADEL,ADELW);
    
    assign finalbadadr = ( pcexceptW == 1'b1 ) ? pcW :
                         ( ADELW == 1'b1) ? badadrW : badadrW;
    
    cp0_reg cp0(.clk(clk),.rst(rst),.raddr_i(rdE),
    .we_i(mtc0W),.waddr_i(writeregW),.data_i(srcb3W),
    .int_i(int),
    .excepttype_i(excepttype_i_W),.current_inst_addr_i(pcW),
    .is_in_delayslot_i(is_in_delayslot_i_W),.bad_addr_i(finalbadadr),.status_o(cp0_status),.cause_o(cp0_cause),.epc_o(epc),
    .data_o(data_oE));

	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
	mux2 #(32) resmux2(resultW,data_oW,mfc0W,result2W);

	
endmodule
