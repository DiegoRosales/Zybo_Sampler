source scripts/reg_gen/rtl_reg_gen_utils.tcl     
source scripts/reg_gen/uvm_reg_gen_utils.tcl     

puts "Running Register Generation"

source $project_regmap
source $filelists_path/core_reg_maps.f

## Global signals
set SIG_PARAMS {
  CLK                  "clk"
  RST                  "reset_n"
  WE_SIGNAL            "write_enable"
  WRITE_DATA_SIGNAL    "write_data"
  READ_DATA_SIGNAL     "read_data"
  ADDRESS_READ_SIGNAL  "read_addr"
  ADDRESS_WRITE_SIGNAL "write_addr"
}

foreach core $core_reg_maps {
    lassign $core core_name core_root reg_map
    puts "Generating registers for core $core_name"
    puts "Register map = $reg_map"
    source $reg_map

    set reg_model_info {}
    if [info exists reg_blocks] {
      foreach {module_name reg_block} $reg_blocks {
        puts "Generating $module_name"
        generate_rtl_registers      $module_name $reg_block "${core_root}/gen" $SIG_PARAMS
        lappend reg_model_info [generate_uvm_register_model $module_name $reg_block "${core_root}/gen"]
      }
    } else {
      puts "\[ERROR\] - There are no register blocks defined for $core_name"
    }

    generate_uvm_register_pkg $reg_model_info $global_regmap ${project_root}/source/common/gen
}