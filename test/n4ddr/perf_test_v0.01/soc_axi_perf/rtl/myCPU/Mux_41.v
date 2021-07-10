`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 21:51:56
// Design Name: 
// Module Name: Mux_41
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

module Mux_41 #(parameter WIDTH = 8)(
    input wire[1:0] sw,
	input wire[WIDTH-1:0] d0, d1, d2, d3,
	output wire[WIDTH-1:0] y
    );

	assign y = (sw == 2'b00) ? d0:
			    (sw == 2'b01) ? d1:
			    (sw == 2'b10) ? d2: d3;
endmodule
