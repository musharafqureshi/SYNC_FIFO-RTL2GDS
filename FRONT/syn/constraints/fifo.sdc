create_clock -name clk_i -period 4 -waveform {0 2} [get_ports clk_i]

set_clock_transition -rise 0.2 [get_clocks clk_i]
set_clock_transition -fall 0.2 [get_clocks clk_i]

set_clock_uncertainty -setup 0.2 [get_clocks clk_i]
set_clock_uncertainty -hold 0.2 [get_clocks clk_i]

set_input_delay -max 1.6 [get_ports {rst_i wr_en_i rd_en_i}] -clock [get_clocks clk_i]
set_input_delay -min 0.4 [get_ports {rst_i wr_en_i rd_en_i}] -clock [get_clocks clk_i]

set_input_delay -max 1.6 [get_ports {wr_data_i[*]}] -clock [get_clocks clk_i]
set_input_delay -min 0.4 [get_ports {wr_data_i[*]}] -clock [get_clocks clk_i]

set_output_delay -max 1.6 [get_ports {rd_data_o[*] full_o empty_o error_o}] -clock [get_clocks clk_i]
set_output_delay -min 0.4 [get_ports {rd_data_o[*] full_o empty_o error_o}] -clock [get_clocks clk_i]

set_driving_cell -lib_cell BUFX2 [get_ports {rst_i wr_en_i rd_en_i wr_data_i[*]}]

set_load 0.05 [get_ports {rd_data_o[*] full_o empty_o error_o}]
