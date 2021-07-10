`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/28 17:27:34
// Design Name: 
// Module Name: mux4
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


module mux4(
    input [31:0] a,b,c,d,
    input [1:0] sl,
    output [31:0] result
    );
    
    assign result = (sl == 2'b01) ? b :
                    (sl == 2'b10) ? c :
                    (sl == 2'b11) ? d : a;
   
endmodule