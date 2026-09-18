set_logfile_handling logs/edt.log -rep

set_context dft -edt

read_verilog outputs/fifo_scan.v

read_cell_library libs/slow_vdd1v0.mdt

set_current_design sync_fifo

add_black_box -auto

dofile outputs/fifo_scan_testproc.dofile

tessent_scan_setup

set_edt_options -channels 3

check_design_rules

report_edt_pins
 
report_edt_configurations

report_edt_lockup_cells

write_edt_files edt/created -verilog -replace -synthesis_script RTL_Compiler 


exit

