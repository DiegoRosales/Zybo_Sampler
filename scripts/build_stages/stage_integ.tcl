## Integrate the design

if {[dict exists $project_cfg project_integ_script]} {
  set    integ_script [file normalize [subst [dict get $project_cfg project_integ_script]]]
  puts   "Integrating project using script $integ_script"
  source $integ_script

  if {[info exists integ_output]} {
    foreach key [dict keys $integ_output] {
      set filelist [dict get $integ_output $key]
      if {[file exists $filelist]} {
        puts "Copying $filelist to ${filelists_path}"
        file copy -force $filelist ${filelists_path}
      }
    }
  }
}