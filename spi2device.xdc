# Clock
set_property IOSTANDARD LVCMOS33 [get_ports {osc_clk}]
set_property PACKAGE_PIN H4 [get_ports {osc_clk}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {osc_clk}]

# Reset
set_property IOSTANDARD LVCMOS33 [get_ports {rst_n}]
set_property PACKAGE_PIN D14 [get_ports {rst_n}]

# SPI
set_property IOSTANDARD LVCMOS33 [get_ports {spi_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_out}]
set_property IOSTANDARD LVCMOS33 [get_ports {spi_fss}]
set_property PACKAGE_PIN H14 [get_ports {spi_clk}]
set_property PACKAGE_PIN P2 [get_ports {spi_in}]
set_property PACKAGE_PIN L14 [get_ports {spi_out}]
set_property PACKAGE_PIN M13 [get_ports {spi_fss}]

# Auto
set_property PACKAGE_PIN D13 [get_ports {auto}]
set_property IOSTANDARD LVCMOS33 [get_ports {auto}]

# EN_3V3
set_property IOSTANDARD LVCMOS33 [get_ports {EN_3V3}]
set_property PACKAGE_PIN L13 [get_ports {EN_3V3}]

# LEDs
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN J1 [get_ports {led[0]}]
set_property PACKAGE_PIN A13 [get_ports {led[1]}]

# Step Motor Control
set_property IOSTANDARD LVCMOS33 [get_ports {step_dir}]
set_property IOSTANDARD LVCMOS33 [get_ports {step_pul}]
set_property PACKAGE_PIN N14 [get_ports {step_dir}]
set_property PACKAGE_PIN M14 [get_ports {step_pul}]

# DHT
set_property IOSTANDARD LVCMOS33 [get_ports {out_Data}]
set_property PACKAGE_PIN E11 [get_ports {out_Data}]
set_property PULLUP true [get_ports {out_Data}]
set_property IOSTANDARD LVCMOS33 [get_ports {in_Data}]
set_property PACKAGE_PIN P5 [get_ports {in_Data}]
set_property PULLUP true [get_ports {in_Data}]

# GP2Y10
#set_property IOSTANDARD LVCMOS33 [get_ports {o_adc_clk}]
#set_property PACKAGE_PIN C5 [get_ports {o_adc_clk}]
#set_property IOSTANDARD LVCMOS33 [get_ports {adc_en}]
#set_property PACKAGE_PIN J4 [get_ports {adc_en}]
#set_property IOSTANDARD LVCMOS33 [get_ports {led_en}]
#set_property PACKAGE_PIN N14 [get_ports {led_en}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_adc_data[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_adc_data[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_adc_data[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_adc_data[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_adc_data[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_adc_data[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_adc_data[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {i_adc_data[7]}]
#set_property PACKAGE_PIN J3 [get_ports {i_adc_data[0]}]
#set_property PACKAGE_PIN J2 [get_ports {i_adc_data[1]}]
#set_property PACKAGE_PIN D12 [get_ports {i_adc_data[2]}]
#set_property PACKAGE_PIN E12 [get_ports {i_adc_data[3]}]
#set_property PACKAGE_PIN F12 [get_ports {i_adc_data[4]}]
#set_property PACKAGE_PIN C11 [get_ports {i_adc_data[5]}]
#set_property PACKAGE_PIN H11 [get_ports {i_adc_data[6]}]
#set_property PACKAGE_PIN H12 [get_ports {i_adc_data[7]}]

# bh1750(I2C)
set_property IOSTANDARD LVCMOS33 [get_ports {o_i2c_scl}]
set_property PACKAGE_PIN P12 [get_ports {o_i2c_scl}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_i2c_sda}]
set_property PACKAGE_PIN P13 [get_ports {io_i2c_sda}]
set_property PULLUP true [get_ports {io_i2c_sda}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_i2c_en}]
set_property PACKAGE_PIN N4 [get_ports {o_i2c_en}]
