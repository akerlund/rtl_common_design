set top        "axi4s_mux_rr_demux"
set output_dir "./vivado_synth"
set fpga_part  "7z020clg484-1"

file mkdir $output_dir

read_verilog  [ glob ./*.sv ]

synth_design -top $top -part $fpga_part

write_checkpoint      -force $output_dir/post_synth.dcp
report_timing_summary -file $output_dir/post_synth_timing_summary.rpt
report_utilization    -file $output_dir/post_synth_util.rpt