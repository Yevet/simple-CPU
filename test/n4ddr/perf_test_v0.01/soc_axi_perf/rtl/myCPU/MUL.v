`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 00:31:42
// Design Name: 
// Module Name: MUL
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

`define MUL_FREE  2'b00
`define MUL_BUSY  2'b01
`define MUL_FINI  2'b10
`include "defines.vh"

module MUL(
    input wire clk, rst,
    input wire signed_mul, // 有符号乘法

    input wire[31:0] a, b,
    input wire start, stop,

    output reg[63:0] result,
    output reg ready
    );

    reg ResultSign;
    reg[31:0] temp_op1, temp_op2;
    reg[1 :0] state;
    reg[2 :0] cnt;
    wire[63:0] temp_res;
    assign temp_res = temp_op1 * temp_op2;

    always @(posedge clk) begin
        if(rst) begin
            state <= `MUL_FREE;
            ready <= 1'b0; // 结果未就绪
            result <= {`ZeroWord, `ZeroWord};
            temp_op1 <= 0;
            temp_op2 <= 0;
        end else begin
            case(state)
                `MUL_FREE: begin
                    ready <= 1'b0;
                    if(start == 1'b1 && stop == 1'b0) begin
                        state <= `MUL_BUSY;
                        result <= {`ZeroWord, `ZeroWord};
                        cnt <= 3'b000;

                        if(signed_mul == 1'b1 && a[31] == 1'b1 ) begin
                            temp_op1 <= ~a + 1;
                        end else begin
                            temp_op1 <= a;
                        end

                        if(signed_mul == 1'b1 && b[31] == 1'b1 ) begin
                            temp_op2 <= ~b + 1;
                        end else begin
                            temp_op2 <= b;
                        end

                        if(signed_mul == 1'b1) begin
                            ResultSign <= a[31] ^ b[31];
                        end else begin
                            ResultSign <= 1'b0;
                        end
                    end
                end
                `MUL_BUSY: begin
                    if(stop == 1'b0) begin
                        if(cnt != 3'b001) begin
                            cnt <= cnt + 1;
                        end else begin
                            state <= `MUL_FINI;
                            cnt <= 3'b000;    
                        end
                    end else begin
                        state <= `MUL_FREE;
                    end
                end
                `MUL_FINI: begin
                    ready <= 1'b1;
                    if(ResultSign) begin
                        result <= ~temp_res + 1;
                    end else begin
                        result <= temp_res;
                    end
                    if(ready == 1'b1) begin
                        state <= `MUL_FREE;
                        ready <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule