//Module Name: dht11
//Author: Li Lixing
//Made for DHT11 temperature and humidity sensor

module dht11(
						i_clk,
						i_rst_n,
						io_data,
					   o_temp,
						o_humi,
						o_state
							);

input i_clk;//50MHz clock
input i_rst_n;//Low for reset
inout io_data;//dht_data
output reg [7:0]o_temp;//Temperature
output reg [7:0]o_humi;//Humidity
reg o_data;//output data

output wire[1:0]o_state;


reg [39:0]get_data;//40 bits of data
reg [5:0]data_num;//data count
reg[3:0]crt_state;//curent state
reg [3:0]next_state;
parameter idle		= 4'b0001;
parameter init		= 4'b0010;
parameter ans 		= 4'b0100;
parameter rd_data	= 4'b1000;


assign o_state = crt_state;
//============State Register============
always@(posedge i_clk or negedge i_rst_n )
				if(!i_rst_n)
						crt_state<=idle;
				else
						crt_state<=next_state;


reg data_sam1;//sample 1
reg data_sam2;//sample 2

reg data_pluse;//Edge test
always@(posedge i_clk )
begin
	data_sam1<=io_data;
	data_sam2<=data_sam1;
	data_pluse<=(~data_sam2)&data_sam1;
end
reg[31:0] cnt_1s;//time count for 1 second 
always@(posedge i_clk or negedge i_rst_n )
	if(!i_rst_n)
		cnt_1s <= 0;	
	else if(cnt_1s == 32'd9999_9999)
		cnt_1s <= 0;
    else
		cnt_1s <= cnt_1s + 1'b1;
//============Next State Logic============
always@( *) 
		case(crt_state)
				idle:if(cnt_1s == 32'd9999_9999 )//Wait for 2 seconds
								next_state = init;
							else
								next_state = crt_state;
				
				init:if(cnt_1s >= 32'd100_2000 )//20ms+40us
								next_state = ans;
							else
								next_state = crt_state;
				
				ans:if(data_pluse)//Edge
						next_state = rd_data;
					//else if(cnt_1s==32'd9999_9999 )
					   //next_state=idle;
					else
						next_state = crt_state;
				
				rd_data:if(data_num == 6'd40)//Has received 40 bits
							next_state = idle;
					   //else if(cnt_1s==32'd9999_9999 )
                            //next_state=idle;
						else
							next_state = crt_state;
				default:next_state = idle;
		endcase
		
reg [12:0]cnt_40us;//Time counter for 40us
reg send_indi;//data_IO_Control
reg r_hold;//High voltage hold for 40us
always@(posedge i_clk)
	if(crt_state[1] && (cnt_1s <= 27'd100_0000))//20ms low voltage
		begin
			o_data <= 1'b0;
			send_indi <= 1'b1;
		end
	else if(crt_state[1])//40us high voltage
		begin
			o_data <= 1'b1;
			send_indi <= 1'b0;
		end
	else if(crt_state[2] & data_pluse)//clear data
		begin
			data_num <= 6'd0;
		end
	else if(crt_state[3] & (data_pluse | r_hold))//Data judge and in
				begin
					r_hold <= 1'b1;
					cnt_40us <= cnt_40us+1'b1;
					if(cnt_40us == 12'd2000)//Test for 40us?28us for low<40us<70us for high
						begin
							r_hold <= 1'b0;
							if(io_data)
								get_data <= {get_data[38:0],1'b1};
							else
								get_data <= {get_data[38:0],1'b0}; 
							cnt_40us <= 12'd0;
							data_num <= data_num+1'b1;
						end
				end
	else
		begin
			if(data_num == 6'd40)//Has got 40 bits
				begin
					o_humi <= get_data[39:32];
					o_temp <= get_data[23:16];
				end
		end		

assign io_data = send_indi ? o_data : 1'bz;//io_data

endmodule