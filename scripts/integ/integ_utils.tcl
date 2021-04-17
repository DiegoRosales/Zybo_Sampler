#####################################
## Integration Utils
#####################################
namespace eval integ_utils {
  variable loaded_bus_def
  variable project_name
  variable project_dir
  variable bd_name
  variable bd_dir
  variable bd_file
  variable keep_open
}

## Initialize the utilities
proc integ_utils::init {args} {
  array set my_arglist {
    "project_name"         {"store"    ""       "required"   0}
    "project_dir"          {"store"    ""       "required"   0}
    "project_top"          {"store"    ""       "required"   0}
    "part_number"          {"store"    ""       "required"   0}
    "board_part"           {"store"    ""       "optional"   0}
    "ip_repo_list"         {"store"    ""       "optional"   0}
    "bus_def_xml_list"     {"store"    ""       "optional"   0}
    "debug"                {"store"    ""       "optional"   0}
  }

  set status [arg_parser my_arglist parsed_args args]

  if {$status != 0} {
    puts "ERROR: There was an error processing the arguments"
    return 1
  }

  ##############################
  set integ_utils::project_name     $parsed_args(project_name)
  set integ_utils::project_dir      $parsed_args(project_dir)
  set integ_utils::bd_name          $parsed_args(project_top)
  set integ_utils::bd_dir           $integ_utils::project_dir/bd
  set integ_utils::bd_file          $integ_utils::bd_dir/$integ_utils::bd_name/$integ_utils::bd_name.bd
  set integ_utils::keep_open        $parsed_args(debug)

  puts "Initializing project integration"

  ## Remove previous block design
  if {[file exists $integ_utils::bd_dir/$integ_utils::bd_name]} {
    puts "Removing previous Block Design directory"
    file delete -force -- $integ_utils::bd_dir/$integ_utils::bd_name
  }

  ## Create the project
  create_project  $parsed_args(project_name) \
                  $parsed_args(project_dir) \
                  -part $parsed_args(part_number) \
                  -force


  ## Add the packaged IPs to the repository
  set_property ip_repo_paths $parsed_args(ip_repo_list) [current_project]
  update_ip_catalog

  ## Load custom bus definitions
  if {$parsed_args(bus_def_xml_list) != ""} {
    integ_utils::load_bus_def $parsed_args(bus_def_xml_list)
  }

  if {$parsed_args(board_part) != ""} {
    puts "Setting board part as $parsed_args(board_part)"
    set_property board_part $parsed_args(board_part) [current_project]
  }


  ## Create a block design
  create_bd_design -dir $integ_utils::bd_dir $integ_utils::bd_name

  return 0
}

## Load the bus definitions
proc integ_utils::load_bus_def {args} {
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
    set busabs_xml [regsub -all ".xml$" $xml_file {_rtl.xml}] 

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

    lappend integ_utils::loaded_bus_def $bus_def
  }

  return $exit_status
}

## Create a new hierarchy
proc integ_utils::create_hierarchy_level {args} {
  array set my_arglist {
    "name"  {"store"    ""       "required"   1}
  }

  set status [arg_parser my_arglist parsed_args args]

  if {$status != 0} {
    puts "ERROR: There was an error processing the arguments"
    return 1
  }

  ##################################

  create_bd_cell -type hier $parsed_args(name)

}

## Instantiate a new IP Core
proc integ_utils::create_core_instance {args} {
  array set my_arglist {
    "inst_name"           {"store"         ""       "required"   1}
    "vendor"              {"store"         ""       "optional"   0}
    "library"             {"store"         ""       "optional"   0}
    "name"                {"store"         ""       "optional"   0}
    "version"             {"store"         ""       "optional"   0}
    "vlnv"                {"store"         ""       "optional"   0}
    "hierarchy"           {"store"         ""       "optional"   0}
    "config"              {"store"         ""       "optional"   0}
    "apply_board_preset"  {"store"         ""       "optional"   0}
  }

  set status [arg_parser my_arglist parsed_args args]

  if {$status != 0} {
    puts "ERROR: There was an error processing the arguments"
    return 1
  }

  ##################################

  if {$parsed_args(vendor) != ""} {
    set vlnv "$parsed_args(vendor):$parsed_args(library):$parsed_args(name):$parsed_args(version)"
  } elseif {$parsed_args(vlnv) != ""} {
    set vlnv $parsed_args(vlnv)
  } else {
    puts "ERROR: You must provide the VLNV information"
    return 1
  }

  ## Check if IP exists in the IP catalouge
  if {[lsearch -exact [get_ipdefs -all *$parsed_args(name)* ] "$vlnv"] == -1} {
    puts "ERROR: Cannot find IP Core $vlnv in the IP Catalouge. Make sure to include it in the IP repository"
    puts "Similar IP Cores:"
    foreach ip_core [get_ipdefs -all *$parsed_args(name)* ] {
      puts "$ip_core"
    }
  }

  if {$parsed_args(hierarchy) != ""} {
    puts "Instantiating IP \"$vlnv\" in hierarchy \"$parsed_args(hierarchy)\""
    set inst_name $parsed_args(hierarchy)/$parsed_args(inst_name)
  } else {
    puts "Instantiating IP \"$vlnv\" in a top-level hierarchy"
    set inst_name $parsed_args(inst_name)
  }

  ## Create the IP
  create_bd_cell -type ip -vlnv $vlnv $inst_name

  ## Apply configuration
  if {$parsed_args(apply_board_preset) != ""} {
    set bd_rule "$parsed_args(vendor):bd_rule:$parsed_args(name)"
    apply_bd_automation -rule $bd_rule -config $parsed_args(apply_board_preset) [get_bd_cells $inst_name]
  }

  if {$parsed_args(config) != ""} {
    set_property -dict $parsed_args(config) [get_bd_cells $inst_name]
  }

  set component_name [get_property CONFIG.Component_Name [get_bd_cells $inst_name]]
}

## Connect two ports/interfaces
proc integ_utils::connect {args} {
  array set my_arglist {
    "from_instance"  {"store"    ""       "required"   0}
    "from_interface" {"store"    ""       "required"   0}
    "to_instance"    {"store"    ""       "required"   0}
    "to_interface"   {"store"    ""       "required"   0}
  }

  set status [arg_parser my_arglist parsed_args args]

  if {$status != 0} {
    puts "ERROR: There was an error processing the arguments"
    return 1
  }

  ##################################
  set is_bus_if 0

  if {[get_bd_cells $parsed_args(from_instance)] == ""} {
    puts "ERROR: Instance $parsed_args(from_instance) doesn't exist!"
    return 1
  }

  if {[get_bd_cells $parsed_args(to_instance)] == ""} {
    puts "ERROR: Instance $parsed_args(to_instance) doesn't exist!"
    return 1
  }

  set from_interface "$parsed_args(from_instance)/$parsed_args(from_interface)"
  set to_interface   "$parsed_args(to_instance)/$parsed_args(to_interface)"

  
  if {[get_bd_intf_pins -quiet $from_interface] != ""} {
    set from_interface [get_bd_intf_pins $from_interface]
    set is_bus_if 1
  } elseif {[get_bd_pins -quiet $from_interface] != ""} {
    set from_interface [get_bd_pins $from_interface]
    set is_bus_if 0
  } else {
    puts "ERROR: Interface or Pin $from_interface doesn't exist!"
    return 1
  }

  if {[get_bd_intf_pins -quiet $to_interface] != ""} {
    set to_interface [get_bd_intf_pins $to_interface]
    set is_bus_if 1
  } elseif {[get_bd_pins -quiet $to_interface] != ""} {
    set to_interface [get_bd_pins $to_interface]
    set is_bus_if 0
  } else {
    puts "ERROR: Interface or Pin $to_interface doesn't exist!"
    return 1
  }

  puts "Connecting: $from_interface <------> $to_interface "
  if {$is_bus_if} {
    connect_bd_intf_net $from_interface $to_interface
  } else {
    connect_bd_net $from_interface $to_interface
  }

  return 0
}

## Export pins to the top-level
proc integ_utils::export {args} {
  array set my_arglist {
    "from_instance"  {"store"    ""       "required"   0}
    "from_interface" {"store"    ""       "required"   0}
    "port_name"      {"store"    ""       "required"   0}
  }

  set status [arg_parser my_arglist parsed_args args]

  if {$status != 0} {
    puts "ERROR: There was an error processing the arguments"
    return 1
  }

  ##################################
  set is_bus_if 0

  if {[get_bd_cells $parsed_args(from_instance)] == ""} {
    puts "ERROR: Instance $parsed_args(from_instance) doesn't exist!"
    return 1
  }

  set from_interface "$parsed_args(from_instance)/$parsed_args(from_interface)"

  if {[get_bd_intf_pins -quiet $from_interface] != ""} {
    set from_interface [get_bd_intf_pins $from_interface]
    set is_bus_if 1
  } elseif {[get_bd_pins -quiet $from_interface] != ""} {
    set from_interface [get_bd_pins $from_interface]
    set is_bus_if 0
  } else {
    puts "ERROR: Interface or Pin $from_interface doesn't exist!"
    return 1
  }

  puts "Exporting Interface $from_interface ---|--> TOP"
  if {$is_bus_if} {
    set bus_if_vlnv [get_property VLNV [get_bd_intf_pins $from_interface]]
    set bus_if_mode [get_property MODE [get_bd_intf_pins $from_interface]]

    ## Create port
    create_bd_intf_port -mode $bus_if_mode -vlnv $bus_if_vlnv $parsed_args(port_name)

    ## Configure all properties
    foreach config_prop [list_property [get_bd_intf_pins $from_interface] CONFIG.*] {
      puts "Setting property $config_prop to [get_property $config_prop [get_bd_intf_pins $from_interface]]"
      set_property -quiet $config_prop [get_property $config_prop [get_bd_intf_pins $from_interface]] [get_bd_intf_ports $parsed_args(port_name)]
    }

    ## Connect the interface to the port
    connect_bd_intf_net [get_bd_intf_ports $parsed_args(port_name)] $from_interface
  } else {
    set pin_msb  [get_property LEFT  [get_bd_pins $from_interface]]
    set pin_lsb  [get_property RIGHT [get_bd_pins $from_interface]]
    set pin_dir  [get_property DIR   [get_bd_pins $from_interface]]
    set pin_type [get_property TYPE  [get_bd_pins $from_interface]]

    if {$pin_msb == ""} {set pin_msb 0}
    if {$pin_lsb == ""} {set pin_lsb 0}

    if { [get_bd_ports -quiet $parsed_args(port_name)] == "" } {
      if {$pin_msb == 0 && $pin_lsb == 0} {
        create_bd_port -type $pin_type -dir $pin_dir $parsed_args(port_name)
      } else {
        create_bd_port -type $pin_type -dir $pin_dir -from $pin_msb -to $pin_lsb $parsed_args(port_name)
      }
    } else {
      puts "Port $parsed_args(port_name) already exists. Connecting the net to that port"
    }

    if {$pin_type == "clk"} {
      puts "Setting the frequency of the clock to [get_property CONFIG.FREQ_HZ $from_interface]"
      set_property CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ $from_interface] [get_bd_ports $parsed_args(port_name)]
    }

    connect_bd_net [get_bd_ports $parsed_args(port_name)] $from_interface
  }


  return 0
}

## Finalize the design
proc integ_utils::finalize {args} {

  array set my_arglist {
    "output"     {"store"       ""  "required"   0}
    "override"   {"store_true"  0   "optional"   0}
  }

  set status [arg_parser my_arglist parsed_args args]

  if {$status != 0} {
      puts "ERROR: There was an error processing the arguments"
      return 1
  }

  #######################################

  if {$parsed_args(output) != ""} {
    upvar 1 $parsed_args(output) output

    if {[info exists output] && $parsed_args(override) == 0} {
      puts "ERROR: Output variable already exists $parsed_args(output). Use -override to override it"
      return 1
    }
  }

  ## Assign all addressess to the memory maps
  assign_bd_address

  ## Validate design
  validate_bd_design

  ## Generate RTL
  puts "Generating RTL Wrappers"
  make_wrapper -files [get_files $integ_utils::bd_file] -top
  generate_target all [get_files $integ_utils::bd_file]

  ## Generate RTL Filelist
  set wrapper_rtl_file  $integ_utils::bd_dir/$integ_utils::bd_name/synth/$integ_utils::bd_name.v
  set rtl_filelist_name $integ_utils::project_dir/integ_gen_rtl_filelist.f.json
  set xci_filelist_name $integ_utils::project_dir/integ_gen_xci_filelist.f.json

  set rtl_filelist     {}
  set xci_filelist     {}

  # Write the files to the filelist
  foreach core_name [get_ips -all -regexp "$integ_utils::bd_name.*"] {
    set core_vlnv [get_property IPDEF   [get_ips -all $core_name]]
    set xci_file  [get_property IP_FILE [get_ips -all $core_name]]
    lassign [split $core_vlnv ":"] core_vendor core_library core_name core_version

    ## If it's a Xilinx IP, then only append the .xci file
    if {$core_vendor == "xilinx.com"} {
      if {[lsearch -exact $xci_filelist $xci_file] == -1} {
        lappend xci_filelist $xci_file
      }
    } else {
      set core_dir   [file normalize [file dirname $xci_file]]
      set core_synth $core_dir/synth
      set syn_files  [glob $core_synth/*]
      lappend rtl_filelist $syn_files
    }
  }

  # Add the top-level RTL
  lappend rtl_filelist $wrapper_rtl_file

  write_filelist -filelist $rtl_filelist -list_name "integ_gen_rtl_filelist" -description "Generated RTL Files from the Integration Script" -output $rtl_filelist_name
  write_filelist -filelist $xci_filelist -list_name "integ_gen_xci_filelist" -description "Generated XCI Files from the Integration Script" -output $xci_filelist_name

  dict set output "integ_gen_rtl_filelist" [file normalize $rtl_filelist_name]
  dict set output "integ_gen_xci_filelist" [file normalize $xci_filelist_name]

  puts "keep_open = $integ_utils::keep_open"
  if {$integ_utils::keep_open} {
    puts "Keeping the project open"
  } else {
    puts "Closing project"
    close_project
  }

}