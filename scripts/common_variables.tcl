## FPGA Part Variables
set ZYBO_FPGA_PART_NUMBER "xc7z010clg400-1"

## Project Name Variables
set project_name               audio_sampler
set packaged_ip_project_name   ${project_name}_pack
set integrated_ip_project_name ${project_name}_integ
set workspace_project_name     ${integrated_ip_project_name}_sdk_ws

## Project Path Variables
set project_root               [pwd]
set results_dir                "${project_root}/results"
set generated_ip_path          "${results_dir}/generated_ip"
set packaged_ip_project_path   "${results_dir}/${packaged_ip_project_name}"
set integrated_ip_project_path "${results_dir}/${integrated_ip_project_name}"
set worskpace_project_path     "${results_dir}/${workspace_project_name}"

## File list variables
set rtl_file_list         ${project_root}/scripts/rtl_filelist.f
set constraints_file_list ${project_root}/scripts/constraints_filelist.f
set collateral_ip_list    ${project_root}/scripts/collateral_ip_filelist.f

## Packaged Project Variables
set packaged_ip_dirname   "packaged_ip"
set packaged_ip_ver       0.1
set packaged_ip_name      ${project_name}
set packaged_ip_disp_name ${packaged_ip_name}_v${packaged_ip_ver}
set packaged_ip_root_dir  ${results_dir}/${packaged_ip_dirname}

## Block Design Variables
set block_design_name "audio_sampler_block_design"
set block_design_hdf  ${block_design_name}_wrapper.hdf
set MAX_VOICES        64

## SDK Design Variables
set processor        "ps7_cortexa9_0"
set hw_project_name  "codec_${processor}"
set sdk_project_name "codec_fw"
set fw_source_path   ${project_root}/source/fw/
