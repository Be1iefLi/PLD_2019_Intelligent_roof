//Module name: bh1750_IIC
//Author: Li Lixing
//Made for bh1750

module bh1750_IIC(
    input clk,//100Mhz
    input rst_n,
    output reg [15:0]I1_data,
    output reg [15:0]I2_data,
    output reg [15:0]I3_data,
    output reg [15:0]Ih_data,
    output reg [1:0]c_state,
    output IIC_SCL,
    inout IIC_SDA1,
    inout IIC_SDA2
);

localparam  address1 = 7'b010_0011,
            address2 = 7'b101_1100,
            instruction = 8'b0010_0000;
reg [7:0]addr;
reg IIC_Write;
reg IIC_Read;
wire [7:0]IIC_data_H1, IIC_data_H2;
wire [7:0]IIC_data_L1, IIC_data_L2;
wire IIC_Busy;
wire SDA_Dir;
wire SDA_Out1, SDA_Out2;
wire SDA_In1, SDA_In2;

//IIC Driver
Driver_IIC iic(
    .clk(clk),
    .rst_n(rst_n),
    .Addr(addr),
    .Data(instruction),
    .IIC_Write(IIC_Write),
    .IIC_Read(IIC_Read),
    .IIC_Read_Data_H1(IIC_data_H1),
    .IIC_Read_Data_L1(IIC_data_L1),
    .IIC_Read_Data_H2(IIC_data_H2),
    .IIC_Read_Data_L2(IIC_data_L2),
    .IIC_Busy(IIC_Busy),
    .IIC_SCL(IIC_SCL),
    .IIC_SDA_In1(SDA_In1),
    .IIC_SDA_In2(SDA_In2),
    .SDA_Dir(SDA_Dir),
    .SDA_Out1(SDA_Out1),
    .SDA_Out2(SDA_Out2)
);

assign IIC_SDA1 = SDA_Dir ? SDA_Out1:1'bz;
assign SDA_In1 = SDA_Dir ? 1'b1:IIC_SDA1;
assign IIC_SDA2 = SDA_Dir ? SDA_Out2:1'bz;
assign SDA_In2 = SDA_Dir ? 1'b1:IIC_SDA2;
reg select = 0;

//IIC Busy Edge Test
reg [1:0]IIC_Busy_Sample;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        IIC_Busy_Sample <= 2'b00;
    else
        IIC_Busy_Sample <= {IIC_Busy_Sample[0], IIC_Busy};
end
wire IIC_Busy_DIS;
assign IIC_Busy_DIS = (IIC_Busy_Sample == 2'b10);

//2s Count
reg [27:0]cnt_2s;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_2s <= 0;
    else if(cnt_2s == 28'd199_999_999)
        cnt_2s <= 0;
    else
        cnt_2s <= cnt_2s + 1'b1;
end

//State Register
//reg [1:0]c_state;
reg [1:0]n_state;
localparam  st_idle = 2'd0,
            st_write= 2'd1,
            st_wait = 2'd2,
            st_read = 2'd3;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= st_idle;
    else begin
        c_state <= n_state;
        if(c_state == st_read && n_state == st_idle)
            select = ~select;
    end
end

//200ms Count
reg [24:0]time_cnt;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        time_cnt <= 0;
    else if(c_state != st_wait)
        time_cnt <= 0;
    else
        time_cnt <= time_cnt + 1;
end

//Next State Logic
always @(*) begin
    case (c_state)
        st_idle:
            begin
                if(cnt_2s == 28'd99_999_999) 
                    n_state = st_write;
                else
                    n_state = st_idle;
            end
        st_write:
            begin
                if(IIC_Busy_DIS)
                    n_state = st_wait;
                else
                    n_state = st_write;
            end
        st_wait:
            begin
                if(time_cnt == 25'd19_999_999)
                    n_state = st_read;
                else
                    n_state = st_wait;
            end
        st_read:
            begin
                if(IIC_Busy_DIS)
                    n_state = st_idle;
                else
                    n_state = st_read;
            end
    endcase
end
//Output Logic
reg Busy_Confirm;
always @(posedge clk) begin
    case (c_state)
        st_idle:
            begin
                if(!select)begin
                    addr <= address1;
                    I2_data <= {IIC_data_H1, IIC_data_L1};
                    Ih_data <= {IIC_data_H2, IIC_data_L2};
                end
                else begin
                    addr <= address2;
                    I1_data <= {IIC_data_H1, IIC_data_L1};
                    I2_data <= {IIC_data_H2, IIC_data_L2};
                end
                Busy_Confirm <= 1'b0;
                IIC_Read <= 1'b0;
                IIC_Write <= 1'b0;
            end 
        st_write:
            begin
                if(!Busy_Confirm)
                    IIC_Write <= 1'b1;
                else
                    IIC_Write <= 1'b0;
                if(IIC_Busy)
                    Busy_Confirm <= 1'b1;
            end
        st_wait:
            begin
                Busy_Confirm <= 1'b0;
            end 
        st_read:
            begin
                if(!Busy_Confirm)
                    IIC_Read <= 1'b1;
                else
                    IIC_Read <= 1'b0;
                if(IIC_Busy)
                    Busy_Confirm <= 1'b1;
            end
    endcase
end

endmodule // bh1750_IIC