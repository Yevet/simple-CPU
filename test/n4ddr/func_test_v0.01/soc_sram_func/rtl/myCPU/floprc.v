`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/02 20:31:48
// Design Name: 
// Module Name: floprc
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

module floprc #(parameter WIDTH=8) (
    input clk, reset,
    input flush, 
    input [WIDTH-1:0] d, 
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset) 
        if(reset) q<=0; 
        else if(flush) q<=0;
        else q<=d; 
    
endmodule
