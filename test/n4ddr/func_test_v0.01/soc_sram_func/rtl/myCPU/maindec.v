`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/02 20:24:35
// Design Name: 
// Module Name: maindec
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

module maindec(
    input  [5:0] op,
    input  [5:0] funct,
    input  [4:0] rs,
    input [4:0] rt,
    input [4:0] rd,
    output memtoreg,
    output [3:0]memwrite,
    output memen,
    output branch,alusrc,
    output regdst, regwrite,
    output jump,jal,jr,jalr,bal,
    output aluhilo,
    output [1:0]hilowrite,
    output mtc0,mfc0,
    output brk,call,
    output reg invalid
);
    reg [21:0] controls;
    assign {regwrite, regdst, alusrc, branch, memen, memtoreg, jump, jal, jr, jalr, bal, memwrite, aluhilo, hilowrite, mtc0, mfc0, brk, call} = controls;

    always@(*) begin
        invalid=0;
         if( (rs == 0) && (rt == 0) && (rd == 0) && (op == 0) &&(funct == 0)) begin
            controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0; 
        end else begin
                case(op) 
            // extra
                6'b111111: controls <= 22'b1_1_0_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
            // LOGIC
                `EXE_ANDI: controls<= 22'b1_0_1_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_XORI: controls<= 22'b1_0_1_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_LUI:  controls<= 22'b1_0_1_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_ORI:  controls<= 22'b1_0_1_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
            // algorithm
                `EXE_ADDI:  controls<= 22'b1_0_1_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_ADDIU: controls<= 22'b1_0_1_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_SLTI:  controls<= 22'b1_0_1_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_SLTIU: controls<= 22'b1_0_1_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
            // branch jump  
                `EXE_BEQ: controls<= 22'b0_0_0_1_0_0_0_0_0_0_0_0000_0_00_0_0_0_0; 
                `EXE_BGTZ:controls<= 22'b0_0_0_1_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_BLEZ:controls<= 22'b0_0_0_1_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_BNE: controls<= 22'b0_0_0_1_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_J:   controls<= 22'b0_0_0_0_0_0_1_0_0_0_0_0000_0_00_0_0_0_0; 
                `EXE_JAL: controls<= 22'b1_0_0_0_0_0_0_1_0_0_0_0000_0_00_0_0_0_0; 
            //memory access
                `EXE_LB:  controls<= 22'b1_0_1_0_1_1_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_LBU: controls<= 22'b1_0_1_0_1_1_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_LH:  controls<= 22'b1_0_1_0_1_1_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_LHU: controls<= 22'b1_0_1_0_1_1_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_LW:  controls<= 22'b1_0_1_0_1_1_0_0_0_0_0_0000_0_00_0_0_0_0;
                `EXE_SB:  controls<= 22'b0_0_1_0_1_0_0_0_0_0_0_0001_0_00_0_0_0_0;
                `EXE_SH:  controls<= 22'b0_0_1_0_1_0_0_0_0_0_0_0011_0_00_0_0_0_0;
                `EXE_SW:  controls<= 22'b0_0_1_0_1_0_0_0_0_0_0_1111_0_00_0_0_0_0;
            // special
                `EXE_SPECIAL_INST:case(funct)
                    //logic(no need)
                    //move bit(no need)
                    //data remove
                    `EXE_MFHI:controls<= 22'b1_1_0_0_0_0_0_0_0_0_0_0000_1_00_0_0_0_0;
                    `EXE_MFLO:controls<= 22'b1_1_0_0_0_0_0_0_0_0_0_0000_1_00_0_0_0_0;
                    `EXE_MTHI:controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_10_0_0_0_0;
                    `EXE_MTLO:controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_01_0_0_0_0;
                    //algorithm 
                    `EXE_MULT: controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_11_0_0_0_0;
                    `EXE_MULTU:controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_11_0_0_0_0;
                    `EXE_DIV:  controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_11_0_0_0_0;
                    `EXE_DIVU: controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_11_0_0_0_0;     
                    //branch and jump
                    `EXE_JR:  controls<= 22'b0_0_0_0_0_0_1_0_1_0_0_0000_0_00_0_0_0_0; 
                    `EXE_JALR:controls<= 22'b1_1_0_0_0_0_0_0_0_1_0_0000_0_00_0_0_0_0; 
                    // trap
                    `EXE_BREAK:  controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_00_0_0_1_0; 
                    `EXE_SYSCALL:controls<= 22'b0_0_0_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_1; 
                    `EXE_AND,`EXE_OR,`EXE_XOR,`EXE_NOR,`EXE_SLL,`EXE_SRL,`EXE_SRA,`EXE_SLLV,`EXE_SRLV,`EXE_SRAV,
                    `EXE_ADD,`EXE_SUB,`EXE_SLT,`EXE_ADDU,`EXE_SUBU,`EXE_SLTU:
                         controls<= 22'b1_1_0_0_0_0_0_0_0_0_0_0000_0_00_0_0_0_0; //R type
                    default:invalid=1;
                  endcase
                `EXE_REGIMM_INST:case(rt)
                    `EXE_BLTZ:  controls<= 22'b0_0_0_1_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                    `EXE_BLTZAL:controls<= 22'b1_0_0_1_0_0_0_0_0_0_1_0000_0_00_0_0_0_0;
                    `EXE_BGEZ:  controls<= 22'b0_0_0_1_0_0_0_0_0_0_0_0000_0_00_0_0_0_0;
                    `EXE_BGEZAL:controls<= 22'b1_0_0_1_0_0_0_0_0_0_1_0000_0_00_0_0_0_0;
                    default:invalid=1;
                  endcase
                6'b010000:case(rs)
                    5'b00100:controls<= 22'b0_1_0_0_0_0_0_0_0_0_0_0000_0_00_1_0_0_0;            //mtc0
                    5'b00000:controls<= 22'b1_0_0_0_0_0_0_0_0_0_0_0000_0_00_0_1_0_0;            //mfc0
                    default:invalid=1;
                    endcase
                default: invalid=1; //??? 
            endcase
        end
     end 
endmodule