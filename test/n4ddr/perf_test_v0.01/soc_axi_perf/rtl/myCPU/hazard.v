`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/05 19:30:12
// Design Name: 
// Module Name: hazard
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


module hazard(
        output wire FI_Stall, FI_Flush,             // 
        output wire DE_Stall, DE_Flush,             // 
        output wire EX_Stall, EX_Flush,             // 
        output wire ME_Stall, ME_Flush,             // 
        output wire WB_Stall, WB_Flush,             // 流水线控制信号
        output wire Except_Flush,

        output wire DE_Forward_1, DE_Forward_2,     // 
        output wire[1:0] EX_Forward_1,EX_Forward_2,  // 数据前推选择信号
        output wire[1:0] CP0_Forward,                // CP0数据前推选择信号

        input wire FI_ReqStall, ME_ReqStall,

        input wire[4:0] DE_RegPos1, DE_RegPos2,     // 
        input wire[4:0] EX_RegPos1, EX_RegPos2,     // 两个寄存器读位置
        input wire[4:0] EX_RegPos3, ME_RegPos3, WB_RegPos3,
        input wire[4:0] EX_RegWrtPos,               //
        input wire[4:0] ME_RegWrtPos,               //
        input wire[4:0] WB_RegWrtPos,               // 三个寄存器写位置

        input wire EX_RegWrtEna,                    // EX 寄存器写使能
        input wire EX_Mem2Reg  ,                    // EX 内存写寄存器
        input wire ME_RegWrtEna,                    // ME 寄存器写使能
        input wire ME_Mem2Reg  ,                    // ME 内存写寄存器
        input wire WB_RegWrtEna,                    // WB 寄存器写使能
        
        input wire MD_Stall,                        // 乘除法的stall
        input wire DE_Branch, DE_Jr,
        input wire EX_CP0_Read, ME_CP0Wen, WB_CP0Wen,
        input wire[31:0] ME_ExceptType
    );
    // 这下面放暂时没用到的信号量
    assign {WB_Stall} = 0;
    
    

    // 控制冒险目前不太好想，先把数据冒险做了
    // 由于数据冒险大多是考虑寄存器未写先读，而读取寄存器在DE阶段，并且
    // 在EX阶段的计算数据不稳定(只有到下个周期被读入ME阶段寄存器后才算
    // 稳定)，因此只需要考虑ME、WB阶段的数据前推

    // DE 阶段本身读寄存器，所以数据前推只需要ME阶段的数据
    assign DE_Forward_1 = (DE_RegPos1 != 0) & (DE_RegPos1 == ME_RegWrtPos) & ME_RegWrtEna;
	assign DE_Forward_2 = (DE_RegPos2 != 0) & (DE_RegPos2 == ME_RegWrtPos) & ME_RegWrtEna;

    assign CP0_Forward = (EX_CP0_Read && ME_CP0Wen && (EX_RegPos3 == ME_RegPos3)) ? 2'b01 :
                         (EX_CP0_Read && WB_CP0Wen && (EX_RegPos3 == WB_RegPos3)) ? 2'b10 :
                         2'b00;

    // EX 阶段因为过了寄存器，所以不仅需要ME阶段的前推，还需要WB阶段的前推
    assign EX_Forward_1 = ((EX_RegPos1 != 0) & (EX_RegPos1 == ME_RegWrtPos) & ME_RegWrtEna)? 2'b01:
                          ((EX_RegPos1 != 0) & (EX_RegPos1 == WB_RegWrtPos) & WB_RegWrtEna)? 2'b10:
                          2'b00;

    assign EX_Forward_2 = ((EX_RegPos2 != 0) & (EX_RegPos2 == ME_RegWrtPos) & ME_RegWrtEna)? 2'b01:
                          ((EX_RegPos2 != 0) & (EX_RegPos2 == WB_RegWrtPos) & WB_RegWrtEna)? 2'b10:
                          2'b00;

    // 对于流水线控制，一个最经典的就是由于访存导致只能在回写阶段得到稳定的
    // 数据，因此只能在WB阶段进行前推，但假设在访存ME时，EX存在依赖，则下个
    // 周期WB无法前推给已经到达ME阶段的依赖，只能靠将EX阶段暂停1个周期，之
    // 后将WB前推给暂停了1周期的EX阶段

    // 另一个需要暂停寄存器的操作是乘除法操作，由于是多周期，因此需要暂停EX
    // 之前的所有阶段，由于EX对向后的ME、WB不存在后向依赖，因此EX之后的流水
    // 线可以不做处理(控制信号中没有任何对寄存器的控制信号)

    // 跳转指令因为都能在DE阶段解决，并且存在延迟槽，因此不用担心跳转的下一
    // 条指令的执行会产生错误，但是，由于部分跳转指令涉及对寄存器的读取判断
    // ，并且DE阶段就需要判断完成，而EX部分的数据无法前推，ME部分需要访存
    // 并写回的数据无法前推，因此也需要流水线暂停(但不需要清空)

    // 在EX阶段判断貌似可以避免一次数据前推
    wire DE_LoadStall, DE_BranchStall, DE_JrStall;
    assign DE_LoadStall = (EX_Mem2Reg & 
                          ((EX_RegPos2 == DE_RegPos1)| 
                           (EX_RegPos2 == DE_RegPos2)));

    assign Except_Flush = (ME_ExceptType != 0);

    assign DE_BranchStall = (DE_Branch &
        (EX_RegWrtEna & (DE_RegPos1 == EX_RegWrtPos | DE_RegPos2 == EX_RegWrtPos)) |
        (ME_Mem2Reg   & (DE_RegPos1 == ME_RegWrtPos | DE_RegPos2 == ME_RegWrtPos)) |
        (EX_CP0_Read  & (DE_RegPos1 == EX_RegWrtPos | DE_RegPos2 == ME_RegWrtPos))
        );

    assign DE_JrStall = (DE_Jr & 
        (EX_RegWrtEna & (EX_RegWrtPos == DE_RegPos1)) |
        (ME_Mem2Reg   & (ME_RegWrtPos == DE_RegPos1)) |
        (EX_CP0_Read  & (EX_RegWrtPos == DE_RegPos1))  // bug才想到cp0的数据和跳转冲突也需要stall
        );

    assign FI_Stall = DE_Stall;
    assign DE_Stall = DE_LoadStall | DE_BranchStall | DE_JrStall | MD_Stall | FI_ReqStall | ME_ReqStall;
    assign EX_Stall = MD_Stall | ME_ReqStall;
    assign ME_Stall = ME_ReqStall;


    assign FI_Flush = Except_Flush;
    assign DE_Flush = Except_Flush;
    assign EX_Flush = Except_Flush | DE_Stall & (~EX_Stall); // EX不stall时才可以Flush
    assign ME_Flush = Except_Flush;
    assign WB_Flush = Except_Flush | ME_ReqStall;



    // DE 一旦 Stall了，如果不清空EX，那么DE不会走，但是EX会一直从被锁住的
    // DE 获取状态，相当于DE被执行了很多次
    // J类跳转地址只来自立即数，不会读取寄存器，因此不存在依赖
    // Jr类指令需要读取一个寄存器，类似Branch，可以直接和Branch合并
    // (后来发现好像8行)

    // 差点忘了乘除法的Stall MD_Stall
    // 乘除法运行中，直到出结果前，需要：暂停FI、DE、EX流水线，清空ME阶段流水

endmodule
