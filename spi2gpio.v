//Module Name: spi2device
//Author: Li Lixing
//Based on the demo project of spi2gpio(https://github.com/sea-s7/Demo_project/tree/master/spi2gpio)
`define REG_ADDR_SZ		5
`define __LED_SEG		0

module spi2device (
	// common
	input osc_clk,
	input rst_n,

	// spi
	input spi_clk,
	input spi_fss,
	input spi_in,
	output spi_out,

	//EN_3V3
	output EN_3V3,

	//dht
	inout Data,

	//Light
	output o_i2c_scl,
	inout io_i2c_sda1,
	inout io_i2c_sda2,
	output o_i2c_en,
	
	//Motor
	output motor_scl,
	inout motor_sda,
	
	//RGB LED
	output RGB_LED_tri_o,
	output [5:0]RGB,
	
	//UART for esp32
	input esp_tx,
	output uart_tx,
	output esp_rx,
	input uart_rx,
	
	output [1:0]led
);
    /* UART */
    assign uart_tx = esp_tx;
    assign esp_rx = uart_rx;
	/* global clock */
	reg clk;
	reg auto;
	assign o_i2c_en = 1;
	assign led[0] = auto;
	assign led[1] = 1;

	/* a half frequency as global clock */
	always @(posedge osc_clk) begin
		clk = ~clk;
	end

	assign EN_3V3 = 0;

`ifdef OLD_SPI_OUT_R
	reg spi_out_r;
`else
	wire spi_out_r;
`endif
	reg spi_in_r;
	reg spi_clk_r;
	reg spi_fss_r;

	reg  [7:0] spi_snd;
	wire [7:0] spi_rcv;

	/* dht */

/* ===========================================================================*/
/* SPI clock sync to high frequency clock */
/* ===========================================================================*/
	wire sclk;
	wire sfss;
	wire sin;

	assign sclk = spi_clk_r;
	assign sfss = spi_fss_r;
	assign sin = spi_in_r;
	assign spi_out = (!spi_fss)? spi_out_r: 1'bz;

	always @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			spi_clk_r <= 0;
		else
			spi_clk_r <= spi_clk;
	end

	always @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			spi_in_r <= 0;
		else
			spi_in_r <= spi_in;
	end

	always @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			spi_fss_r <= 1;
		else
			spi_fss_r <= spi_fss;
	end

/* ===========================================================================*/
/* SPI logic shifting in/out */
/* ===========================================================================*/
	reg [1:0] sync_r;
	wire cycle_sample;
	wire cycle_wr;
	wire cycle_rd;
	wire cycle_state;
	wire cycle_load;
	wire cycle_clear;

	assign cycle_wr    = cycle_sample;
	assign cycle_rd    = cycle_sample;
	assign cycle_state = sync_r[0];
	assign cycle_load  = sync_r[0];
	assign cycle_clear = sync_r[0];

	reg sfss_l;
	reg sclk_l;
	always @(negedge rst_n or posedge clk) begin
		if (!rst_n) begin
			sfss_l <= 1'b1;
			sclk_l <= 1'b0;
		end else begin
			sfss_l <= sfss;
			sclk_l <= sclk;
		end
	end
	/*
	wire sfss_l = spi_fss_r;
	wire sclk_l = spi_clk_r;
	*/

	reg [9:0] shift_cntr;
	always @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			shift_cntr <= 10'd1;
		else if (cycle_clear)
			shift_cntr <= 10'd1;
		else if (sfss == 0) begin
			if (sfss_l != sfss)//ss_Down_Edge_Test
				shift_cntr <= 10'd1;
			else if (sclk != 0 && sclk_l != sclk)//sclk_Up_Edge_Test
				shift_cntr <= {shift_cntr[8:0], 1'b0};
		end
	end

	reg [8:0] shift_r;
	assign spi_rcv = shift_r[8:1];

	always @(negedge rst_n or posedge clk) begin//Send_Part
		if (!rst_n)
			shift_r <= 9'd0;
		else if (cycle_load) begin//Load Send Data
			shift_r <= {spi_snd, 1'b0};
		end else if (!sfss && sclk != 0 && sclk != sclk_l) begin//sclk_Up_Edge_Test
			// shift in the received bit from LSB.
			shift_r <= {shift_r[7:0], sin};
		end
	end

`ifdef OLD_SPI_OUT_R
	wire w;
	always @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			spi_out_r <= 0;
		else if (sclk == 0) begin
			spi_out_r <= shift_r[8];
		end
	end
`else
	assign spi_out_r = shift_r[8];
`endif

	always @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			sync_r[1] <= 0;
		else
			sync_r[1] <= sync_r[0];
	end

	wire byte_rcv;
	assign byte_rcv = shift_cntr[9];

	reg byte_rcv_l;
	always @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			byte_rcv_l <= 1;
		else
			byte_rcv_l <= byte_rcv;
	end

	assign cycle_sample = byte_rcv_l == 0 && byte_rcv != 0 && sync_r == 2'b0;
	always @(negedge rst_n or posedge clk) begin
		if (!rst_n)
			sync_r[0] <= 0;
		else begin
			sync_r[0] <= 0;
			if (cycle_sample)
				sync_r[0] <= 1;
		end
	end

/* ===========================================================================*/
/* SPI ADDRESS/DATA BYTE switch */
/* ===========================================================================*/
	parameter spi_st_addr = 1'b0,
		spi_st_data = 1'b1;

	reg spi_st;

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			spi_st <= spi_st_addr;
		else if (cycle_state) begin
			case (spi_st)
			spi_st_addr: spi_st <= spi_st_data;
			spi_st_data: spi_st <= spi_st_addr;
			default: spi_st <= spi_st_addr;
			endcase;
		end
		else if (sfss_l != sfss && sfss != 0) begin
			/*
			 * return to register addressing state
			 * if this device unselected.
			 */
			spi_st <= spi_st_addr;
		end
	end

	/* spi_wr/wr_addr use spi_st_addr's data */
	reg  [`REG_ADDR_SZ - 1:0] wr_addr;
	reg spi_wr_r;
	wire spi_wr = cycle_wr && spi_st == spi_st_data && spi_wr_r;
	/* spi_wdata      use spi_st_data's data */
	wire [7:0] spi_wdata;

	/* spi_rd/rd_addr use spi_st_addr's data */
	wire [`REG_ADDR_SZ - 1:0] rd_addr;
	wire spi_rd = cycle_rd && spi_st == spi_st_addr && ~spi_rcv[7];
/*
	always @(posedge clk) begin
		gpa_oe = 8'hff;
		gpa_odata = {wr_addr, spi_wr_r};
	end
*/

/* ===========================================================================*/
/* DHT */
/* ===========================================================================*/

	wire [7:0] Humi, Temp;
	dht11 dht(
		.i_clk(clk),
		.i_rst_n(rst_n),
		.io_data(Data),
		.o_temp(Temp),
		.o_humi(Humi)
	);

/* ===========================================================================*/
/* bh1750 */
/* ===========================================================================*/	

    wire [15:0] I1_data, I2_data, I3_data, Ih_data;
    wire [1:0]state;
    bh1750_IIC bh(
        .clk(osc_clk),
        .rst_n(rst_n),
        .I1_data(I1_data),
        .I2_data(I2_data),
        .I3_data(I3_data),
        .Ih_data(Ih_data),
        .c_state(state),
        .IIC_SCL(o_i2c_scl),
        .IIC_SDA1(io_i2c_sda1),
        .IIC_SDA2(io_i2c_sda2)
    );
    
    wire [15:0]Is, It, Ia, Ip;
    Illumination_Cal Illumination_Cal_0 (
      .clk(osc_clk),                                // input wire clk
      .Illumination1(I1_data),            // input wire [15 : 0] Illumination1
      .Illumination2(I2_data),            // input wire [15 : 0] Illumination2
      .Illumination3(I3_data),            // input wire [15 : 0] Illumination3
      .Illumination_H(Ih_data),          // input wire [15 : 0] Illumination_H
      .Illumination_S(Is),          // output wire [15 : 0] Illumination_S
      .Illumination_T(It),          // output wire [15 : 0] Illumination_T
      .Illumination_Alpha(Ia),  // output wire [15 : 0] Illumination_Alpha
      .Illumination_Phi(Ip)      // output wire [15 : 0] Illumination_Phi
    );
    
    reg [15:0]Is_reg,It_reg,Ia_reg,Ip_reg;
    
    reg [5:0]bh_time_cnt = 0;
    always @(posedge clk)begin
        if(state != 0)
            bh_time_cnt <= 0;
        else begin
            if(bh_time_cnt != 6'b111111)
                bh_time_cnt <= bh_time_cnt + 1;
            else begin
                Is_reg <= Is;
                It_reg <= It;
                Ia_reg <= Ia;
                Ip_reg <= Ip;
            end
        end
    end

/* ===========================================================================*/
/* Motor */
/* ===========================================================================*/

reg [5:0]sw = 0;
Motor_Control(
    .clk_100MHz(osc_clk),
    .IIC_SDA(motor_sda),
    .IIC_SCL(motor_scl),
    .func(sw)
);	
/* ===========================================================================*/
/* LED_Control */
/* ===========================================================================*/	

LED_Control_0 LED_Control_0_1 (
  .RGB_LED_tri_o(RGB_LED_tri_o),  // output wire RGB_LED_tri_o
  .RGB(RGB),                      // output wire [5 : 0] RGB
  .clk_100MHz(osc_clk),        // input wire clk_100MHz
  .sw(sw)                        // input wire [5 : 0] sw
);

/* ===========================================================================*/
/* Logic Processor */
/* ===========================================================================*/    

    
    reg [7:0]data = 8'hff;
/* ===========================================================================*/
/* SPI REGISTER WRITE */
/* ===========================================================================*/
	/*
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			spi_wdata = 0;
		end else if (cycle_sample && spi_st == spi_st_data) begin
			spi_wdata = spi_rcv;
		end
	end
	*/
	assign spi_wdata = spi_rcv;

	/* SAVING WRITING ADDRESS */
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			spi_wr_r <= 0;
			wr_addr <= 0;
		end else if (cycle_sample && spi_st == spi_st_addr) begin
			spi_wr_r  <= spi_rcv[7];
			wr_addr <= spi_rcv[`REG_ADDR_SZ - 1:0];
		end
	end

	/* register writing */
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin

		end 
		else if (spi_wr) begin
			case (wr_addr)
			     'h01:sw <= spi_wdata[7:1];
				 'h02:auto <= spi_wdata[1];
				 'h03:data <= spi_wdata;
			default: ;
			endcase
		end
	end

/* ===========================================================================*/
/* SPI REGISTER READ */
/* ===========================================================================*/
	assign rd_addr = spi_rcv[`REG_ADDR_SZ - 1:0];
	`define SPI_DUMMY	8'h5A

	/* register reading */
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			spi_snd <= `SPI_DUMMY;
		else if (cycle_rd && spi_st == spi_st_data)
			// when command phase, spi output with SPI_DUMMY
			spi_snd <= `SPI_DUMMY;
		else if (spi_rd) begin
			case (rd_addr)
            'h01: spi_snd <= {3'b000,sw};
			'h02: spi_snd <= {7'b0,auto};
			'h03: spi_snd <= data;
			'h10: spi_snd <= Temp;//Outside Temperature
			'h11: spi_snd <= Humi;//Outside Humidity
			'h12: spi_snd <= Is[15:8];
			'h13: spi_snd <= Is[7:0];
			'h14: spi_snd <= It[15:8];
			'h15: spi_snd <= It[7:0];
			'h16: spi_snd <= Ia[15:8];
			'h17: spi_snd <= Ia[7:0];
			'h18: spi_snd <= Ip[15:8];
			'h19: spi_snd <= Ip[7:0];
            
			default: spi_snd <= 8'h0;
				/*
				 * debuging only
				 * {spi_rd, 4'h0, rd_addr};
				 * {spi_wr, 4'h0, wr_addr};
				 */
			endcase
		end
	end

endmodule
