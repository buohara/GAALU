set_part xc7a100tcsg324-1

read_verilog ../rtl/ga_pkg.sv
read_verilog ../rtl/ga_alu_even.sv
read_verilog ../rtl/fpga_test_wrapper.sv
read_verilog ../rtl/fpga_top.sv
read_verilog ../rtl/uart_controller.sv

set_property file_type SystemVerilog [get_files *.sv]
set_param general.maxThreads 2

read_xdc ../config/constraints.xdc

set_property top fpga_top [current_fileset]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz
set_property -dict [list \
  CONFIG.CLKIN1_JITTER_PS {50.0} \
  CONFIG.CLKOUT1_USED {true} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
  CONFIG.CLKOUT2_USED {false} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {10.000} \
  CONFIG.MMCM_CLKIN1_PERIOD {10.000} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {10.000} \
] [get_ips clk_wiz]

generate_target all [get_ips clk_wiz]
synth_ip [get_ips clk_wiz]

synth_design -top fpga_top -part xc7a100tcsg324-1
write_checkpoint -force fpga/reports/synth.dcp
report_utilization -file fpga/reports/synth_util.rpt
report_timing_summary -file fpga/reports/synth_timing.rpt
report_utilization -cells [get_cells -hierarchical -filter {REF_NAME == CARRY4}] -file fpga/reports/util_carry4.rpt

opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force impl.dcp

report_utilization -file fpga/reports/impl_util.rpt
report_timing_summary -file fpga/reports/impl_timing.rpt
report_drc -file fpga/reports/impl_drc.rpt

write_bitstream -force fpga_top.bit
puts "Bitstream generated: fpga_top.bit"

exit
