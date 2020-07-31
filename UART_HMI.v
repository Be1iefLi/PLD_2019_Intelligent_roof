module UART_HMI(
    input clk,
    input rst_n,
    input Rx,
    input [30:0]Baud_Rate,
    input [15:0]I1_data,
    input [15:0]I2_data,
    input [15:0]I3_data,
    input [15:0]Ih_data,
    input [7:0]Temp,
    input [7:0]Humi,
    input [5:0]sw,
    input auto_in,
    output reg auto_out,
    output Tx,
    output uart_clk,
    output tx_en,
    output reg [1:0]tx_delay,
    output reg state_change,
    output reg [3:0]crt_state
);

//State
//reg[3:0]crt_state;
reg[3:0]next_state;

localparam  idle        = 4'd0,
            I1_send     = 4'd1,
            I2_send     = 4'd2,
            I3_send     = 4'd3,
            Ih_send     = 4'd4,
            Temp_send   = 4'd5,
            Humi_send   = 4'd6,
            auto_rev    = 4'd7,
            auto_send   = 4'd8;

//State Register
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        crt_state <= idle;
    else   
        crt_state <= next_state;
end

//Time delay count
reg[31:0] delay_cnt;
localparam delay = 32'd50_00;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        delay_cnt <= 0;
    else if(crt_state != idle)
        delay_cnt <= 0;
    else
        delay_cnt <= delay_cnt + 1;
end

//UART buf
reg [5:0]tx_cnt;
reg [511:0]tx_buf;
reg [5:0]tx_total;
reg [3:0]rx_cnt;
reg [39:0]rx_buf;

//UART transmission
reg EN_Tx = 0;
assign tx_en = EN_Tx;
reg [7:0]Tx_Data;
wire [7:0]Rx_Data;
wire Tx_ACK, Rx_ACK;

Driver_UART uart1(
    .clk_100MHz(clk),
    .Rst(rst_n),
    .En_Rx(1'b1),
    .En_Tx(EN_Tx),
    .Baud_Rate(Baud_Rate),
    .Rx(Rx),
    .Tx_Data(Tx_Data),
    .Tx(Tx),
    .Rx_Data(Rx_Data),
    .Rx_ACK(Rx_ACK),
    .clk_UART(uart_clk),
    .Tx_ACK(Tx_ACK)
);

//State Judgement
reg last_state;
//reg state_change;
always @(posedge clk) last_state <= crt_state[0];

always @(*) begin
    if({last_state, crt_state[0]} == 2'b10 || {last_state, crt_state[0]} == 2'b01)
        state_change <= 1;
    else
        state_change <= 0;
end

reg change_state;
//Next State Logic
always @(*) begin
    case (crt_state)
        idle:
        begin
            if(delay_cnt >= delay)
                next_state = I1_send;
            else
                next_state = idle;
        end 
        I1_send, I2_send, I3_send, Ih_send, Temp_send, Humi_send, auto_send:
        begin
            if(!state_change && tx_cnt == tx_total)
                next_state = crt_state + 1;
            else
                next_state = crt_state;
        end
        auto_rev:
        begin
            if(!state_change && change_state)
                next_state <= crt_state + 1;
            else
                next_state <= crt_state;
        end

        default: next_state <= idle;
    endcase
end

//bcd Circuit
reg [19:0]I1_bcd_reg, I2_bcd_reg, I3_bcd_reg, Ih_bcd_reg;
reg [7:0]Temp_bcd_reg, Humi_bcd_reg;
wire I1_done, I2_done, I3_done, Ih_done, Temp_done, Humi_done;
wire [19:0]I1_bcd, I2_bcd, I3_bcd, Ih_bcd;
wire [7:0]Temp_bcd, Humi_bcd;
bin2bcd bin2bcd_I1(
    .clk(clk),
    .rst(~rst_n),
    .bin({4'b0, I1_data}),
    .bcd(I1_bcd),
    .done(I1_done)
);

bin2bcd bin2bcd_I2(
    .clk(clk),
    .rst(~rst_n),
    .bin({4'b0, I2_data}),
    .bcd(I2_bcd),
    .done(I2_done)
);

bin2bcd bin2bcd_I3(
    .clk(clk),
    .rst(~rst_n),
    .bin({4'b0, I3_data}),
    .bcd(I3_bcd),
    .done(I3_done)
);

bin2bcd bin2bcd_Ih(
    .clk(clk),
    .rst(~rst_n),
    .bin({4'b0, Ih_data}),
    .bcd(Ih_bcd),
    .done(Ih_done)
);

bin2bcd bin2bcd_Temp(
    .clk(clk),
    .rst(~rst_n),
    .bin({12'b0, Temp}),
    .bcd(Temp_bcd),
    .done(Temp_done)
);

bin2bcd bin2bcd_Humi(
    .clk(clk),
    .rst(~rst_n),
    .bin({12'b0, Humi}),
    .bcd(Humi_bcd),
    .done(Humi_done)
);

//ACK Edge Test
reg Tx_ACK_last;
reg Tx_ACK_Edge;
always @(posedge clk) Tx_ACK_last = Tx_ACK;
always @(*) begin
    if(!Tx_ACK_last && Tx_ACK)
        Tx_ACK_Edge <= 1'b1;
    else
        Tx_ACK_Edge <= 1'b0;
end

//Send Data Control
//reg tx_delay;
always @(posedge clk) begin
    tx_delay[0] <= state_change ||  Tx_ACK_Edge;
    tx_delay[1] <= tx_delay[0];
end

always @(posedge clk)begin
    if(tx_delay && tx_cnt < tx_total)
        EN_Tx <= 1'b1;
    else
        EN_Tx <= 1'b0;
end

always @(posedge clk) begin
    Tx_Data[0] <= tx_buf[tx_cnt<<3];
    Tx_Data[1] <= tx_buf[(tx_cnt<<3) + 1];
    Tx_Data[2] <= tx_buf[(tx_cnt<<3) + 2];
    Tx_Data[3] <= tx_buf[(tx_cnt<<3) + 3];
    Tx_Data[4] <= tx_buf[(tx_cnt<<3) + 4];
    Tx_Data[5] <= tx_buf[(tx_cnt<<3) + 5];
    Tx_Data[6] <= tx_buf[(tx_cnt<<3) + 6];
    Tx_Data[7] <= tx_buf[(tx_cnt<<3) + 7];
    if(state_change)begin
        tx_cnt <= 6'd0;
    end
    else if(Tx_ACK_Edge)
        tx_cnt <= tx_cnt + 1'b1;
end

//Send State Control
always @(posedge clk) begin
    case (crt_state)
        idle:
        begin
            tx_total <= 6'd0;
            tx_buf <= 512'b1;
            I1_bcd_reg <= I1_bcd;
            I2_bcd_reg <= I2_bcd;
            I3_bcd_reg <= I3_bcd;
            Ih_bcd_reg <= Ih_bcd;
        end
        I1_send:
        begin
            if(state_change)begin
                tx_total <= 6'd15;
                tx_buf[(6<<3) + 7: (0<<3)] <= "n2.val=";
                tx_buf[(7<<3) + 7: (7<<3)] <= I1_bcd_reg[19:16] + 8'h30;
                tx_buf[(8<<3) + 7: (8<<3)] <= I1_bcd_reg[15:12] + 8'h30;
                tx_buf[(9<<3) + 7: (9<<3)] <= I1_bcd_reg[11:8] + 8'h30;
                tx_buf[(10<<3) + 7: (10<<3)] <= I1_bcd_reg[7:4] + 8'h30;
                tx_buf[(11<<3) + 7: (11<<3)] <= I1_bcd_reg[3:0] + 8'h30;
                tx_buf[(14<<3) + 7: (12<<3)] <= 24'hffffff;
            end
        end
        I2_send:
        begin
            if(state_change)begin
                tx_total <= 6'd15;
                tx_buf[(6<<3) + 7: 0<<3] <= "n3.val=";
                tx_buf[(7<<3) + 7: 7<<3] <= I2_bcd_reg[19:16] + 8'h30;
                tx_buf[(8<<3) + 7: 8<<3] <= I2_bcd_reg[15:12] + 8'h30;
                tx_buf[(9<<3) + 7: 9<<3] <= I2_bcd_reg[11:8] + 8'h30;
                tx_buf[(10<<3) + 7: 10<<3] <= I2_bcd_reg[7:4] + 8'h30;
                tx_buf[(11<<3) + 7: 11<<3] <= I2_bcd_reg[3:0] + 8'h30;
                tx_buf[(14<<3) + 7: 12<<3] <= 24'hffffff;
            end
        end
        I3_send:
        begin
            if(state_change)begin
                tx_total <= 6'd15;
                tx_buf[(6<<3) + 7: 0<<3] <= "n4.val=";
                tx_buf[(7<<3) + 7: 7<<3] <= I3_bcd_reg[19:16] + 8'h30;
                tx_buf[(8<<3) + 7: 8<<3] <= I3_bcd_reg[15:12] + 8'h30;
                tx_buf[(9<<3) + 7: 9<<3] <= I3_bcd_reg[11:8] + 8'h30;
                tx_buf[(10<<3) + 7: 10<<3] <= I3_bcd_reg[7:4] + 8'h30;
                tx_buf[(11<<3) + 7: 11<<3] <= I3_bcd_reg[3:0] + 8'h30;
                tx_buf[(14<<3) + 7: 12<<3] <= 24'hffffff;
            end
        end
        Ih_send:
        begin
            if(state_change)begin
                tx_total <= 6'd15;
                tx_buf[(6<<3) + 7: 0<<3] <= "n5.val=";
                tx_buf[(7<<3) + 7: 7<<3] <= Ih_bcd_reg[19:16] + 8'h30;
                tx_buf[(8<<3) + 7: 8<<3] <= Ih_bcd_reg[15:12] + 8'h30;
                tx_buf[(9<<3) + 7: 9<<3] <= Ih_bcd_reg[11:8] + 8'h30;
                tx_buf[(10<<3) + 7: 10<<3] <= Ih_bcd_reg[7:4] + 8'h30;
                tx_buf[(11<<3) + 7: 11<<3] <= Ih_bcd_reg[3:0] + 8'h30;
                tx_buf[(14<<3) + 7: 12<<3] <= 24'hffffff;
            end
        end
        Temp_send:
        begin
            if(state_change)begin
                tx_total <= 6'd12;
                tx_buf[(6<<3) + 7: 0<<3] <= "n6.val=";
                tx_buf[(7<<3) + 7: 7<<3] <= Temp_bcd_reg[7:4] + 8'h30;
                tx_buf[(8<<3) + 7: 8<<3] <= Temp_bcd_reg[3:0] + 8'h30;
                tx_buf[(11<<3) + 7: 9<<3] <= 24'hffffff;
            end
        end
        Humi_send:
        begin
            if(state_change)begin
                tx_total <= 6'd12;
                tx_buf[(6<<3) + 7: 0<<3] <= "n7.val=";
                tx_buf[(7<<3) + 7: 7<<3] <= Humi_bcd_reg[7:4] + 8'h30;
                tx_buf[(8<<3) + 7: 8<<3] <= Humi_bcd_reg[3:0] + 8'h30;
                tx_buf[(11<<3) + 7: 9<<3] <= 24'hffffff;
            end
        end
        auto_send:
        begin
            if(state_change)begin
                tx_buf[(6<<3) + 7: 0<<3] <= "h0.val=";
                tx_buf[(7<<3) + 7: 7<<3] <= auto_in + 8'h30;
                tx_buf[(10<<3) + 7: 8<<3] <= 24'hffffff;
                tx_buf[(19<<3) + 7: 11<<3] <= "t13.txt=\"";
                if(auto_in)begin
                    tx_buf[(22<<3) + 7: 20<<3] <= "on\"";
                    tx_buf[(25<<3) + 7: 23<<3] <= 24'hffffff;
                    tx_total <= 6'd26;
                end
                else begin
                    tx_buf[(23<<3) + 7: 20<<3] <= "off\"";
                    tx_buf[(26<<3) + 7: 24<<3] <= 24'hffffff;
                    tx_total <= 6'd27;
                end
            end
        end
    endcase
end

//Receive Data Control
always @(posedge clk) begin
    if(state_change)begin
        rx_cnt <= 0;
        change_state <= 0;
    end
    else if(Rx_ACK)begin
        rx_cnt <= rx_cnt + 1;
        rx_buf[(rx_cnt<<3)] <= Rx_Data[0];
        rx_buf[(rx_cnt<<3) + 1] <= Rx_Data[1];
        rx_buf[(rx_cnt<<3) + 2] <= Rx_Data[2];
        rx_buf[(rx_cnt<<3) + 3] <= Rx_Data[3];
        rx_buf[(rx_cnt<<3) + 4] <= Rx_Data[4];
        rx_buf[(rx_cnt<<3) + 5] <= Rx_Data[5];
        rx_buf[(rx_cnt<<3) + 6] <= Rx_Data[6];
        rx_buf[(rx_cnt<<3) + 7] <= Rx_Data[7];
    end
    if(rx_cnt[3] || delay_cnt >= delay)begin
        change_state <= 1'b1;
    end
end

//Receive State Control
always @(posedge clk ) begin
    case (crt_state)
        auto_rev:
        begin
            if(rx_cnt[3]) begin
                auto_out <= rx_buf[0];
            end
        end 
    endcase
end

endmodule // UART_HMI