//Module Name: Step_Control
//Author: Li Lixing
//Using for the control of Step Motor with the help of TB6600

module Step_Control(
    input clk,//100MHz
    input rst_n,
    input [2:0]speed,
    input [4:0]openess,
    output reg dir,
    output reg pul
);

//==============Clock Devider==============
localparam time_1ms = 'd9_999;
reg [15:0] cnt_1ms;
reg clk_1KHz;
reg [2:0] cnt;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_1ms <= 0;
        clk_1KHz <= 0;
        cnt <= 0;
    end
    else if(cnt_1ms == time_1ms) begin
        cnt_1ms <= 0;
        if(cnt == (3'd5 - speed)) begin
            clk_1KHz <= ~clk_1KHz;
            cnt <= 0;
        end
        else
            cnt <= cnt + 1;
    end
    else
        cnt_1ms <= cnt_1ms + 1;
end

//Position Control
reg [18:0]  crt_pos = 0,
            next_pos = 0;
always @(posedge clk) next_pos <= {openess , 14'b0} + {openess , 12'b0};

always @(posedge clk_1KHz) begin
    if(crt_pos < next_pos) begin
        dir <= 1;
        pul <= ~pul;
        crt_pos <= crt_pos + 1;
    end
    else if(crt_pos > next_pos)begin
        dir <= 0;
        pul <= ~pul;
        crt_pos <= crt_pos - 1;
    end
end

endmodule // Step_Control