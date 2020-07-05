## Package the design

source $filelists_path/core_pack_scripts.f

foreach core $core_pack_scripts {
    lassign $core core_name core_root pack_script
    puts "Packaging Core $core_name with script $pack_script"
    source $pack_script
}