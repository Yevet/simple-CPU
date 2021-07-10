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
        output wire HILOWrt, // ���÷ֱ��ʾ�ߵ�ʹ�ܣ���Ϊ��λ��λ�ֱ���Ϊreg�洢��ALU
		output wire Jump, Jal, Jr, Bal, Wrt_CP0, Read_CP0,
		output wire Invalid, syscall, break, eret
    );
	reg[21:0] Ctrls;
    
	
	always @(*) begin
	    case(instr[31:26])  // OP
	        `EXE_NOP: begin  // R-Type
	            case(instr[5:0])
	                // �߼�ָ��
	                `EXE_AND, 
                    `EXE_OR, 
                    `EXE_XOR, 
                    `EXE_NOR,

	                // ��������
	                `EXE_ADD ,
	                `EXE_ADDU,
	                `EXE_SUB ,
	                `EXE_SUBU,
	               
                    // ��λָ��
	                `EXE_SLL ,
	                `EXE_SRL ,
	                `EXE_SRA ,
	                `EXE_SLLV,
	                `EXE_SRLV,
	                `EXE_SRAV: Ctrls <= 22'b_000_0000_00_11_00000_00_0000;
	               

	                // moveָ��
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
	                // �ٶ��˳�����HILO��д�����ṩʹ���ź�
	               

	                // ��תָ��
	                `EXE_JR  : Ctrls <= 22'b_000_0000_00_00_01010_00_0000;
	                `EXE_JALR: Ctrls <= 22'b_000_0000_00_11_00110_00_0000;
	               
                    // �ж��ݲ�����
	                `EXE_SYSCALL: Ctrls <= 22'b_000_0000_00_00_00000_00_0100;
	                `EXE_BREAK	: Ctrls <= 22'b_000_0000_00_00_00000_00_0010;
	                default		: Ctrls <= 22'b_000_0000_00_00_00000_00_1000;
	            endcase
	        end
            // �߼�����������
	        `EXE_ANDI,
	        `EXE_XORI,
	        `EXE_ORI ,
	        `EXE_LUI : Ctrls <= 22'b_100_0000_00_01_00000_00_0000;
           
            // ADD����������
	        `EXE_ADDI ,
	        `EXE_ADDIU: Ctrls <= 22'b_110_0000_00_01_00000_00_0000;

	        `EXE_SLTI ,
	        `EXE_SLTIU: Ctrls <= 22'b_110_0000_00_01_00000_00_0000;
	       
	        `EXE_J  : Ctrls <= 22'b_000_0000_00_00_01000_00_0000;
	        `EXE_JAL: Ctrls <= 22'b_000_0000_00_11_00100_00_0000;
            // ���ܳ���ð��
	       
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
                        5'b00000: Ctrls <= 22'b_000_0000_00_01_00000_10_0000; // ���Ǹ�д�Ĵ����ź�
                        default: Ctrls  <= 22'b_000_0000_00_00_00000_00_1000;
                    endcase
                end
            end
            default: Ctrls <= 21'b_000_0000_00_00_00000_0_1000;
	    endcase
	end
	
    assign {
                AluSelecter,            // ALU �ڶ�������ѡ����
                ImmExSg,                // ������������չ�����ź�
                HILOWrt,                // HILO�Ĵ���д�����ź�

                Mem2Reg,                // �洢����(ͨ��)�Ĵ��������ź�, ������WB�׶ο���
                MemEn,                  // �洢��ʹ���ź�
                MemWrite,               // �洢��д�ź�
                MemExSign,              // �ô������չ

                MemSeg,                 // �ô����� {�ֽ�, ����, ��}

                WtRegSelecter,          // д��(ͨ��)�Ĵ���ѡ����������ѡ��rt��rdΪд��Ŀ��
                RegWrite,               // (ͨ��)�Ĵ���д���ź�

                Branch,                 // ��ͨ��תָ��
                Jump,                   // ��������ת�ź�
                Jal,                    // ...
                Jr,                     // ...
                Bal,                    // ...

				Read_CP0,
                Wrt_CP0,                // �Ƿ�дCP0

                Invalid,
				syscall,
				break,
				eret
            } = Ctrls;
endmodule
