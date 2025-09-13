create_project gaalu_proj ./gaalu_proj -part xc7a100tcsg324-1
add_files {../rtl/ga_alu_even.sv}
add_files -fileset constrs_1 ../config/constraints.xdc
set_property top top_module [current_fileset]
update_compile_order -fileset sources_1
launch_runs synth_1
wait_on_run synth_1
launch_runs impl_1
wait_on_run impl_1
launch_runs write_bitstream -jobs 4
wait_on_run write_bitstream_1
exit