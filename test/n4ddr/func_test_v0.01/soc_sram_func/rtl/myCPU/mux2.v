`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/02 20:23:14
// Design Name: 
// Module Name: mux2
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

module mux2 #(parameter WIDTH=8)(
    input [WIDTH-1:0]op1,
    input [WIDTH-1:0]op2,
    input control,
    output [WIDTH-1:0]result
    );
    
    assign result = ( control == 1'b0 ? op1 : op2);
    
endmodule

