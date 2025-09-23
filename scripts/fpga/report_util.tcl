open_checkpoint ./scripts/fpga/reports/synth.dcp

report_utilization -hierarchical -file scripts/fpga/reports/util_hier.rpt
report_utilization -hierarchical -hierarchical_depth 2 -file scripts/fpga/reports/util_depth2.rpt
report_utilization -file scripts/fpga/reports/util_summary.rpt
report_utilization -cells [get_cells -hierarchical -filter {REF_NAME == CARRY4}] -file scripts/fpga/reports/util_carry4.rpt