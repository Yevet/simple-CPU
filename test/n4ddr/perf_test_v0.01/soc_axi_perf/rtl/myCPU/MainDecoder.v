`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 22:48:11
// Design Name: 
// Module Name: MainDecoder
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
module MainDecoder(
		input wire [31:0] instr,
		
		output wire Mem2Reg, MemEn, MemWrite, MemExSign,
        output wire[1:0] MemSeg,
		output wire Branch, AluSelecter, ImmExSg, 
		output wire WtRegSelecter, RegWrite, 
        output wire HILOWrt, // 不用分别表示高低使能，因为高位低位分别作为reg存储在ALU
		output wire Jump, Jal, Jr, Bal, Wrt_CP0, Read_CP0,
		output wire Invalid, syscall, break, eret
    );
	reg[21:0] Ctrls;
    
	
	always @(*) begin
	    case(instr[31:26])  // OP
	        `EXE_NOP: begin  // R-Type
	            case(instr[5:0])
	                // 逻辑指令
	                `EXE_AND, 
                    `EXE_OR, 
                    `EXE_XOR, 
                    `EXE_NOR,

	                // 算数运算
	                `EXE_ADD ,
	                `EXE_ADDU,
	                `EXE_SUB ,
	                `EXE_SUBU,
	               
                    // 移位指令
	                `EXE_SLL ,
	                `EXE_SRL ,
	                `EXE_SRA ,
	                `EXE_SLLV,
	                `EXE_SRLV,
	                `EXE_SRAV: Ctrls <= 22'b_000_0000_00_11_00000_00_0000;
	               

	                // move指令
	                `EXE_MFHI,
	                `EXE_MFLO: Ctrls <= 22'b_000_0000_00_11_00000_00_0000;

	                `EXE_MTHI,
	                `EXE_MTLO: Ctrls <= 22'b_001_0000_00_00_00000_00_0000;
	               

	                `EXE_SLT ,
	                `EXE_SLTU: Ctrls <= 22'b_000_0000_00_11_00000_00_0000;
	               

	                `EXE_MULT ,
	                `EXE_MULTU,
	                `EXE_DIV  ,
	                `EXE_DIVU : Ctrls <= 22'b_000_0000_00_00_00000_00_0000;
	                // 假定乘除法对HILO的写会自提供使能信号
	               

	                // 跳转指令
	                `EXE_JR  : Ctrls <= 22'b_000_0000_00_00_01010_00_0000;
	                `EXE_JALR: Ctrls <= 22'b_000_0000_00_11_00110_00_0000;
	               
                    // 中断暂不处理
	                `EXE_SYSCALL: Ctrls <= 22'b_000_0000_00_00_00000_00_0100;
	                `EXE_BREAK	: Ctrls <= 22'b_000_0000_00_00_00000_00_0010;
	                default		: Ctrls <= 22'b_000_0000_00_00_00000_00_1000;
	            endcase
	        end
            // 逻辑立即数运算
	        `EXE_ANDI,
	        `EXE_XORI,
	        `EXE_ORI ,
	        `EXE_LUI : Ctrls <= 22'b_100_0000_00_01_00000_00_0000;
           
            // ADD立即数操作
	        `EXE_ADDI ,
	        `EXE_ADDIU: Ctrls <= 22'b_110_0000_00_01_00000_00_0000;

	        `EXE_SLTI ,
	        `EXE_SLTIU: Ctrls <= 22'b_110_0000_00_01_00000_00_0000;
	       
	        `EXE_J  : Ctrls <= 22'b_000_0000_00_00_01000_00_0000;
	        `EXE_JAL: Ctrls <= 22'b_000_0000_00_11_00100_00_0000;
            // 可能出现冒险
	       
	        `EXE_BGTZ, 
	        `EXE_BLEZ, 
	        `EXE_BEQ , 
	        `EXE_BNE : Ctrls <= 22'b_010_0000_00_00_10000_00_0000;
	       
	        `EXE_LB : Ctrls <= 22'b_110_1101_00_01_00000_00_0000;
	        `EXE_LBU: Ctrls <= 22'b_110_1100_00_01_00000_00_0000;
	        `EXE_LH : Ctrls <= 22'b_110_1101_01_01_00000_00_0000;
	        `EXE_LHU: Ctrls <= 22'b_110_1100_01_01_00000_00_0000;
	        `EXE_LW : Ctrls <= 22'b_110_1100_10_01_00000_00_0000;
	        `EXE_SB : Ctrls <= 22'b_110_0110_00_00_00000_00_0000;
	        `EXE_SH : Ctrls <= 22'b_110_0110_01_00_00000_00_0000;
	        `EXE_SW : Ctrls <= 22'b_110_0110_10_00_00000_00_0000;
            6'b000001: begin 
                case (instr[20:16])
                    `EXE_BGEZ  ,
                    `EXE_BLTZ  : Ctrls <= 22'b_010_0000_00_00_10000_00_0000;

                    `EXE_BGEZAL,
                    `EXE_BLTZAL: Ctrls <= 22'b_010_0000_00_11_10001_00_0000;
                    default: Ctrls     <= 22'b_000_0000_00_00_00000_00_1000;
                endcase
            end
            6'b010000: begin 
                if(instr==`EXE_ERET) begin
                    Ctrls <= 22'b_000_0000_00_00_00000_10_0001;
                end else begin 
                    case (instr[25:21])
                        5'b00100: Ctrls <= 22'b_000_0000_00_00_00000_01_0000;
                        5'b00000: Ctrls <= 22'b_000_0000_00_01_00000_10_0000; // 忘记给写寄存器信号
                        default: Ctrls  <= 22'b_000_0000_00_00_00000_00_1000;
                    endcase
                end
            end
            default: Ctrls <= 21'b_000_0000_00_00_00000_0_1000;
	    endcase
	end
	
    assign {
                AluSelecter,            // ALU 第二运算数选择器
                ImmExSg,                // 立即数符号扩展控制信号
                HILOWrt,                // HILO寄存器写控制信号

                Mem2Reg,                // 存储器到(通用)寄存器控制信号, 用于在WB阶段控制
                MemEn,                  // 存储器使能信号
                MemWrite,               // 存储器写信号
                MemExSign,              // 访存符号扩展

                MemSeg,                 // 访存类型 {字节, 半字, 字}

                WtRegSelecter,          // 写回(通用)寄存器选择器，用于选择rt或rd为写回目标
                RegWrite,               // (通用)寄存器写回信号

                Branch,                 // 普通跳转指令
                Jump,                   // 无条件跳转信号
                Jal,                    // ...
                Jr,                     // ...
                Bal,                    // ...

				Read_CP0,
                Wrt_CP0,                // 是否写CP0

                Invalid,
				syscall,
				break,
				eret
            } = Ctrls;
endmodule
