module gp2y10(
    input           i_clk,//50Mhz clock
    input           i_rst_n,
    output  [7:0]   o_data,
    input   [7:0]   i_adc_data,
    output          o_adc_clk,
    output  reg     o_led_en
);

//============adc1173============
wire [7:0]data;
adc1173 adc(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .o_data(data),
    .i_adc_data(i_adc_data),
    .o_adc_clk(o_adc_clk)
);

//============Time Count============
reg [19:0] time_cnt;
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        time_cnt <= 0;
    else if(time_cnt == 20'd49_9999)
        time_cnt <= 0;
    else
        time_cnt <= time_cnt + 1;
end

//============LED Control============
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        o_led_en <= 0;
    else if(time_cnt < 20'd1_6000)//0.32ms
        o_led_en <= 0;
    else
        o_led_en <= 1;
end

//============Data Input============
reg[7:0]adc_val;
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        adc_val <= 0;
    else if(time_cnt == 20'd1_5000)//0.30ms
        adc_val <= data;
end

assign o_data = adc_val;
endmodule // gp2y10