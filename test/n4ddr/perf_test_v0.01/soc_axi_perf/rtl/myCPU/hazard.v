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
        output wire WB_Stall, WB_Flush,             // ��ˮ�߿����ź�
        output wire Except_Flush,

        output wire DE_Forward_1, DE_Forward_2,     // 
        output wire[1:0] EX_Forward_1,EX_Forward_2,  // ����ǰ��ѡ���ź�
        output wire[1:0] CP0_Forward,                // CP0����ǰ��ѡ���ź�

        input wire FI_ReqStall, ME_ReqStall,

        input wire[4:0] DE_RegPos1, DE_RegPos2,     // 
        input wire[4:0] EX_RegPos1, EX_RegPos2,     // �����Ĵ�����λ��
        input wire[4:0] EX_RegPos3, ME_RegPos3, WB_RegPos3,
        input wire[4:0] EX_RegWrtPos,               //
        input wire[4:0] ME_RegWrtPos,               //
        input wire[4:0] WB_RegWrtPos,               // �����Ĵ���дλ��

        input wire EX_RegWrtEna,                    // EX �Ĵ���дʹ��
        input wire EX_Mem2Reg  ,                    // EX �ڴ�д�Ĵ���
        input wire ME_RegWrtEna,                    // ME �Ĵ���дʹ��
        input wire ME_Mem2Reg  ,                    // ME �ڴ�д�Ĵ���
        input wire WB_RegWrtEna,                    // WB �Ĵ���дʹ��
        
        input wire MD_Stall,                        // �˳�����stall
        input wire DE_Branch, DE_Jr,
        input wire EX_CP0_Read, ME_CP0Wen, WB_CP0Wen,
        input wire[31:0] ME_ExceptType
    );
    // ���������ʱû�õ����ź���
    assign {WB_Stall} = 0;
    
    

    // ����ð��Ŀǰ��̫���룬�Ȱ�����ð������
    // ��������ð�մ���ǿ��ǼĴ���δд�ȶ�������ȡ�Ĵ�����DE�׶Σ�����
    // ��EX�׶εļ������ݲ��ȶ�(ֻ�е��¸����ڱ�����ME�׶μĴ��������
    // �ȶ�)�����ֻ��Ҫ����ME��WB�׶ε�����ǰ��

    // DE �׶α�����Ĵ�������������ǰ��ֻ��ҪME�׶ε�����
    assign DE_Forward_1 = (DE_RegPos1 != 0) & (DE_RegPos1 == ME_RegWrtPos) & ME_RegWrtEna;
	assign DE_Forward_2 = (DE_RegPos2 != 0) & (DE_RegPos2 == ME_RegWrtPos) & ME_RegWrtEna;

    assign CP0_Forward = (EX_CP0_Read && ME_CP0Wen && (EX_RegPos3 == ME_RegPos3)) ? 2'b01 :
                         (EX_CP0_Read && WB_CP0Wen && (EX_RegPos3 == WB_RegPos3)) ? 2'b10 :
                         2'b00;

    // EX �׶���Ϊ���˼Ĵ��������Բ�����ҪME�׶ε�ǰ�ƣ�����ҪWB�׶ε�ǰ��
    assign EX_Forward_1 = ((EX_RegPos1 != 0) & (EX_RegPos1 == ME_RegWrtPos) & ME_RegWrtEna)? 2'b01:
                          ((EX_RegPos1 != 0) & (EX_RegPos1 == WB_RegWrtPos) & WB_RegWrtEna)? 2'b10:
                          2'b00;

    assign EX_Forward_2 = ((EX_RegPos2 != 0) & (EX_RegPos2 == ME_RegWrtPos) & ME_RegWrtEna)? 2'b01:
                          ((EX_RegPos2 != 0) & (EX_RegPos2 == WB_RegWrtPos) & WB_RegWrtEna)? 2'b10:
                          2'b00;

    // ������ˮ�߿��ƣ�һ�����ľ������ڷô浼��ֻ���ڻ�д�׶εõ��ȶ���
    // ���ݣ����ֻ����WB�׶ν���ǰ�ƣ��������ڷô�MEʱ��EX�������������¸�
    // ����WB�޷�ǰ�Ƹ��Ѿ�����ME�׶ε�������ֻ�ܿ���EX�׶���ͣ1�����ڣ�֮
    // ��WBǰ�Ƹ���ͣ��1���ڵ�EX�׶�

    // ��һ����Ҫ��ͣ�Ĵ����Ĳ����ǳ˳��������������Ƕ����ڣ������Ҫ��ͣEX
    // ֮ǰ�����н׶Σ�����EX������ME��WB�����ں������������EX֮�����ˮ
    // �߿��Բ�������(�����ź���û���κζԼĴ����Ŀ����ź�)

    // ��תָ����Ϊ������DE�׶ν�������Ҵ����ӳٲۣ���˲��õ�����ת����һ
    // ��ָ���ִ�л�������󣬵��ǣ����ڲ�����תָ���漰�ԼĴ����Ķ�ȡ�ж�
    // ������DE�׶ξ���Ҫ�ж���ɣ���EX���ֵ������޷�ǰ�ƣ�ME������Ҫ�ô�
    // ��д�ص������޷�ǰ�ƣ����Ҳ��Ҫ��ˮ����ͣ(������Ҫ���)

    // ��EX�׶��ж�ò�ƿ��Ա���һ������ǰ��
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
        (EX_CP0_Read  & (EX_RegWrtPos == DE_RegPos1))  // bug���뵽cp0�����ݺ���ת��ͻҲ��Ҫstall
        );

    assign FI_Stall = DE_Stall;
    assign DE_Stall = DE_LoadStall | DE_BranchStall | DE_JrStall | MD_Stall | FI_ReqStall | ME_ReqStall;
    assign EX_Stall = MD_Stall | ME_ReqStall;
    assign ME_Stall = ME_ReqStall;


    assign FI_Flush = Except_Flush;
    assign DE_Flush = Except_Flush;
    assign EX_Flush = Except_Flush | DE_Stall & (~EX_Stall); // EX��stallʱ�ſ���Flush
    assign ME_Flush = Except_Flush;
    assign WB_Flush = Except_Flush | ME_ReqStall;



    // DE һ�� Stall�ˣ���������EX����ôDE�����ߣ�����EX��һֱ�ӱ���ס��
    // DE ��ȡ״̬���൱��DE��ִ���˺ܶ��
    // J����ת��ַֻ�����������������ȡ�Ĵ�������˲���������
    // Jr��ָ����Ҫ��ȡһ���Ĵ���������Branch������ֱ�Ӻ�Branch�ϲ�
    // (�������ֺ���8��)

    // ������˳˳�����Stall MD_Stall
    // �˳��������У�ֱ�������ǰ����Ҫ����ͣFI��DE��EX��ˮ�ߣ����ME�׶���ˮ

endmodule
