`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/02 20:31:48
// Design Name: 
// Module Name: flopenr
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


module pc(
    input clk, reset,
    input en, 
    input [31:0] d, 
    output reg [31:0] q
);
    always @(posedge clk or posedge reset) 
        if(reset) q<=32'hbfc00000; 
        else if(en) q<=d; 
    
endmodule