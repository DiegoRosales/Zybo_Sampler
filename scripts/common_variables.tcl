## Project Name Variables
set project_name               audio_sampler
set packaged_ip_project_name   ${project_name}_pack
set integrated_ip_project_name ${project_name}_integ

## Project Path Variables
set project_root [pwd]
set packaged_ip_project_path   "${project_root}/${packaged_ip_project_name}"
set integrated_ip_project_path "${project_root}/${integrated_ip_project_name}"

## File list variables
set rtl_file_list         scripts/rtl_filelist.f
set constraints_file_list scripts/constraints_filelist.f

## Packaged Project Variables
set packaged_ip_dirname   "packaged_ip"
set packaged_ip_ver       0.1
set packaged_ip_name      ${project_name}
set packaged_ip_disp_name ${packaged_ip_name}_v${packaged_ip_ver}
set packaged_ip_root_dir  ${project_root}/${packaged_ip_dirname}
