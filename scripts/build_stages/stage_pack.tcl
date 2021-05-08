## Package the design

foreach core $proj_utils::cores {
  ## Write a debug filelist with all the scripts
  proj_utils::write_compiled_filelists -core_info $proj_utils::cores \
                                       -output_dir ${results_dir}/filelists \
                                       -override \
                                       -variables core_pack_script
  
  ## Run the pack script
  if {[dict exists $core core_pack_script]} {
    set core_root   [dict get $core core_root]
    set core_name   [dict get $core core_name]
    set pack_script [dict get $core core_pack_script]
    puts "Packaging Core $core_name with script $pack_script"
    source $pack_script
  }
}