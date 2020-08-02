puts "Running Register Generation"

source $filelists_path/core_reg_maps.f

foreach core $core_reg_maps {
    lassign $core core_name core_root reg_map
    puts "Generating registers for core $core_name"
    puts "Register map = $reg_map"
    source $reg_map

    foreach {module_name regs} $registers {
      puts "Generating $module_name"
      generate_rtl_registers $module_name $regs "${core_root}/gen"
    }
}