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
report_utilization -hierarchical -file fpga/reports/util_hier.rpt

set_property LOC MMCME2_ADV_X1Y1 [get_cells u_clk_wiz/inst/mmcm_adv_inst]

opt_design

set mmcm_cell [get_cells -quiet u_clk_wiz/inst/mmcm_adv_inst]
if {[llength $mmcm_cell] == 0} {
    puts "ERROR: mmcm cell not found at u_clk_wiz/inst/mmcm_adv_inst. Adjust path and retry."
    return
}

# show where the IBUF is
set ibuf_cells [get_cells -quiet u_clk_wiz/inst/clkin1_ibufg]
if {[llength $ibuf_cells] == 0} {
    puts "WARN: clkin1_ibufg not found; continuing but check your cell names."
} else {
    puts "IBUF LOC: [get_property LOC $ibuf_cells]"
}

set mmcms [get_sites -filter {SITE_TYPE == MMCME2_ADV}]
if {[llength $mmcms] == 0} {
    puts "ERROR: no MMCME2_ADV sites found on device."
    return
}

puts "Found [llength $mmcms] MMCME2_ADV sites. Will try them in order."
set success 0
set tried 0
set results {}

foreach site $mmcms {
    incr tried
    puts "\n--- Attempt $tried: trying site $site ---"

    catch {set_property LOC -unset $mmcm_cell} errmsg

    catch {set_property LOC $site $mmcm_cell} setres
    puts "Set MMCM LOC -> $site"

    catch {write_checkpoint -force before_place_${site}.dcp} werr

    if {[catch {place_design} place_err_msg]} {
        puts "place_design FAILED for $site"
        if {[file exists "vivado.log"]} {
            set fh [open "vivado.log" r]
            set logdata [read $fh]
            close $fh
            if {[string length $logdata] > 4000} {
                set tail [string range $logdata [expr {[string length $logdata] - 4000}] end]
            } else {
                set tail $logdata
            }
            puts "---- vivado.log tail for $site ----"
            puts $tail
            puts "---- end vivado.log tail ----"
        } else {
            puts "vivado.log not found in current directory"
        }

        lappend results [list site $site status FAIL reason $place_err_msg]
        catch {set_property LOC -unset $mmcm_cell} ignore
        continue
    } else {
        puts "place_design SUCCEEDED for $site"
        set success 1
        lappend results [list site $site status PASS]
        write_checkpoint -force after_place_success_${site}.dcp
        break
    }
}

puts "\n=== SUMMARY ==="
puts "Tried: $tried sites. Success: $success"
foreach r $results {
    if {[lsearch -exact $r PASS] >= 0} {
        puts "PASS: [lindex $r 1]"
    } else {
        puts "FAIL: [lindex $r 1]"
    }
}
puts "=== END SUMMARY ==="

if {!$success} {
    puts "\nAll MMCM site trials failed. Last placer output was printed above for each attempted site. Recommended next steps:"
    puts "- Verify the IOB pin you used is a clock-capable pin (CCIO/MRCC)."
    puts "- Verify the port has a PACKAGE_PIN assignment in your XDC; if the pin is locked by board constraints, consider changing the board pin."
    puts "- As last resort, consider the CLOCK_DEDICATED_ROUTE override (see your XDC) but only after STA verification."
}

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
