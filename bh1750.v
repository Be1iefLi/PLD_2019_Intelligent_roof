//Driver for bh1750 by using I2C

module bh1750(
    input               i_clk,//50Mhz
    input               i_rst_n,//reset pin
    output  reg[15:0]   o_data,//Illumination Data
    output  reg         o_i2c_scl,//I2C scl
    inout               io_i2c_sda//I2C sda
);

//Time Count
localparam  cnt_2_5us = 'd124,
            cnt_5us = 'd249,
            cnt_200ms = 'd999_9999,
            cnt_2s = 'd9999_9999;

reg [27:0] sec_cnt;
reg [23:0] time_cnt;

//State
reg [3:0] crt_state;
reg [3:0] next_state;
localparam  idle = 4'h0,
            w_start = 4'h1,
            w_adr_send = 4'h2,
            w_adr_ask = 4'h3,
            w_instr_send = 4'h4,
            w_instr_ask = 4'h5,
            w_stop = 4'h6,
            r_wait = 4'h7,
            r_start = 4'h8,
            r_adr_send = 4'h9,
            r_adr_ask = 4'ha,
            r_high_byte_rev = 4'hb,
            r_high_byte_ask = 4'hc,
            r_low_byte_rev = 4'hd,
            r_low_byte_ask = 4'he,
            r_stop = 4'hf;

//Send/Receive Control
reg[3:0] send_rev_cnt;
reg start_ask;
reg stop;
//=============State Register=============
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        crt_state <= 0;
    else
        crt_state <= next_state;
end

//=============Time Count=============
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        sec_cnt <= 0;
    else if(sec_cnt == 'd10)
        sec_cnt <= 0;
    else 
        sec_cnt <= sec_cnt + 1'b1;
end

//=============Next State Logic=============
localparam send_rev_bits = 4'd9;
always @(*) begin
    case (crt_state)
        idle: 
            begin
                if(sec_cnt == 'd10)//Wait for 2 seconds
                    next_state = w_start;
                else
                    next_state = idle;
            end
        w_start: 
            begin
                if(start_ask)
                    next_state = w_adr_send;
                else
                    next_state = w_start;
            end
        w_adr_send:
            begin
                if(send_rev_cnt == send_rev_bits)
                    next_state = w_adr_ask;
                else
                    next_state = w_adr_send;
            end
        w_adr_ask:
            begin
                if(start_ask)
                    next_state = w_instr_send;
                else
                    next_state = w_adr_ask;
            end
        w_instr_send:
            begin
                if(send_rev_cnt == send_rev_bits)
                    next_state = w_instr_ask;
                else
                    next_state = w_instr_send;
            end
        w_instr_ask:
            begin
                if(start_ask)
                    next_state = w_stop;
                else
                    next_state = w_instr_ask;
            end
        w_stop:
            begin
                if(stop)
                    next_state = r_wait;
                else
                    next_state = w_stop;
            end
        r_wait:
            begin
                if(time_cnt == cnt_200ms)
                    next_state = r_start;
                else
                    next_state = r_wait;
            end
        r_start:
            begin
                if(start_ask)
                    next_state = r_adr_send;
                else
                    next_state = r_start;
            end
        r_adr_send:
            begin
                if(send_rev_cnt == send_rev_bits)
                    next_state = r_adr_ask;
                else 
                    next_state = r_adr_send;
            end
        r_adr_ask:
            begin
                if(start_ask)
                    next_state = r_high_byte_rev;
                else
                    next_state = r_adr_ask;
            end
        r_high_byte_rev:
            begin
                if(send_rev_cnt == send_rev_bits)
                    next_state = r_high_byte_ask;
                else
                    next_state = r_high_byte_rev;
            end
        r_high_byte_ask:
            begin
                if(start_ask)
                    next_state = r_low_byte_rev;
                else
                    next_state = r_high_byte_ask;
            end
        r_low_byte_rev:
            begin
                if(send_rev_cnt == send_rev_bits)
                    next_state = r_low_byte_ask;
                else
                    next_state = r_low_byte_rev;
            end
        r_low_byte_ask:
            begin
                if(start_ask)
                    next_state = r_stop;
                else
                    next_state = r_low_byte_rev;
            end
        r_stop:
            begin
                if(stop)
                    next_state <= idle;
                else
                    next_state <= r_stop;
            end
        default: next_state = idle;
    endcase  
end

//=============State Logic Output=============
reg sda_dir;//direction:0 for send and 1 for receive
reg sda_out;//sda_out
reg sda_ask;//ask judge
reg [7:0]send_rev_data;
reg [15:0]data = 16'hffff;

localparam  address = 7'b010_0011,
            instruction = 8'b0010_0000;

always @(posedge i_clk) begin
    case (crt_state)
        idle:
            begin
                time_cnt <= 0;
                start_ask <= 0;
                stop <= 1;
                send_rev_cnt <= 0;
                o_i2c_scl <= 1;
                sda_dir <= 0;
                sda_out <= 1;
                send_rev_data <= 8'hff;
                sda_ask <= 0;
                o_data <= data;
            end
        w_adr_send:
            begin
                sda_dir <= 0;
                if(start_ask) begin
                    send_rev_data <= {address, 1'b0};
                    o_i2c_scl <= 0;
                    time_cnt <= 0;
                    send_rev_cnt <= 0;
                    start_ask <= 0;
                end
                else if(time_cnt == cnt_5us) begin
                    o_i2c_scl <= ~o_i2c_scl;
                    time_cnt <= 0;
                end
                else
                    time_cnt <= time_cnt + 1;
                if((time_cnt == cnt_2_5us) & ~o_i2c_scl)begin
                    sda_out <= send_rev_data[7];
                    send_rev_data <= {send_rev_data[6:0], 1'b1};
                    send_rev_cnt <= send_rev_cnt + 1;
                end
            end
        w_instr_send:
            begin
                sda_dir <= 0;
                if(start_ask) begin
                    send_rev_data <= instruction;
                    o_i2c_scl <= 0;
                    time_cnt <= 0;
                    send_rev_cnt <= 0;
                    start_ask <= 0;
                end
                else if(time_cnt == cnt_5us) begin
                    o_i2c_scl <= ~o_i2c_scl;
                    time_cnt <= 0;
                end
                else
                    time_cnt <= time_cnt + 1;
                if((time_cnt == cnt_2_5us) & ~o_i2c_scl)begin
                    sda_out <= send_rev_data[7];
                    send_rev_data <= {send_rev_data[6:0], 1'b1};
                    send_rev_cnt <= send_rev_cnt + 1;
                end
            end
        r_wait:
            begin
                sda_dir <= 0;
                sda_out <= 1;
                o_i2c_scl <= 1;
                if(stop) begin
                    stop <= 0;
                    time_cnt <= 0;
                    start_ask <= 0;   
                end
            end
        r_adr_send:
            begin
                sda_dir <= 0;
                if(start_ask) begin
                    send_rev_data <= {address, 1'b1};
                    o_i2c_scl <= 0;
                    time_cnt <= 0;
                    send_rev_cnt <= 0;
                    start_ask <= 0;
                end
                else if(time_cnt == cnt_5us) begin
                    o_i2c_scl <= ~o_i2c_scl;
                    time_cnt <= 0;
                end
                else
                    time_cnt <= time_cnt + 1;
                if((time_cnt == cnt_2_5us) & ~o_i2c_scl)begin
                    sda_out <= send_rev_data[7];
                    send_rev_data <= {send_rev_data[6:0], 1'b1};
                    send_rev_cnt <= send_rev_cnt + 1;
                end
            end
        r_high_byte_ask:
            begin
                sda_dir <= 0;
                if(send_rev_cnt == send_rev_bits) begin
                    send_rev_cnt <= 0;
                    o_i2c_scl <= 0;
                    stop <= 0;
                    sda_out <= 0;
                    time_cnt <= 0;
                    data[15:8] <= send_rev_data;
                end
                else
                    time_cnt <= time_cnt + 1;
                if(time_cnt == cnt_5us)
                    o_i2c_scl <= 1;
                if(time_cnt == (cnt_5us + cnt_5us + 1))
                    start_ask <= 1;
            end
        r_low_byte_ask:
            begin
                sda_dir <= 0;
                if(send_rev_cnt == send_rev_bits) begin
                    send_rev_cnt <= 0;
                    o_i2c_scl <= 0;
                    stop <= 0;
                    sda_out <= 0;
                    time_cnt <= 0;
                    data[7:0] <= send_rev_data;
                end
                else
                    time_cnt <= time_cnt + 1;
                if(time_cnt == cnt_5us)
                    o_i2c_scl <= 1;
                if(time_cnt == (cnt_5us + cnt_5us + 1))
                    start_ask <= 1;
            end

        //==============Start Part==============
        w_start,r_start:
            begin
                sda_dir <= 0;
                o_i2c_scl <= 1;
                if(stop) begin
                    stop <= 0;
                    time_cnt <= 0;
                    start_ask <= 0;
                    sda_out <= 0;
                    send_rev_cnt <= 0;
                end
                else 
                    time_cnt <= time_cnt + 1;
                if(time_cnt == cnt_5us)
                    start_ask <= 1;
            
            end
        //==============Send Part==============
        /*w_adr_send,w_instr_send,r_adr_send:
            begin
                sda_dir <= 0;
                if(start_ask) begin
                    o_i2c_scl <= 0;
                    time_cnt <= 0;
                    send_rev_cnt <= 0;
                    start_ask <= 0;
                    send_rev_data <= 8'hff;
                end
                else if(time_cnt == cnt_5us) begin
                    o_i2c_scl <= ~o_i2c_scl;
                    time_cnt <= 0;
                end
                else
                    time_cnt <= time_cnt + 1;
                if((time_cnt == cnt_2_5us) & ~o_i2c_scl)begin
                    sda_out <= send_rev_data[7];
                    send_rev_data <= {send_rev_data[6:0], 1'b1};
                    send_rev_cnt <= send_rev_cnt + 1;
                end
            end*/
        //==============Send Ask Part==============
        w_adr_ask,w_instr_ask,r_adr_ask:
            begin
                sda_dir <= 1;
                if(send_rev_cnt == send_rev_bits) begin
                    time_cnt <= 0;
                    sda_ask <= 0;
                    send_rev_cnt <= 0;
                    start_ask <= 0;
                end
                if((time_cnt == (cnt_5us + cnt_2_5us + 1))&sda_ask)
                    start_ask <= 1;
                else
                    time_cnt <= time_cnt + 1;
                if(time_cnt == cnt_2_5us)
                    o_i2c_scl <= 1;
                if(!io_i2c_sda)
                    sda_ask <= 1;
            end
        //==============Receive Part==============
        r_high_byte_rev,r_low_byte_rev:
            begin
                sda_dir <= 1;
                if(start_ask) begin
                    time_cnt <= 0;
                    start_ask <= 0;
                    o_i2c_scl <= 0;
                    send_rev_data <= 8'hff;
                    send_rev_cnt <= 0;
                end
                else if(time_cnt == cnt_5us) begin
                    o_i2c_scl <= ~o_i2c_scl;
                    time_cnt <= 0;
                    if(!o_i2c_scl) begin
                        send_rev_data <= {send_rev_data[6:0], io_i2c_sda};
                        send_rev_cnt <= send_rev_cnt + 1;
                    end
                    if(o_i2c_scl & (send_rev_cnt == 4'd8))
                        send_rev_cnt <= send_rev_bits;
                end
                else
                    time_cnt <= time_cnt + 1;  
            end
        //==============Receive Ask Part==============
        /*r_high_byte_ask,r_low_byte_ask:
            begin
                sda_dir <= 0;
                if(send_rev_cnt == send_rev_bits) begin
                    send_rev_cnt <= 0;
                    o_i2c_scl <= 0;
                    stop <= 0;
                    sda_out <= 0;
                    time_cnt <= 0;
                end
                else
                    time_cnt <= time_cnt + 1;
                if(time_cnt == cnt_5us)
                    o_i2c_scl <= 1;
                if(time_cnt == (cnt_5us + cnt_5us + 1)) begin
                    start_ask <= 1;
                end
            end*/
        //==============Stop Part==============
        w_stop,r_stop:
            begin
                sda_dir <= 0;
                if(start_ask) begin
                    time_cnt <= 0;
                    o_i2c_scl <= 0;
                    start_ask <= 0;
                    sda_out <= 1;
                end
                else
                    time_cnt <= time_cnt + 1;
                if(time_cnt == (cnt_5us + cnt_5us + 1))
                    stop <= 1;
                if(time_cnt == cnt_5us)
                    o_i2c_scl <= 1;
                if(time_cnt == cnt_2_5us)
                    sda_out <= 0;
                if(time_cnt == (cnt_2_5us + cnt_5us + 1))
                    sda_out <= 1;
            end
    endcase
end

assign io_i2c_sda = sda_dir? 1'bz: sda_out;

endmodule // bh1750
