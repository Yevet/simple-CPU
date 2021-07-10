`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/13 16:26:35
// Design Name: 
// Module Name: memsel
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

`include"defines.vh"

module memsel(
    input wire [31:0]readdata, 
    input wire [3:0]memwriteM,     
    input wire [31:0]dataadr,  
    input wire [31:0]writedataM,    
    output reg [31:0]finaldata,  
    input wire [7:0] alucontrolM,
    output reg ADEL,
    output reg ADES,
    output reg [31:0]badadr,
    output reg [31:0] writedata,
    output reg  [3:0] memwrite
    );
    

    always@(*) begin
        ADEL<=0;
        ADES<=0;
        case(alucontrolM)
            `EXE_LW_OP: begin 
                if(dataadr[1:0]==2'b00) begin
                    finaldata <= readdata;
                    memwrite <= memwriteM;
                end else begin
                    ADEL<=1;
                    badadr<=dataadr;
                end
            end
            `EXE_LB_OP: begin
                case(dataadr[1:0])
                    2'b11: finaldata<= {{24{readdata[31]}},readdata[31:24]};
                    2'b10: finaldata<= {{24{readdata[23]}},readdata[23:16]};
                    2'b01: finaldata<= {{24{readdata[15]}},readdata[15:8]};
                    2'b00: finaldata<= {{24{readdata[7]}},readdata[7:0]};
                    default:begin
                        ADEL<=1;
                        badadr<=dataadr;
                    end
                endcase
                memwrite <= memwriteM;
            end
            `EXE_LH_OP:begin
                case(dataadr[1:0])
                    2'b10: finaldata<= {{16{readdata[31]}},readdata[31:16]};
                    2'b00: finaldata<= {{16{readdata[15]}},readdata[15:0]};
                    default: begin
                        ADEL<=1;
                        badadr<=dataadr;
                    end
                endcase
                memwrite <= memwriteM;
            end
            `EXE_LBU_OP:begin
                case(dataadr[1:0])
                     2'b11: finaldata<= {{24{1'b0}},readdata[31:24]};
                     2'b10: finaldata<= {{24{1'b0}},readdata[23:16]};
                     2'b01: finaldata<= {{24{1'b0}},readdata[15:8]};
                     2'b00: finaldata<= {{24{1'b0}},readdata[7:0]};
                     default:begin
                        ADEL<=1;
                        badadr<=dataadr;
                     end
                 endcase
                 memwrite <= memwriteM;
            end
            `EXE_LHU_OP:begin
                case(dataadr[1:0])
                    2'b10: finaldata<= {{16{1'b0}},readdata[31:16]};
                    2'b00: finaldata<= {{16{1'b0}},readdata[15:0]};
                    default: begin
                        ADEL<=1;
                        badadr<=dataadr;
                    end
                endcase
                memwrite <= memwriteM;
            end
            `EXE_SW_OP:begin
                writedata <= writedataM;
                if(dataadr[1:0]!=2'b00) begin
                    ADES<=1;
                    badadr<=dataadr;
                end else begin
                    memwrite <= memwriteM;
                    writedata <= writedataM;
                end
            end
            `EXE_SH_OP:begin
                writedata <= {writedataM[15:0],writedataM[15:0]};
                if((dataadr[1:0]!=2'b00) && (dataadr[1:0]!=2'b10)) begin
                    ADES<=1;
                    badadr<=dataadr;
                end else if(dataadr[1:0]==2'b00) begin
                    memwrite<=4'b0011;
                end else if(dataadr[1:0]==2'b10) begin
                    memwrite<=4'b1100;
                end
            end
            `EXE_SB_OP:begin
                writedata <= {writedataM[7:0],writedataM[7:0],writedataM[7:0],writedataM[7:0]};
                if(dataadr[1:0]==2'b00)
                    memwrite<=4'b0001;
                else if(dataadr[1:0]==2'b01)
                    memwrite<=4'b0010;
                else if(dataadr[1:0]==2'b10)
                    memwrite<=4'b0100;
                else if(dataadr[1:0]==2'b11)
                    memwrite<=4'b1000;
                else begin
                    ADES<=1;
                    badadr<=dataadr;
                end 
            end
        endcase
    end
endmodule
