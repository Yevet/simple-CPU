`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 21:13:56
// Design Name: 
// Module Name: ALU_Decoder
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

module ALU_Decoder(
        input wire[5:0] op,
        input wire[5:0] funct,
        input wire[4:0] CP0,  // inst[25:21] 用于判断是否为 CP0 相关指令
        output reg[7:0] ALUop
    );
    
    always @(*) begin
        case(op)
            `EXE_NOP: begin  // R-Type
                case(funct)
                    // 逻辑指令
                    `EXE_AND: ALUop <= `EXE_AND_OP; // T
	                `EXE_OR : ALUop <= `EXE_OR_OP ; // T
	                `EXE_XOR: ALUop <= `EXE_XOR_OP; // T
	                `EXE_NOR: ALUop <= `EXE_NOR_OP; // T

                    // 移位指令
	                `EXE_SLL : ALUop <= `EXE_SLL_OP;  // T
	                `EXE_SRL : ALUop <= `EXE_SRL_OP;  // T
	                `EXE_SRA : ALUop <= `EXE_SRA_OP;  // T
	                `EXE_SLLV: ALUop <= `EXE_SLLV_OP; // T
	                `EXE_SRLV: ALUop <= `EXE_SRLV_OP; // T
	                `EXE_SRAV: ALUop <= `EXE_SRAV_OP; // T
                    
                    // move指令
	                `EXE_MFHI: ALUop <= `EXE_MFHI_OP; // T
	                `EXE_MTHI: ALUop <= `EXE_MTHI_OP; // T
	                `EXE_MFLO: ALUop <= `EXE_MFLO_OP; // T
	                `EXE_MTLO: ALUop <= `EXE_MTLO_OP; // T
                    
                    // 算数运算
	                `EXE_ADD : ALUop <= `EXE_ADD_OP ; // T
	                `EXE_ADDU: ALUop <= `EXE_ADDU_OP; // T
	                `EXE_SUB : ALUop <= `EXE_SUB_OP ; // T
	                `EXE_SUBU: ALUop <= `EXE_SUBU_OP; // T
	                `EXE_SLT : ALUop <= `EXE_SLT_OP ; // T
	                `EXE_SLTU: ALUop <= `EXE_SLTU_OP; // T
	                
	                `EXE_MULT : ALUop <= `EXE_MULT_OP ;
	                `EXE_MULTU: ALUop <= `EXE_MULTU_OP;
	                `EXE_DIV  : ALUop <= `EXE_DIV_OP  ;
	                `EXE_DIVU : ALUop <= `EXE_DIVU_OP ;

                    default: ALUop <= `EXE_NOP_OP;
                endcase
            end
            `EXE_ANDI: ALUop <= `EXE_AND_OP; // T
            `EXE_XORI: ALUop <= `EXE_XOR_OP; // T
            `EXE_LUI : ALUop <= `EXE_LUI_OP; // T
            `EXE_ORI : ALUop <= `EXE_OR_OP ; // T

            `EXE_ADDI : ALUop <= `EXE_ADD_OP ; // T
            `EXE_ADDIU: ALUop <= `EXE_ADDU_OP; // T
            `EXE_SLTI : ALUop <= `EXE_SLT_OP ; // T
            `EXE_SLTIU: ALUop <= `EXE_SLTU_OP; // T

            `EXE_LB : ALUop <= `EXE_ADD_OP; // T
            `EXE_LBU: ALUop <= `EXE_ADD_OP; // T
            `EXE_LH : ALUop <= `EXE_ADD_OP; // T
            `EXE_LHU: ALUop <= `EXE_ADD_OP; // T
            `EXE_LW : ALUop <= `EXE_ADD_OP; // T
            `EXE_SB : ALUop <= `EXE_ADD_OP; // T
            `EXE_SH : ALUop <= `EXE_ADD_OP; // T
            `EXE_SW : ALUop <= `EXE_ADD_OP; // T

            6'b010000: begin 
                case(CP0)
                    5'b00100: ALUop <= `EXE_MTC0_OP; // To
                    5'b00000: ALUop <= `EXE_MFC0_OP; // From
                    default: ALUop <= `EXE_NOP_OP;
                endcase
            end

            default: ALUop <= `EXE_NOP_OP;
        endcase
    end
endmodule
