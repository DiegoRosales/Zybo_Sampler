## Generate all the Xilinx IPs
set generated_xilinx_ips ""
source $filelists_path/xilinx_ip_tcl.f
# IPs from the integration phase
if {[file exists ${filelists_path}/integ_gen_xci_filelist.f]} {
    source ${filelists_path}/integ_gen_xci_filelist.f
    lappend generated_xilinx_ips [generate_xilinx_ips_xci -ip_list $integ_gen_xci_filelist -part_number $ZYBO_FPGA_PART_NUMBER -board_part ${ZYBO_BOARD_PART_NUMBER} -dest_dir ${xilinx_ip_xci_path}]
}

# IPs from TCL scripts
lappend generated_xilinx_ips [generate_xilinx_ips_tcl -ip_list [join $xilinx_ip_tcl]  -part_number $ZYBO_FPGA_PART_NUMBER -dest_dir $xilinx_ip_tcl_path]
write_filelist -filelist [join $generated_xilinx_ips] -list_name "all_gen_xci_filelist" -description "Generated XCI Files" -output $filelists_path/all_gen_xci_filelist.f