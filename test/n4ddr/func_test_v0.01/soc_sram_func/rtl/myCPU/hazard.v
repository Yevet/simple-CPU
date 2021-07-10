`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/02 21:53:09
// Design Name: 
// Module Name: hazard
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

`include"defines.vh"

module hazard(  
    //fetch stage
		output reg stallF,
		output reg flushF,
		//decode stage
		input [4:0]rsD,[4:0]rtD,
		input [5:0] opD,
		input branchD,jrD,jalrD,
		output reg [1:0] forwardaD,forwardbD,
		output reg stallD,
		input balD,equalD,
		output reg flushD,
		output reg [1:0] forwardcpaD,forwardcpbD,
		//execute stage
		input [7:0]alucontrolE,
		input div_stall,
		input [4:0]rsE,[4:0]rtE,[4:0]rdE,
		input [4:0]writeregE,
		input regwriteE,
		input memtoregE,
		output reg [1:0]forwardaE,
		output reg [1:0]forwardbE,
		output reg flushE,
		output reg stallE,
		output reg [1:0]forwardhiloE,
		output reg [1:0] forwardcp0,
		input mfc0E,
		output reg [1:0] forwardcpaE,forwardcpbE,
		//mem stage
		input [4:0]writeregM,
		input regwriteM,
		input memtoregM,
		input [31:0]excepttypeM,
		input [1:0]hilowriteM,
		output reg flushM,
		input mtc0M,mfc0M,
		//write back stage
		input [4:0]writeregW,
		input regwriteW,
		input mtc0W,mfc0W,
		input [1:0] hilowriteW,
		output reg flushW,
		input [31:0]excepttypeW	
    );
    reg lwstall;
    reg branchstall,jstall;
    reg flush_except;
    reg flush_except2;
    
    //data hazard
    always@(*) begin
        flush_except=(excepttypeW == 32'h00000000) ? 0:1;
        flush_except2 = (excepttypeM == 32'h00000000) ? 0:1;
        if((rsE!=0)&&(rsE == writeregM)&&(regwriteM)) begin
            forwardaE <= 2'b10;
            if( mfc0M ) begin
               forwardcpaE <= 2'b01;  //取cp0的M阶段值
            end else begin
               forwardcpaE <= 2'b00;
            end
        end else if ((rsE != 0) && (rsE == writeregW) && regwriteW ) begin
            forwardaE <= 2'b01;
            if( mfc0W ) begin
               forwardcpaE <= 2'b10;  //取cp0的W阶段值
            end else begin
               forwardcpaE <= 2'b00;
            end
        end else begin          
            forwardaE <= 2'b00;
            forwardcpaE <= 2'b00;
        end
            
        if((rtE!=0)&&(rtE == writeregM)&&(regwriteM) ) begin
            forwardbE <= 2'b10;
            if( mfc0M ) begin
               forwardcpbE <= 2'b01;  //取cp0的M阶段值
            end else begin
               forwardcpbE <= 2'b00;
            end
        end else if ((rtE != 0) && (rtE == writeregW) && regwriteW ) begin
            forwardbE <= 2'b01;
            if( mfc0W ) begin
               forwardcpbE <= 2'b10;  //取cp0的W阶段值
            end else begin
               forwardcpbE <= 2'b00;
            end
        end else begin          
            forwardbE <= 2'b00;
            forwardcpbE <= 2'b00;
        end        
    

        if(alucontrolE == `EXE_MFHI_OP) begin
            if(hilowriteM == 2'b11 || hilowriteM == 2'b10) begin
                forwardhiloE <= 2'b01;
            end else if(hilowriteW == 2'b11 || hilowriteW == 2'b10 ) begin
                forwardhiloE <= 2'b10;
            end else 
                forwardhiloE <= 2'b00; 
        end else if(alucontrolE == `EXE_MFLO_OP) begin
            if(hilowriteM == 2'b11 || hilowriteM == 2'b01) begin
                forwardhiloE <= 2'b01;
            end else if(hilowriteW == 2'b11 || hilowriteW == 2'b10 ) begin
                forwardhiloE <= 2'b10;
            end else 
                forwardhiloE <= 2'b00; 
        end else
            forwardhiloE <= 2'b00; 
               
        if((rdE!=0) && (rdE == writeregW) && (mtc0W == 1'b1)) begin
            forwardcp0 <= 2'b01;       
        end else if((rdE!=0) && (rdE == writeregM) && (mtc0M == 1'b1)) begin
            forwardcp0 <= 2'b10;
        end else
            forwardcp0 <= 2'b00;
          
     
       /* 
        if( mfc0E ) begin
            if( branchD && !balD  ) begin
                if( (rsD == writeregE) && regwriteE && (rsD != 0) )begin
                
                end
            end else if( branchD && balD ) begin
            
            end else begin
                
            end
        end else if( mfc0M ) begin
             if( branchD && !balD  ) begin
            
            end else if( branchD && balD ) begin
            
            end else begin
                if( (rsE == writeregM) && regwriteM && (rsE != 0)) begin
                
                end else if( (rtE == writeregM) && regwriteM && (rtE != 0)) begin
                
                end
            end
        end else begin
            
        end   */
            
        
        /*branchstall = branchD && regwriteE && 
                      (writeregE == rsD || (writeregE == rtD && opD != `EXE_REGIMM_INST)) ||
                       branchD && memtoregM && 
                       (writeregM == rsD || (writeregM == rtD && opD != `EXE_REGIMM_INST) ); */
                       
       if( (branchD && !balD) || jrD || jalrD ) begin
            if( (rsD != 0) && regwriteE && (writeregE == rsD)) begin   
                   forwardaD <= 2'b01;      //取aluoutE
                   if( mfc0E ) begin
                      forwardcpaD <= 2'b01;  //取cp0的E阶段值
                   end else begin
                      forwardcpaD <= 2'b00;
                   end
            end else if( (rsD != 0) && regwriteM && !memtoregM && (writeregM == rsD) ) begin 
                   forwardaD <= 2'b10;      // 取aluoutM
                   if( mfc0M ) begin
                      forwardcpaD <= 2'b10;  //取cp0的M阶段值
                   end else begin
                      forwardcpaD <= 2'b00;
                   end
            end else if( (rsD != 0) && memtoregM && (writeregM == rsD) ) begin   
                   forwardaD <= 2'b11;      //取resultM    
            end else begin
                   forwardaD <= 2'b00;
                   forwardcpaD <= 2'b00;
            end 
                    
            if( (rtD != 0) && regwriteE && (writeregE == rtD)) begin  
                   forwardbD <= 2'b01;              //取aluoutE
                   if( mfc0E ) begin
                      forwardcpbD <= 2'b01;  //取cp0的E阶段值
                   end else begin
                      forwardcpbD <= 2'b00;
                   end
            end else if( (rtD != 0) && regwriteM  && !memtoregM && (writeregM == rtD) ) begin 
                   forwardbD <= 2'b10;              // 取aluoutM
                   if( mfc0M ) begin
                      forwardcpbD <= 2'b10;  //取cp0的m阶段值
                   end else begin
                      forwardcpbD <= 2'b00;
                   end
                end else if( (rtD != 0) && memtoregM && (writeregM == rtD)) begin  
                   forwardbD <= 2'b11;              //取resultM
                end else begin
                   forwardbD <= 2'b00;
                   forwardcpbD <= 2'b00;
                end   
            end 
        else if(branchD && balD) begin
               if( (rsD != 0) && regwriteE && (writeregE == rsD)) begin
                    forwardaD <= 2'b01;
                     if( mfc0E ) begin
                      forwardcpaD <= 2'b01;  //取cp0的E阶段值
                   end else begin
                      forwardcpaD <= 2'b00;
                   end
               end else if( (rsD != 0) && regwriteM && !memtoregM  && (writeregM == rsD) ) begin
                    forwardaD <= 2'b10;
                     if( mfc0M ) begin
                      forwardcpaD <= 2'b10;  //取cp0的M阶段值
                   end else begin
                      forwardcpaD <= 2'b00;
                   end
               end else if( (rsD != 0) && memtoregM && (writeregM == rsD)) begin
                    forwardaD <= 2'b11;
               end else begin
                    forwardaD <= 2'b00;
               end
            end else begin
                forwardaD <= 2'b00;
                forwardbD <= 2'b00;
                forwardcpaD <= 2'b00;
                forwardcpbD <= 2'b00;
            end                 
                                                               
          
                       
        /*jstall = ( jrD && (rsD == writeregE) && regwriteE) ||
                 ( jalrD && (rsD == writeregE) && regwriteE) ||
                 ( jrD && memtoregM && (writeregM == rsD )) ||
                 ( jalrD && memtoregM && (writeregM == rsD ));*/
        lwstall = ((rsD==rtE) || (rtD==rtE && !balD)) && memtoregE;
        flushF = flush_except || flush_except2;
        flushD = flush_except || flush_except2 ;
        flushE = lwstall || flush_except || flush_except2 ;
        flushM = flush_except || flush_except2; 
        flushW = flush_except;
       
        
        stallF = (lwstall || div_stall) && !flushF; //|| jstall || branchstall;
        stallD = lwstall || div_stall; //|| jstall || branchstall;
        stallE = div_stall;
       
       
    end
endmodule
