source scripts/reg_gen/reg_rtl_structures.tcl     

## Global signals
set CLK                  "clk"
set RST                  "reset_n"
set WE_SIGNAL            "write_enable"
set WRITE_DATA_SIGNAL    "write_data"
set READ_DATA_SIGNAL     "read_data"
set ADDRESS_READ_SIGNAL  "read_addr"
set ADDRESS_WRITE_SIGNAL "write_addr"

proc generate_rtl_registers {module_name registers output_directory} {
  if {$module_name == ""} {
    puts "ERROR: No module name specified!"
    return
  }
  puts "------------------------------------"
  puts "Generating registers for $module_name"
  puts "------------------------------------"
  set inputs   [list]
  set outputs  [list]
  set mux_data [list]
  set reg_body ""
  foreach {reg addr} $registers {
    global $reg
    array  set new_reg [array get $reg]
    set    reg_name   [dict get $reg name]
    set    reg_fields [dict get $reg fields]
    puts   "Reg = $reg_name | Addr = $addr"

    set readback [list]

    append reg_body "  /////////////////////////\n"
    append reg_body "  //  Register $reg_name\n"
    append reg_body "  //  Address  [format "'h%0x" $addr]\n"
    append reg_body "  /////////////////////////\n\n"

    ## Generate all the register fields
    foreach {name field} $reg_fields {
      set     reg_generator "gen_[dict get $field type]"
      lassign [$reg_generator $field [format "'h%0x" $addr]] curr_body curr_inputs curr_outputs curr_readback curr_write
      append  reg_body $curr_body
      append  reg_body "\n\n"
      lappend inputs   [list $name $curr_inputs]
      lappend outputs  [list $name $curr_outputs]
      lappend readback $curr_readback
    }

    lappend mux_data $readback $addr $reg_name
  }

  set reg_read_mux [generate_read_mux $mux_data]
  set reg_top_io   [generate_top_io $inputs $outputs]
  set reg_module   [generate_reg_module $module_name $reg_top_io $reg_body $reg_read_mux]

  ## Write to output
  if {![file exists $output_directory]} {
    file mkdir $output_directory
  }
  set fp [open "${output_directory}/${module_name}.sv" w]
  puts $fp $reg_module
  close $fp
}
