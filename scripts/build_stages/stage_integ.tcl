## Integrate the design

set    integ_script [file normalize ${project_integ_script}]
puts   "Integrating project using script $integ_script"
source $integ_script
if {[file exists ${integ_project_dir}/integ_gen_rtl_filelist.f]} {
    file copy -force ${integ_project_dir}/integ_gen_rtl_filelist.f ${filelists_path}/integ_gen_rtl_filelist.f
}
if {[file exists ${integ_project_dir}/integ_gen_xci_filelist.f]} {
    file copy -force ${integ_project_dir}/integ_gen_xci_filelist.f ${filelists_path}/integ_gen_xci_filelist.f
}