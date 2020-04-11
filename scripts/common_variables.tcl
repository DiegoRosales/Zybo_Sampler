## FPGA Part Variables
set ZYBO_FPGA_PART_NUMBER  "xc7z010clg400-1"
set ZYBO_BOARD_PART_NUMBER "digilentinc.com:zybo:part0:1.0"

## Xilinx variables
#set vivado_install_path        $::env(XILINX_VIVADO)
#set vivado_interface_path      ${vivado_install_path}/data/ip/interfaces

## Project Path Variables
set results_dir                "${project_root}/results"
set xilinx_ip_tcl_path         "${results_dir}/${gen_xilinx_ip_tcl_dirname}"
set xilinx_ip_xci_path         "${results_dir}/${gen_xilinx_ip_xci_dirname}"
set project_impl_path          "${results_dir}/${project_name}"
set workspace_project_path     "${results_dir}/${workspace_project_name}"

## Packaged cores variables
set packaged_cores_dirname "${results_dir}/packaged_cores"

## Project integration variables
set integ_project_dir    ${results_dir}/${integ_project_name}

## Block Design Variables
set block_design_name "audio_sampler_block_design"
set block_design_hdf  ${block_design_name}_wrapper.hdf

## Vitis SDK Design Variables
set processor              "ps7_cortexa9_0"
set platform_project_name  "${project_name}_platform"
set app_project_name       "${project_name}_app"
set fw_source_path          ${project_root}/source/fw/
