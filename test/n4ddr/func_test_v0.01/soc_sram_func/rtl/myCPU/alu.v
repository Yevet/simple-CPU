`timescale 1ns / 1ps
`include "defines.vh"
module alu(
    input  [31:0]srca,
    input  [31:0]srcb,
    input  [7:0]alucontrol,
    input  [4:0]sa,
    
    output wire [31:0]aluout,
    output wire[63:0]hilo_temp,
    output reg overflow
    );
    reg [32:0] result;
    wire [31:0] mult_a,mult_b,subt_b;
    reg [31:0] temp;

    assign mult_a = ((alucontrol==`EXE_MULT_OP)&&(srca[31] == 1'b1)) ? (~srca + 1) : srca;
    assign mult_b = ((alucontrol==`EXE_MULT_OP)&&(srcb[31] == 1'b1)) ? (~srcb + 1) : srcb;
    assign hilo_temp = ((alucontrol==`EXE_MULT_OP) && (srca[31] ^ srcb[31] == 1'b1)) ? ~(mult_a*mult_b)+1 :
                       ((alucontrol==`EXE_MULT_OP) && (srca[31] ^ srcb[31] == 1'b0)) ? mult_a*mult_b :
                       (alucontrol==`EXE_MULTU_OP) ? mult_a*mult_b : 
                       (alucontrol==`EXE_MTHI)? {srca,`ZeroWord}:
                       (alucontrol==`EXE_MTLO)? {`ZeroWord,srca}:{`ZeroWord,`ZeroWord};
    assign subt_b = ((alucontrol==`EXE_SUB_OP) || ((alucontrol==`EXE_SUBU_OP))) ? (~srcb + 1) : srcb;
    
    always@(*)
    begin 
        overflow=0;
        case(alucontrol)
                 //extra
                 8'b11111111: begin
                    if(srca[31] == 1'b0 )
                        result[31:0] = srca;
                    else if(srca[31] == 1'b1)
                        result[31:0] = 32'h00000000;
                 end
                 //logic calculus instr
                 `EXE_AND_OP:begin//,
                  result = srca & srcb;
                  end
                 `EXE_OR_OP:begin//,
                  result =  srca | srcb;
                  end
                 `EXE_XOR_OP: begin//,
                  result = srca ^ srcb;
                  end
                 `EXE_NOR_OP : begin//,
                  result = ~(srca|srcb); 
                  end               
 
                 `EXE_ANDI_OP: begin//,
                 result = srca & srcb; 
                 end  
                 `EXE_XORI_OP: begin//,
                 result = srca ^ srcb;
                 end
                   
                 `EXE_LUI_OP:begin//,,
                 result = {srcb[15:0],16'b0}; 
                 end                            
                 `EXE_ORI_OP: begin//,
                 result = srca | srcb;
                 end                
                 //shift inst
                 `EXE_SLL_OP: begin
                  result = srcb << sa;//,
                  end
                 `EXE_SLLV_OP : begin
                  result = srcb << srca[4:0];
                  end 
                 `EXE_SRL_OP: begin//,
                 result = srcb >> sa ;
                  end
                 `EXE_SRLV_OP: begin
                 result = srcb >> srca[4:0];
                 end
                 `EXE_SRA_OP:begin//,
                 result = ({32{srcb[31]}} << (6'd32-{1'b0,sa})) | srcb >> sa;
                 end
                 `EXE_SRAV_OP :begin
                  result = ({32{srcb[31]}} << (6'd32-{1'b0,srca[4:0]})) | srcb >> srca[4:0]; 
                  end 
                 //move data inst
                 
                 `EXE_MFHI_OP: result[31:0] = srca;
                 `EXE_MFLO_OP: result[31:0] = srca;
                   
                 //arithmetic calculus instr   
                 `EXE_ADD_OP: begin
                 result =  srca+srcb;
                 if((srca[31]^srcb[31]==0)&&(srca[31]!=result[31]))
                     begin
                     overflow = 1;
                     end
                 end
                 `EXE_ADDU_OP : begin
                 result =  srca+srcb;
                 end
                 `EXE_SUB_OP: begin
                 result =  srca + subt_b;
                 if((srca[31]^subt_b[31]==0)&&(srca[31]!=result[31]))
                     begin
                     overflow = 1;
                     end                                                                                                                                                 
                 end
                 `EXE_SUBU_OP : begin
                 result = srca + subt_b;
                 end
                 //`EXE_DIV  : alucontrol <=  `EXE_ANDI_OP;
                 //`EXE_DIVU : alucontrol <=  `EXE_ANDI_OP;           
                `EXE_SLT_OP: begin
                    if(srca[31]^srcb[31]==1'b1)begin
                        if(srca[31]==1'b0)
                            result<=33'h00000000;
                        else if(srca[31]==1'b1)
                            result<=33'h00000001;
                    end
                    else if((srca[31]==1'b1) && (srcb[31]==1'b1)) begin
                        temp= srca - srcb;
                        if(temp[31]==1'b1)
                            result<=33'h00000001;
                        else if(temp[31]==1'b0)
                            result<=33'h00000000;
                    end
                    else if((srca[31]==1'b0) && (srcb[31]==1'b0)) begin
                        temp= srca - srcb;
                        if(temp[31]==1'b1)
                           result<=33'h00000001;
                        else if(temp[31]==1'b0)
                           result<=33'h00000000;
                    end
                end
                 `EXE_SLTU_OP: begin
                 result =  srca < srcb ? 1:0; 
                 end 
                 `EXE_ADDI_OP : begin
                 result = srca + srcb;  
                 if((srca[31]^srcb[31]==0)&&(srca[31]!=result[31]))
                     begin
                     overflow = 1;
                     end
                 end               
                 `EXE_ADDIU_OP : 
                 result = srca + srcb;                 
                `EXE_SLTI_OP:begin
                    if(srca[31]^srcb[31]==1'b1)begin
                       if(srca[31]==1'b0)
                            result<=33'h00000000;
                        else if(srca[31]==1'b1)
                            result<=33'h00000001;
                    end
                    else if((srca[31]==1'b1) && (srcb[31]==1'b1)) begin
                        temp= srca - srcb;
                        if(temp[31]==1'b1)
                              result<=33'h00000001;
                        else if(temp[31]==1'b0)
                              result<=33'h00000000;
                    end
                    else if((srca[31]==1'b0) && (srcb[31]==1'b0)) begin
                         temp= srca - srcb;
                         if(temp[31]==1'b1)
                              result<=33'h00000001;
                         else if(temp[31]==1'b0)
                              result<=33'h00000000;
                    end                    
                end
                 `EXE_SLTIU_OP : begin
                 result = srca < srcb ? 1 : 0;
                 end
                //load and store
                 `EXE_LB_OP: begin
                 result =  srca + srcb;
                 end 
                 `EXE_LBU_OP:begin
                 result =  srca + srcb;
                 end 
                 
                 `EXE_LH_OP: begin
                 result =  srca + srcb;
                 end                  
                 `EXE_LHU_OP: begin
                 result =  srca + srcb;
                 end                  
                 `EXE_LW_OP:begin
                 result =  srca + srcb;
                 end                  
                 `EXE_SB_OP:begin
                 result =  srca + srcb;
                 end                  
                 `EXE_SH_OP:begin
                 result =  srca + srcb;
                 end                 
                 `EXE_SW_OP:begin
                 result =  srca + srcb;
                 end                   
         endcase

     

end

    assign aluout = result[31:0];
    
endmodule