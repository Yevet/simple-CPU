`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/15 17:56:45
// Design Name: 
// Module Name: exception
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


module exception(
    input rst,
    input pcexceptM,
    input eretM,
    input brkM,
    input callM,
    input invalidM,
    input overflowM,
    input ADEL,ADES,
    input wire[31:0] cp0_status,
    input wire [31:0] cp0_cause,
    output reg [31:0] exctype
    );
    
    always@(*) begin
        if(rst)
            exctype<=32'h00000000;
        else begin
            exctype<=32'h00000000;
            if(((cp0_status[15:8] & cp0_cause[15:8]) !=8'h00) && (cp0_status[1]==1'b0) && (cp0_status[0]==1'b1))
                exctype <= 32'h00000001;
            else if(pcexceptM || ADEL)
                exctype <= 32'h00000004;
            else if(ADES)
                exctype <= 32'h00000005;
            else if(callM)
                exctype <= 32'h00000008;
            else if(brkM)
                exctype <= 32'h00000009;
            else if(invalidM && eretM!=1'b1)
                exctype <= 32'h0000000a;
            else if(overflowM)
                exctype <= 32'h0000000c;
            else if(eretM)
                exctype <= 32'h0000000e;      
        end
    end
    
endmodule
