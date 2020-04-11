

namespace eval pack_utils {
  ## Core
  variable core_revision
  ## RTL Top
  variable rtl_top
  variable top_file
  variable include_files
  ## Interface
  variable current_interface
  variable current_interface_xml
  variable current_interface_vlnv
  ##
  variable loaded_bus_def
}

proc pack_utils::init {args} {
  array set my_arglist {
    "project_name"      {"store"    ""       "required"   0}
    "project_dir"       {"store"    ""       "required"   0}
    "part_number"       {"store"    ""       "required"   0}
    "revision"          {"store"    ""       "required"   0}
    "vendor"            {"store"    ""       "required"   0}
    "library"           {"store"    ""       "required"   0}
    "rtl_filelist"      {"store"    ""       "required"   0}
  }

  set status [arg_parser my_arglist parsed_args args]

  if {$status != 0} {
    puts "ERROR: There was an error processing the arguments"
    return 1
  }

  puts "Initializing packager"
  ## Core
  set pack_utils::core_revision              $parsed_args(revision)
  ## RTL Top
  set pack_utils::rtl_top                    ""
  set pack_utils::top_file                   ""
  set pack_utils::include_files              ""
  ## Interface
  set pack_utils::current_interface          ""
  set pack_utils::current_interface_xml      ""
  set pack_utils::current_interface_vlnv     ""
  ##
  set pack_utils::loaded_bus_def             ""

  ## Create the project
  puts "Creating project"
  set project_location $parsed_args(project_dir)/$parsed_args(project_name)
  create_project $parsed_args(project_name) \
                 ${project_location} \
                 -part $parsed_args(part_number) \
                 -force

  ## Add the RTL files
  foreach rtl_file $parsed_args(rtl_filelist) {
    puts "Adding file ${rtl_file}"
    add_files -norecurse ${rtl_file} -scan_for_includes
  }

  ## Package the project
  puts "Packaging the Core"
  ipx::package_project -root_dir $parsed_args(project_dir) \
                       -vendor $parsed_args(vendor) \
                       -library $parsed_args(library) \
                       -taxonomy /UserIP \
                       -import_files \
                       -set_current false

  ## Load the core
  ipx::open_core $parsed_args(project_dir)/component.xml

  puts "Removing auto-inferred stuff..."
  ## Remove all auto-inferred interfaces
  foreach interface [ipx::get_bus_interfaces] {
    set interface_name [lindex $interface 2]
    puts "Removing interface $interface_name"
    ipx::remove_bus_interface $interface_name [ipx::current_core]
  } 

  ## Remove all auto-inferred memory maps
  ipx::remove_all_memory_map    [ipx::current_core]
  ipx::remove_all_address_space [ipx::current_core]

  ## Set core revision
  puts "Setting core revision to $pack_utils::core_revision"
  set_property core_revision $pack_utils::core_revision [ipx::current_core]
}

proc pack_utils::load_interface_def { args } {
    array set my_arglist {
        "vendor"            {"store"    ""       "optional"   0}
        "library"           {"store"    ""       "optional"   0}
        "name"              {"store"    ""       "optional"   0}
        "version"           {"store"    ""       "optional"   0}
        "vlnv"              {"store"    ""       "optional"   0}
        "xml"               {"store"    ""       "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    if {$parsed_args(vendor) != ""} {
        set vlnv "$parsed_args(vendor):$parsed_args(library):$parsed_args(name):$parsed_args(version)"
    } elseif {$parsed_args(vlnv) != ""} {
        set vlnv $parsed_args(vlnv)
    }
}

## List all loaded bus definitions
proc pack_utils::list_loaded_bus_def {} {
    foreach bus_def $pack_utils::loaded_bus_def {
        set busabs_vlnv [lindex $bus_def 1]
        set busdef_xml  [lindex $bus_def 2]
        puts "$busdef_xml -- $busabs_vlnv"
    }
}

## Instantiate an instance
proc pack_utils::create_interface_instance { args } {
    array set my_arglist {
        "instance_name"     {"store"    ""       "required"   1}
        "vendor"            {"store"    ""       "required"   0}
        "library"           {"store"    ""       "required"   0}
        "name"              {"store"    ""       "required"   0}
        "version"           {"store"    ""       "required"   0}
        "description"       {"store"    ""       "required"   0}
        "display_name"      {"store"    ""       "required"   0}
        "mode"              {"store"    "master" "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return ""
    }

    set vlnv      "$parsed_args(vendor):$parsed_args(library):$parsed_args(name):$parsed_args(version)"
    set vlnv_rtl  "$parsed_args(vendor):$parsed_args(library):$parsed_args(name)_rtl:$parsed_args(version)"
    set inst_name $parsed_args(instance_name)

    set found_loaded_busabs 0
    if {$pack_utils::loaded_bus_def == {}} {
        puts "ERROR: There are no interfaces loaded"
        return ""
    }

    #puts "Searching for the bus definition"
    foreach bus_def $pack_utils::loaded_bus_def {
        set bus_abs_def [lindex $bus_def 0]
        set busabs_vlnv [lindex $bus_def 1]
        set busdef_xml  [lindex $bus_def 2]
        set busabs_xml  [lindex $bus_def 3]
        # Found vlnv
        if {$busabs_vlnv == $vlnv} {
            #puts "Loading bus from $busdef_xml"
            set found_loaded_busabs 1
            set pack_utils::current_interface_xml $busabs_xml
            ipx::current_busabs [lindex $bus_abs_def 1]
            break
        }
    }

    if {$found_loaded_busabs == 0} {
        puts "ERROR: Could not find a loaded bus definition for VLNV $vlnv"
        puts "List of loaded bus definitions"
        pack_utils::list_loaded_bus_def
        return ""
    }

    ## Add bus interface
    set interface [ipx::add_bus_interface $inst_name [ipx::current_core]]

    ## Set properties
    set_property abstraction_type_vlnv $vlnv_rtl                   $interface
    set_property bus_type_vlnv         $vlnv                       $interface
    set_property display_name          $parsed_args(display_name)  $interface
    set_property description           $parsed_args(description)   $interface
    puts "Setting interface mode as $parsed_args(mode) for interface \"$interface\""
    set_property interface_mode        $parsed_args(mode)          $interface
    puts "Interface mode = [get_property interface_mode $interface]"

    ## Set pack_utils variables
    set pack_utils::current_interface         $inst_name
    set pack_utils::current_interface_vlnv    $vlnv 

    return [ipx::get_bus_interfaces $inst_name -of_objects [ipx::current_core]]
}

# Map an RTL port to an interface bus port
proc pack_utils::map_interface_port { args } {
    array set my_arglist {
        "interface_instance"  {"store"    ""       "required"   1}
        "interface_port_name" {"store"    ""       "required"   0}
        "rtl_port_name"       {"store"    ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    ## Check that the interface has been instantiated
    set current_interface [ipx::get_bus_interfaces $parsed_args(interface_instance) -of_objects [ipx::current_core]]

    if {$current_interface == {}} {
        puts "ERROR: Interface $parsed_args(interface_instance) has not been instantiated"
        return 1
    }


    ## Check that the port definition exists in the interface
    set interface_ports     [ipx::get_bus_abstraction_ports -of_objects [ipx::current_busabs]]
    set interface_port_name {}
    foreach port $interface_ports {
        set obj_type    [lindex $port 0]
        set bus_abs_def [lindex $port 1]
        set port_name   [lindex $port 2]
        #puts $port
        #puts "port_name = $port_name"

        if {$port_name == $parsed_args(interface_port_name)} {
            set interface_port_name $port_name
        }
    }

    if {$interface_port_name == {}} {
        puts "ERROR: Port name $parsed_args(interface_port_name) of interface $parsed_args(interface_instance) doesn't exist!"
        return 1
    }

    ## Check that the RTL port name exists
    set rtl_port [ipx::get_ports $parsed_args(rtl_port_name) -of_objects [ipx::current_core]]
    #puts "rtl_port $rtl_port"

    if {$rtl_port == {}} {
        puts "ERROR: RTL Port name $parsed_args(rtl_port_name) of core [ipx::current_core] doesn't exist!"
        return 1
    }

    set rtl_port_name $parsed_args(rtl_port_name)

    ## Add the port for mapping
    puts "Adding the port $interface_port_name"
    set added_port [ipx::add_port_map $interface_port_name $current_interface]

    puts "Mapping the port $interface_port_name -> $rtl_port_name"
    set_property physical_name $rtl_port_name $added_port

    return 0
}

proc pack_utils::load_bus_def {args} {
    array set my_arglist {
        "xml"  {"store"    ""       "required"   1}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    set exit_status 0

    foreach xml_file $parsed_args(xml) {
        set busdef_xml $xml_file
        set busabs_xml [regsub -all ".xml$" $xml_file "_rtl.xml"] 

        puts "busdef_xml = $busdef_xml"
        puts "busabs_xml = $busabs_xml"

        if {[file exists $busdef_xml] == 0} {
            puts "ERROR: Bus definition XML $busdef_xml doesn't exist"
            set exit_status 1
        }

        if {[file exists $busabs_xml] == 0} {
            puts "ERROR: Bus abstraction definition XML $busabs_xml doesn't exist"
            set exit_status 1
        }

        set bus_abs_def [list [ipx::open_abstraction_definition  $busabs_xml]]

        set     bus_def $bus_abs_def
        lappend bus_def [get_property BUS_TYPE_VLNV [ipx::current_busabs]]
        lappend bus_def [file normalize $busdef_xml]
        lappend bus_def [file normalize $busabs_xml]

        lappend pack_utils::loaded_bus_def $bus_def
    }

    return $exit_status
}

## Add register map (for slaves)
proc pack_utils::add_register_map {args} {
    array set my_arglist {
      "interface_instance"  {"store"    ""       "required"   1}
      "reg_name"            {"store"    ""       "required"   0}
      "range_dependency"    {"store"    ""       "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    set interface_name  $parsed_args(interface_instance)
    set addr_block_name $parsed_args(reg_name)
    set memory_map_name "${interface_name}_memory_map"
    set range_dependency $parsed_args(range_dependency)

    ## Create the address space
    set memory_map [ipx::add_memory_map     $memory_map_name [ipx::current_core]]

    ## Create the register block
    set addr_block [ipx::add_address_block $addr_block_name $memory_map]

    ## Set the Xilinx parameters
    set bar_low_param  [ipx::add_address_block_parameter OFFSET_BASE_PARAM $addr_block]
    set bar_high_param [ipx::add_address_block_parameter OFFSET_HIGH_PARAM $addr_block]
    set_property Value C_${interface_name}_BASEADDR $bar_low_param
    set_property Value C_${interface_name}_HIGHADDR $bar_high_param

    ## Reference it to the interface
    set_property slave_memory_map_ref $memory_map_name [ipx::get_bus_interfaces $interface_name -of_objects [ipx::current_core]]

    ## Set the range dependency
    set_property RANGE_DEPENDENCY $range_dependency $addr_block
}

## Add address space (for masters)
proc pack_utils::add_address_space {args} {
    array set my_arglist {
      "interface_instance"  {"store"    ""       "required"   1}
      "reg_name"            {"store"    ""       "required"   0}
      "range_dependency"    {"store"    ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    set interface_name   $parsed_args(interface_instance)
    set addr_space_name  $parsed_args(reg_name)
    set range_dependency $parsed_args(range_dependency)

    ## Create Address Space
    set addr_space [ipx::add_address_space $addr_space_name [ipx::current_core]]

    ## Reference it to the interface
    set_property master_address_space_ref $addr_space_name [ipx::get_bus_interfaces $interface_name -of_objects [ipx::current_core]]

    ## Set the range dependency
    set_property RANGE_DEPENDENCY $range_dependency $addr_space
}

proc pack_utils::configure_interface_parameter {args} {
    array set my_arglist {
      "interface_instance"  {"store"    ""       "required"   1}
      "parameter_name"      {"store"    ""       "required"   0}
      "value"               {"store"    ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    ## Check that the interface has been instantiated
    set current_interface [ipx::get_bus_interfaces $parsed_args(interface_instance) -of_objects [ipx::current_core]]

    if {$current_interface == {}} {
        puts "ERROR: Interface $parsed_args(interface_instance) has not been instantiated"
        return 1
    }

    set current_param [ipx::add_bus_parameter $parsed_args(parameter_name) ${current_interface}]

    puts "Setting property VALUE of parameter $parsed_args(parameter_name) to $parsed_args(value)"
    set_property VALUE $parsed_args(value) $current_param

}

proc pack_utils::finalize_current_interface {} {
    ## Check integrity
    set integrity [ipx::check_integrity [ipx::get_bus_interfaces $pack_utils::current_interface]]

    return integrity
}


proc pack_utils::finalize_packaging {} {
    ## Check integrity
    foreach interface [ipx::get_bus_interfaces -of_objects [ipx::current_core]] {
        puts "Checking interface [lindex $interface 2]"
        ipx::check_integrity $interface
    }

    
    ipx::create_xgui_files                                [ipx::current_core]
    ipx::update_checksums                                 [ipx::current_core]
    ipx::save_core                                        [ipx::current_core]

    puts "Closing project"
    close_project
}