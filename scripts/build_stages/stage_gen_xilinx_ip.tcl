###################################
## Generate all XCI IPs from the integration phase
###################################
generate_xilinx_ips_xci -ip_list ${filelists_path}/integ_gen_xci_filelist.f.json -part_number $FPGA_PART_NUMBER -board_part  ${BOARD_PART_NUMBER} -dest_dir ${xilinx_ip_xci_path} -output_list gen_xci_list
###################################
## Generate all XCI IPs from TCL scripts
###################################
generate_xilinx_ips_tcl -core_info $proj_utils::cores -part_number $FPGA_PART_NUMBER -dest_dir $xilinx_ip_tcl_path -output_list gen_xci_tcl_list -override

###################################
## Generate a filelist with all xci files
###################################
parse_json_cfg -cfg_file $gen_xci_list     -output gen_xci_filelist -override -debug
parse_json_cfg -cfg_file $gen_xci_tcl_list -output xci_tcl_filelist -override -debug
set xci_filelist [list {*}[dict get $gen_xci_filelist syn_xci_filelist] {*}[dict get $xci_tcl_filelist syn_tcl_xci_filelist]]
write_filelist -filelist $xci_filelist -description "Synthesis XCI Filelist" -list_name "synthesis_xci_file_list" -output "${filelists_path}/synthesis_xci_file_list.f.json"