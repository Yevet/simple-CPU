`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/16 17:28:42
// Design Name: 
// Module Name: div_state
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

module div_state(
    input [7:0] alucontrol,
    input div_ready,
    output reg div_stall,div_start,div_signed
    );
    
    always@(*) begin
        case(alucontrol)
            `EXE_DIV_OP: begin
                if(div_ready== 1'b0) begin
                    div_start<=1'b1;
                    div_signed<=1'b1;
                    div_stall<=1'b1;
                end
                else if(div_ready == 1'b1) begin
                    div_start<=1'b0;
                    div_signed<=1'b1;
                    div_stall<=1'b0;
                end
                else begin
                    div_start<=1'b0;
                    div_signed<=1'b0;
                    div_stall<=1'b0;
                end
            end
            `EXE_DIVU_OP: begin
                if(div_ready== 1'b0) begin
                    div_start<=1'b1;
                    div_signed<=1'b0;
                    div_stall<=1'b1;
                end
                else if(div_ready == 1'b1) begin
                    div_start<=1'b0;
                    div_signed<=1'b0;
                    div_stall<=1'b0;
                end
                else begin
                    div_start<=1'b0;
                    div_signed<=1'b0;
                    div_stall<=1'b0;
                end
            end
            default: begin
                div_start<=1'b0;
                div_signed<=1'b0;
                div_stall<=1'b0;
            end
        endcase
    end
endmodule
