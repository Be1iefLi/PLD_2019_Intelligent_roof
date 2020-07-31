//Module: Driver_IIC
//Anthor: Li Lixing
//Made for the IIC Communication for bh1750
//Based on the module of IIC_Driver in the demo project of Camera_Demo

module Driver_IIC(
    input clk, 
    input rst_n,
    // �������ͨ���ź�
    input   [6:0]Addr,
    input   [7:0]Data,
    input   IIC_Write,
    input   IIC_Read,
    output  reg [7:0]IIC_Read_Data_H1 = 8'hff,
    output  reg [7:0]IIC_Read_Data_L1 = 8'hff,
    output  reg [7:0]IIC_Read_Data_H2 = 8'hff,
    output  reg [7:0]IIC_Read_Data_L2 = 8'hff,
    output  IIC_Busy,
    // �ⲿ�ź�
    output  IIC_SCL,
    input   IIC_SDA_In1,
    input   IIC_SDA_In2,
    output reg SDA_Dir=0,// �������ݷ���,�ߵ�ƽΪ�������
    output wire SDA_Out1,// �������
    output wire SDA_Out2
    );
    
    //  SCL ��Ƶϵ��
    // ����IICʱ��  100M/100K = 1000
    parameter  SCL_SUM = 13'd1000;
    reg SDA_Out;
    assign SDA_Out1 = SDA_Out;
    assign SDA_Out2 = SDA_Out;

    // iic��д״̬��
    
    reg  [13:0]     scl_cnt=0;
    always @ (posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            scl_cnt <= 13'd0;
        else if(scl_cnt < (SCL_SUM - 1))
            scl_cnt <= scl_cnt + 1;
        else
            scl_cnt <= 13'd0;
    end 
    
    
    // ��ͬ��ʱ�ӽ׶�
    assign  IIC_SCL = rst_n&(scl_cnt <= (SCL_SUM >> 1));                       // ��ʼΪ�ߵ�ƽ
    wire    scl_hs = (scl_cnt == 13'd1);                                // scl high start
    wire    scl_hc = (scl_cnt == ((SCL_SUM >> 1)-(SCL_SUM >> 2)));      // scl high center
    wire    scl_ls = (scl_cnt == (SCL_SUM >> 1));                       // scl low start
    wire    scl_lc = (scl_cnt == ((SCL_SUM >> 1)+(SCL_SUM >> 2)));      // scl low center
    
    
    
    //IIC״̬�������ź�                
    reg     iicwr_req=0;                                          // IICд�����źţ��ߵ�ƽ��Ч
    reg     iicrd_req=0;                                          // IIC�������źţ��ߵ�ƽ��Ч 
    reg     [2:0]   bcnt=0;
    wire    [7:0]   slave_addr_w = {Addr,1'b0};               // slave��ַ,д����
    wire    [7:0]   slave_addr_r = {Addr,1'b1};             // slave��ַ,������
    wire    [7:0]   iic_wrdb = Data;                   // �����͵����� 
    wire            iic_wr_en = IIC_Write;                    // дʹ��
    wire            iic_rd_en = IIC_Read;                    // ��ʹ��
    
    //****************************************************************************
    // ��дʹ���������ź�
    reg     iic_wr_en_r0,iic_wr_en_r1;
    reg     iic_rd_en_r0,iic_rd_en_r1;
    always @  (posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            iic_wr_en_r0 <= 1'b0;
            iic_wr_en_r1 <= 1'b0;
        end 
        else
        begin
            iic_wr_en_r0 <= iic_wr_en;
            iic_wr_en_r1 <= iic_wr_en_r0;
        end 
    end 
    wire    iic_wr_en_pos = (~iic_wr_en_r1 && iic_wr_en_r0);    // дʹ��������
    
    always @  (posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            iic_rd_en_r0 <= 1'b0;
            iic_rd_en_r1 <= 1'b0;
        end 
        else
        begin
            iic_rd_en_r0 <= iic_rd_en;
            iic_rd_en_r1 <= iic_rd_en_r0;
        end 
    end 
    wire    iic_rd_en_pos = (~iic_rd_en_r1 && iic_rd_en_r0);    // ��ʹ��������
    //****************************************************************************
    // IIC״̬ 
    parameter       IDLE        = 4'd0, 
                    START0      = 4'd1,
                    WRSADDR0    = 4'd2,
                    ACK0        = 4'd3,
                    WRDATA      = 4'd4,
                    ACK1        = 4'd5,
                    STOP        = 4'd6,
                    START1      = 4'd7,
                    WRSADDR1    = 4'd8,
                    ACK2        = 4'd9,
                    RDDATA_H    = 4'd10,
                    NOACK1      = 4'd11,
                    RDDATA      = 4'd12,
                    NOACK2      = 4'd13;
    
    // ״̬��ת
    reg [3:0]   c_state;
    reg [3:0]   n_state;
    
    always @ (posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            c_state <= IDLE;
        else
            c_state <= n_state;
    end 
    
    // ����߼�����
    always @ (*)
    begin
        case(c_state)
            IDLE:       // ��ʼ��
            begin
                if((iicwr_req)&&(scl_hc))
                    n_state = START0;
                else if((iicrd_req)&&(scl_hc))    
                    n_state = START1;
                else
                    n_state = IDLE;
            end 
    
            START0:     // ��ʼ
            begin
                if(scl_lc == 1'b1)
                    n_state = WRSADDR0;
                else
                    n_state = START0;
            end 
    
            WRSADDR0:   // дslave��ַ
            begin
                if((scl_lc == 1'b1)&&(bcnt == 3'd0))
                    n_state = ACK0;
                else
                    n_state = WRSADDR0;
            end 
    
            ACK0:       // ����Ӧ��
            begin
                if(scl_lc == 1'b1)
                    n_state = WRDATA;
                else
                    n_state = ACK0;
            end 
    
            //**************
            // д����
            WRDATA:
            begin
                if((scl_lc == 1'b1)&&(bcnt == 3'd0))
                    n_state = ACK1;
                else
                    n_state = WRDATA;
            end 
    
            ACK1:   // ����Ӧ��
            begin
                if(scl_lc == 1'b1)
                    n_state = STOP;
                else
                    n_state = ACK1;
            end 
    
            //**************
            // �����ݹ���
            START1:
            begin
                if(scl_lc == 1'b1)
                    n_state = WRSADDR1;
                else
                    n_state = START1;
            end 
    
            WRSADDR1:
            begin
                if((scl_lc == 1'b1)&&(bcnt == 3'd0))
                    n_state = ACK2;
                else
                    n_state = WRSADDR1;
            end 
    
            ACK2:   // ����Ӧ��    
            begin
                if(scl_lc == 1'b1)
                    n_state = RDDATA_H;
                else
                    n_state = ACK2;
            end 

            RDDATA_H:
            begin
                if((scl_lc)&&(bcnt == 3'd0))
                    n_state <= NOACK1;
                else
                    n_state <= RDDATA_H;
            end

            NOACK1:
            begin
                if(scl_lc)
                    n_state <= RDDATA;
                else
                    n_state <= NOACK1;
            end
    
            RDDATA:
            begin
                if((scl_lc)&&(bcnt == 3'd0))
                    n_state = NOACK2;
                else
                    n_state = RDDATA;
            end
    
            NOACK2:  
            begin
                if(scl_lc == 1'b1)
                    n_state = STOP;
                else
                    n_state = NOACK2;
            end 
            //**************
    
            STOP:
            begin   
                if(scl_lc == 1'b1)
                    n_state = IDLE;
                else
                    n_state = STOP;
            end 
    
            default:  n_state = IDLE;  
        endcase 
    end 
    
    
    // ����������
    always @ (posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            bcnt <= 3'd0;
        else
        begin
            case (n_state)
                WRSADDR0,WRDATA,WRSADDR1,RDDATA_H,RDDATA:
                begin
                    if(scl_lc == 1'b1)
                        bcnt <= bcnt + 1;    
                end 
                default: bcnt <= 3'd0;
            endcase 
        end 
    end 
    
    // �����������
    always @ (posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
        begin
            SDA_Dir <= 1'b1;
            SDA_Out <= 1'b1;
        end 
        else
        begin
            case (n_state)
                IDLE,NOACK2:
                begin
                    SDA_Dir <= 1'b1;
                    SDA_Out <= 1'b1;
                end 
                
                NOACK1:
                begin
                    SDA_Dir <= 1'b1;
                    SDA_Out <= 1'b0;
                end
    
                START0:
                begin
                    SDA_Dir <= 1'b1;
                    SDA_Out <= 1'b0;          // ���뿪ʼ״̬��,��������
                end 
    
                START1:
                begin
                    SDA_Dir <= 1'b1;
                    if(scl_lc == 1'b1)
                        SDA_Out <= 1'b1;
                    else if(scl_hc == 1'b1)
                        SDA_Out <= 1'b0;
                end 
    
    
                WRSADDR0:
                begin
                    SDA_Dir <= 1'b1;
                    if(scl_lc == 1'b1)
                        SDA_Out <= slave_addr_w[7-bcnt];
                end 
    
                WRSADDR1:
                begin
                    SDA_Dir <= 1'b1;
                    if(scl_lc == 1'b1)
                        SDA_Out <= slave_addr_r[7-bcnt];
                end 
    
    
                ACK0,ACK1,ACK2:  SDA_Dir <= 1'b0;      // ������������
    
                WRDATA:
                begin
                    SDA_Dir <= 1'b1;
                    if(scl_lc == 1'b1)
                        SDA_Out <= iic_wrdb[7-bcnt];
                end 

                RDDATA_H:
                begin
                    SDA_Dir <= 1'b0;
                    if(scl_lc == 1'b1)
                        IIC_Read_Data_H1[7-bcnt] <= IIC_SDA_In1;
                        IIC_Read_Data_H2[7-bcnt] <= IIC_SDA_In2;
                end
    
                RDDATA:
                begin
                    SDA_Dir <= 1'b0;
                    if(scl_lc == 1'b1)
                        IIC_Read_Data_L1[7-bcnt] <= IIC_SDA_In1;
                        IIC_Read_Data_L2[7-bcnt] <= IIC_SDA_In2;
                end 
    
                STOP:
                begin
                    SDA_Dir <= 1'b1;
                    if(scl_lc == 1'b1)
                        SDA_Out <= 1'b0;
                    else if(scl_hc == 1'b1)
                        SDA_Out <= 1'b1;
                end 
    
            endcase 
        end 
    end 
    wire iic_ack = (c_state == STOP) && scl_hc; //IIC������Ӧ���ߵ�ƽ��Ч
    // ȷ����д���̱�־
    always @ (posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            iicwr_req <= 1'b0;
        else
        begin
            if(iic_wr_en_pos == 1'b1)
                iicwr_req <= 1'b1;
            else if(iic_ack == 1'b1)            // IIC���̽���
                iicwr_req <= 1'b0;    
        end 
    end 
    
    always @ (posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            iicrd_req <= 1'b0;
        else
        begin
            if(iic_rd_en_pos == 1'b1)
                iicrd_req <= 1'b1;
            else if(iic_ack == 1'b1)            // IIC���̽���
                iicrd_req <= 1'b0;    
        end 
    end 
    
    // ��������ʱһֱæ,��ɹ��̺�æ����
    assign  IIC_Busy = (iicwr_req || iicrd_req);

endmodule
