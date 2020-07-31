module bin2bcd(
    input clk,
    input rst,
    input [19:0]bin,
    output reg [19:0]bcd,
    output reg done
);
localparam  idle = 2'b00,
            op = 2'b01,
            finish = 2'b10;

reg [1:0] crt_state,next_state;
reg [19:0] p2s;
reg [4:0] cnt;
reg [3:0] bcd4_reg, bcd3_reg, bcd2_reg, bcd1_reg, bcd0_reg;
wire [3:0] bcd4_temp, bcd3_temp, bcd2_temp, bcd1_temp, bcd0_temp;

always @(posedge clk or posedge rst) begin
    if(rst)
        crt_state <= 0;
    else
        crt_state <= next_state;
end

always @(*) begin
    case (crt_state)
        idle:
            next_state = op;
        op:
            begin
                if(cnt == 5'd0)
                    next_state = finish;
                else
                    next_state = op;
            end
        finish:
            next_state = idle;
        default: next_state = idle;
    endcase
end

always @(posedge clk) begin
    case (crt_state)
        idle:
            begin
                p2s <= bin;
                cnt <= 5'd19;
                bcd0_reg <= 0;
                bcd1_reg <= 0;
                bcd2_reg <= 0;
                bcd3_reg <= 0;
                bcd4_reg <= 0;
            end 
        op:
            begin
                done <= 0;
                cnt <= cnt - 1'b1;
                p2s <= p2s << 1;
                bcd0_reg <= {bcd0_temp[2:0], p2s[15]};
                bcd1_reg <= {bcd1_temp[2:0], bcd0_temp[3]};
                bcd2_reg <= {bcd2_temp[2:0], bcd1_temp[3]};
                bcd3_reg <= {bcd3_temp[2:0], bcd2_temp[3]};
                bcd4_reg <= {bcd4_temp[2:0], bcd3_temp[3]};
            end
        finish:
            begin
                done <= 1;
                bcd <= {bcd4_reg, bcd3_reg, bcd2_reg, bcd1_reg, bcd0_reg};
            end
    endcase
end

assign bcd0_temp = (bcd0_reg > 4)? bcd0_reg + 4'h3: bcd0_reg;
assign bcd1_temp = (bcd1_reg > 4)? bcd1_reg + 4'h3: bcd1_reg;
assign bcd2_temp = (bcd2_reg > 4)? bcd2_reg + 4'h3: bcd2_reg;
assign bcd3_temp = (bcd3_reg > 4)? bcd3_reg + 4'h3: bcd3_reg;
assign bcd4_temp = (bcd4_reg > 4)? bcd4_reg + 4'h3: bcd4_reg;

endmodule // bin2bcd