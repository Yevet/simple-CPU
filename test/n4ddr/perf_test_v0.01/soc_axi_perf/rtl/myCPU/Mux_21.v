`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 21:50:54
// Design Name: 
// Module Name: Mux_21
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

// 2-1 Ñ¡ÔñÆ÷
module Mux_21 #(parameter DATA_WIDTH = 32)(
        input sw,
        input [DATA_WIDTH-1:0] D1, D2,
        output reg [DATA_WIDTH-1:0] Dout
    );
    always@(*) begin
        if (sw == 0) Dout <= D1;
        else Dout <= D2;
    end
endmodule
