##################################################
## Script to generate UVM Register models
##################################################

set uvm_reg_function_new_template {
  function new(string name = "${class_name}");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction: new
}

set uvm_reg_block_function_new_template {
  function new(string name = "${class_name}");
    super.new(name, UVM_NO_COVERAGE);
  endfunction: new
}

set register_config_template {
    // Field name: ${field_name}\[$field_msb:$field_lsb\]
    this.${field_name} = uvm_reg_field::type_id::create("${field_name}", , get_full_name());
    this.${field_name}.configure(this, ${field_size}, ${field_lsb}, "${field_access}", ${field_volatile}, ${field_reset}, ${field_has_reset}, ${field_is_rand}, ${field_individually_accessible});
}

set register_block_config_template {
    // Register name: ${reg_name}, Address: ${reg_addr}
    this.${reg_name} = ${reg_class}::type_id::create("${reg_name}", , get_full_name());
    this.${reg_name}.configure(this, null, "");
    this.${reg_name}.build();
    this.default_map.add_reg(this.${reg_name}, ${reg_addr}, "RW", 0);
}

set uvm_reg_class_name_template       {${reg_name}_uvm_reg}
set uvm_reg_block_class_name_template {${reg_block_name}_uvm_reg_block}

proc generate_uvm_register {reg addr} {
    ## Templates
    global uvm_reg_function_new_template
    global register_config_template
    global uvm_reg_class_name_template

    ## Get the fields
    set    reg_name    [dict get $reg name]
    set    reg_fields  [dict get $reg fields]

    ## UVM variables
    set class_name [subst $uvm_reg_class_name_template]

    append output_str "/////////////////////////\n"
    append output_str "//  Register $class_name\n"
    append output_str "//  Address  [format "'h%0x" $addr]\n"
    append output_str "/////////////////////////\n"
    ## Create the class
    append output_str "class ${class_name} extends uvm_reg;\n\n"
    append output_str "  `uvm_object_utils(${class_name})\n\n"

    ## Declare the fields
    append output_str "  // Register fields\n"
    foreach {name field} $reg_fields {
      append output_str "  rand uvm_reg_field [dict get $field rtl_name];\n"
    }

    ## Function new
    append output_str [subst $uvm_reg_function_new_template]
    append output_str "\n\n"
    append output_str "  function build();"
    foreach {name field} $reg_fields {
      set field_name                    [dict get $field rtl_name]
      set field_size                    [expr 1 + [dict get $field msb] - [dict get $field lsb]];
      set field_msb                     [dict get $field msb];
      set field_lsb                     [dict get $field lsb];
      set field_access                  "RW";
      set field_volatile                0;
      set field_reset                   "1'b0";
      set field_has_reset               1;
      set field_is_rand                 0;
      set field_individually_accessible 0;
      append output_str [subst $register_config_template]
    }
    append output_str "  endfunction: build\n"

    ## Append the register field information
    append output_str "endclass: ${class_name}\n\n"

    return $output_str
}

proc generate_register_block {module_name register_blocks} {
  ## Templates
  global uvm_reg_block_function_new_template
  global register_block_config_template
  global uvm_reg_class_name_template
  global uvm_reg_block_class_name_template

  set reg_block_name $module_name
  set class_name [subst $uvm_reg_block_class_name_template]

  ## Create the class
  append output_str "//////////////////////////////////////\n"
  append output_str "// UVM Register Block\n"
  append output_str "// Block Name: ${class_name}\n"
  append output_str "//////////////////////////////////////\n"
  append output_str "class $class_name extends uvm_reg_block;\n\n"
  append output_str "  `uvm_object_utils($class_name)\n\n"

  ## Declare the registers
  append output_str "  // Registers\n"
  # Calculate the spaces for left justification
  set max_len 0
  foreach {reg addr} $register_blocks { 
    set reg_name  [dict get $reg name]
    if {$max_len < [string length [subst $uvm_reg_class_name_template]]} {
      set max_len [string length [subst $uvm_reg_class_name_template]]
    }
  }
  # Write the registers
  foreach {reg addr} $register_blocks {
    set reg_name  [dict get $reg name]
    set reg_class [subst $uvm_reg_class_name_template]

    append output_str [format "  rand %-${max_len}s %s;\n" ${reg_class} ${reg_name}]
    #"  rand ${reg_class} ${reg_name};\n"
  }

  append output_str [subst $uvm_reg_block_function_new_template]
  append output_str "\n\n"
  append output_str "  function build();\n"
  append output_str "    this.default_map = create_map(\"\", 0, 4, UVM_LITTLE_ENDIAN, 1);\n"

  ## Configure the registers
  foreach {reg addr} $register_blocks {
    set reg_name  [dict get $reg name]
    set reg_class [subst $uvm_reg_class_name_template]
    set reg_addr  [expr $addr * 2 * 2]
    append output_str [subst $register_block_config_template]
  }

  append output_str "\n"
  append output_str "  endfunction: build\n"

  append output_str "endclass: $class_name\n"

  return $output_str
}


## Generate UVM register package
proc generate_uvm_register_model {module_name register_block output_directory} {
  global uvm_reg_block_class_name_template

  if {$module_name == ""} {
    puts "ERROR: No module name specified!"
    return
  }
  puts "------------------------------------"
  puts "Generating UVM Register Model for $module_name"
  puts "Filename: ${output_directory}/${module_name}_uvm_reg_model.sv"
  puts "------------------------------------"

  set reg_block_name $module_name
  set output_str ""
  foreach {reg addr} $register_block {
    append output_str [generate_uvm_register $reg $addr]
  }
  append output_str [generate_register_block $module_name $register_block]

  ## Write to output
  if {![file exists $output_directory]} {
    file mkdir $output_directory
  }
  set fp [open "${output_directory}/${module_name}_uvm_reg_model.sv" w]
  puts $fp $output_str
  close $fp

  set reg_model_info "file_name ${module_name}_uvm_reg_model.sv reg_block_class_name [subst $uvm_reg_block_class_name_template]"

  return $reg_model_info
}

## Generate UVM Register Package
proc generate_uvm_register_pkg {reg_model_info regmap output_directory} {

  set pkg_name [dict get $regmap name]

  puts "------------------------------------"
  puts "Generating UVM Register Model Package for $pkg_name"
  puts "Register model file name: ${output_directory}/${pkg_name}_uvm_reg_model.sv"
  puts "Package file name:        ${output_directory}/${pkg_name}_uvm_reg_pkg.sv"
  puts "------------------------------------"

  ## Generate the register block with all the sub-blocks
  set reg_block ""
  foreach {name addr} [dict get $regmap map] {
    append reg_block "{ name ${name} } $addr "
  }

  set output_str [generate_register_block $pkg_name $reg_block]

  if {[file exists ${output_directory}] == 0} {
    file mkdir ${output_directory}
  }

  set fp [open "${output_directory}/${pkg_name}_uvm_reg_model.sv" w]
  puts $fp $output_str
  close $fp

  ## Generate the register package
  set output_str "// Register package\n"
  append output_str "package ${pkg_name}_uvm_reg_pkg;\n"
  append output_str "  import uvm_pkg::*;\n"
  append output_str "  `include \"uvm_macros.svh\";\n\n"
  append output_str "  // Include all the register models\n"

  foreach model_info $reg_model_info {
    append output_str "  `include \"[subst [dict get $model_info file_name]]\"\n"
  }
  append output_str "  `include \"${pkg_name}_uvm_reg_model.sv\"\n\n"

  append output_str "endpackage: ${pkg_name}_uvm_reg_pkg\n"

  set fp [open "${output_directory}/${pkg_name}_uvm_reg_pkg.sv" w]
  puts $fp $output_str
  close $fp
}