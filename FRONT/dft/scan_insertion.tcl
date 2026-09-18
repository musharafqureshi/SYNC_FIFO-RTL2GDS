#---------------------------------------------------------------#
#                                                               #
#                  TESSENT SCAN INSERTION                       #
#                                                               #
#---------------------------------------------------------------#

#===============================================================#
#       DFT SCAN INSERTION                                      #
#===============================================================#

set_logfile_handling logs/scan_insertion.log -rep

set_context dft -scan

read_verilog rtl/fifo_noscan.v
read_cell_library libs/slow_vdd1v0.mdt
read_sdc constraints/fifo.sdc


set_current_design

# Analyze clocks/resets/test controls
analyze_control_signals -auto_fix

# Enable test clock insertion
set_test_logic -clock on


# DFT analysis mode
set_system_mode analysis


#set_scan_insertion_options -si_port_format "SI_%d"
#set_scan_insertion_options -so_port_format "SO_%d"

add_scan_mode int_mode -type internal -chain_length 50 -chain_count 3 -single_power_domain_chains on 

analyze_scan_chains

# DFT rule checking
#check_design_rules

# Insert scan chains
insert_test_logic

write_scan_order outputs/fifo.scandef 

# Verify scan insertion
report_scan_chains
#verify_scan_chain

# Write scan inserted netlist
write_design -output_file outputs/fifo_scan.v -rep

# Generate ATPG setup files
write_atpg_setup outputs/fifo_scan_testproc -procfile -rep

exit

#---------------------------------------------------------------#
# END OF FLOW
#---------------------------------------------------------------#
