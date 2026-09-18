
read_libs libs/slow_vdd1v0_basicCells.lib
read_hdl rtl/fifo.v
elaborate
check_design -unresolved
read_sdc constraints/fifo.sdc

set_db syn_generic_effort medium
set_db syn_map_effort high 
set_db syn_opt_effort high

#set_dont_use [get_lib_cell */DFFQ*]
#set_dont_use [get_lib_cell */DFFHQ*]
#set_dont_use [get_lib_cell */DFFX*]
#set_dont_use [get_lib_cell */DFFTR*]
#set_dont_use [get_lib_cell */EDFF*]
set_dont_use [get_lib_cell */SMDFF*]
set_dont_use [get_lib_cell */SDFF*]
set_dont_use [get_lib_cell */MDFF*]

syn_generic
syn_map
syn_opt

write_hdl > netlist/fifo_noscan.v
write_sdc > constraints/fifo_syn.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge  -setuphold split > delays.sdf

report area > reports/area.rpt
report power > reports/power.rpt
report gates > reports/gates.rpt
report summary > reports/summary.rpt

