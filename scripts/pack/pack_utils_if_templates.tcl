############################
## Interface presets
############################

## Create a Xilinx GPIO Interface
proc pack_utils::create_xilinx_gpio_interface {args} {
    array set my_arglist {
        "interface_name"  {"store"         ""     "required"  1}
        "rtl_port_name"   {"store"         ""     "required"  0}
        "mode"            {"store"         ""     "optional"  0}
        "description"     {"store"         ""     "required"  0}
        "display_name"    {"store"         ""     "required"  0}
        "direction"       {"store"         "in"   "optional"  0}
    }

    ## Parse arguments
    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    set core [ipx::current_core]
    set name          $parsed_args(interface_name)
    set rtl_port_name $parsed_args(rtl_port_name)
    set description   $parsed_args(description)
    set display_name  $parsed_args(display_name)

    switch -exact $parsed_args(direction) {
        in      { set interface_port TRI_I }
        out     { set interface_port TRI_O }
        default { set interface_port TRI_I }
    }

    switch -exact $parsed_args(mode) {
      master {
        set interface_mode "master"
      }
      slave {
        set interface_mode "slave"
      }
      monitor {
        set interface_mode "monitor"
      }
      default {
        set interface_mode "master"
      }
    }

    # Add the bus interface
    set interface_instance [pack_utils::create_interface_instance ${name}                        \
                                                                  -vendor        xilinx.com      \
                                                                  -library       interface       \
                                                                  -name          gpio            \
                                                                  -version       1.0             \
                                                                  -description   $description    \
                                                                  -display_name  $display_name   \
                                                                  -mode          $interface_mode \
                                                                  ]

    if {${interface_instance} == ""} {
      puts "ERROR: There was an error creating the interface instance"
      return 1
    }

    pack_utils::map_interface_port ${name}                              \
                                   -interface_port_name $interface_port \
                                   -rtl_port_name       $rtl_port_name
}

## Create Xilinx interrupt interface
proc pack_utils::create_xilinx_interrupt_interface {args} {
    array set my_arglist {
        "interface_name"  {"store"         ""       "required"  1}
        "rtl_port_name"   {"store"         ""       "required"  0}
        "mode"            {"store"         "master" "optional"  0}
        "description"     {"store"         ""       "required"  0}
        "display_name"    {"store"         ""       "required"  0}
        "sensitivity"     {"store"         ""       "required"  0}
    }

    ## Parse arguments
    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    set core          [ipx::current_core]
    set name          $parsed_args(interface_name)
    set rtl_port_name $parsed_args(rtl_port_name)
    set description   $parsed_args(description)
    set display_name  $parsed_args(display_name)

    switch -exact $parsed_args(mode) {
      master {
        set interface_mode "master"
      }
      slave {
        set interface_mode "slave"
      }
      monitor {
        set interface_mode "monitor"
      }
      default {
        set interface_mode "master"
      }
    }

    # Add the bus interface
    set interface_instance [pack_utils::create_interface_instance ${name}                        \
                                                                  -vendor        xilinx.com      \
                                                                  -library       signal          \
                                                                  -name          interrupt       \
                                                                  -version       1.0             \
                                                                  -description   $description    \
                                                                  -display_name  $display_name   \
                                                                  -mode          $interface_mode \
                                                                  ]

    if {${interface_instance} == ""} {
      puts "ERROR: There was an error creating the interface instance"
      return 1
    }

    pack_utils::map_interface_port ${name}                              \
                                   -interface_port_name INTERRUPT       \
                                   -rtl_port_name       $rtl_port_name
    
    if {$parsed_args(sensitivity) != ""} {
        pack_utils::configure_interface_parameter ${name} -parameter_name SENSITIVITY -value $parsed_args(sensitivity)
    }
}

## Create a Clock Interface
proc pack_utils::create_xilinx_clock_interface {args} {
    array set my_arglist {
        "interface_name"  {"store"         ""       "required"  1}
        "rtl_port_name"   {"store"         ""       "required"  0}
        "mode"            {"store"         "master" "optional"  0}
        "description"     {"store"         ""       "required"  0}
        "display_name"    {"store"         ""       "required"  0}
        "frequency"       {"store"         ""       "optional"  0}
        "associated_if"   {"store"         ""       "optional"  0}
    }

    ## Parse arguments
    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    set core          [ipx::current_core]
    set name          $parsed_args(interface_name)
    set rtl_port_name $parsed_args(rtl_port_name)
    set description   $parsed_args(description)
    set display_name  $parsed_args(display_name)

    switch -exact $parsed_args(mode) {
      master {
        set interface_mode "master"
      }
      slave {
        set interface_mode "slave"
      }
      monitor {
        set interface_mode "monitor"
      }
      default {
        set interface_mode "master"
      }
    }

    # Add the bus interface
    set interface_instance [pack_utils::create_interface_instance ${name}                        \
                                                                  -vendor        xilinx.com      \
                                                                  -library       signal          \
                                                                  -name          clock           \
                                                                  -version       1.0             \
                                                                  -description   $description    \
                                                                  -display_name  $display_name   \
                                                                  -mode          $interface_mode \
                                                                  ]

    if {${interface_instance} == ""} {
      puts "ERROR: There was an error creating the interface instance"
      return 1
    }

    pack_utils::map_interface_port ${name}                              \
                                   -interface_port_name CLK             \
                                   -rtl_port_name       $rtl_port_name

    if {$parsed_args(frequency) != ""} {
        puts "Configuring frequency for clock $parsed_args(rtl_port_name). Frequency = $parsed_args(frequency)Hz"
        pack_utils::configure_interface_parameter ${name} -parameter_name FREQ_HZ -value $parsed_args(frequency)
    }

    if {$parsed_args(associated_if) != ""} {
        puts "Associating clock $parsed_args(rtl_port_name) to interfaces [join $parsed_args(associated_if) ", "]"
        pack_utils::configure_interface_parameter ${name} -parameter_name ASSOCIATED_BUSIF -value [join $parsed_args(associated_if) ":"]
    } else {
        pack_utils::configure_interface_parameter ${name} -parameter_name ASSOCIATED_BUSIF -value ""
    }
}

## Create a Reset Interface
proc pack_utils::create_xilinx_reset_interface {args} {
    array set my_arglist {
        "interface_name"  {"store"         ""       "required"  1}
        "rtl_port_name"   {"store"         ""       "required"  0}
        "mode"            {"store"         "master" "optional"  0}
        "description"     {"store"         ""       "required"  0}
        "display_name"    {"store"         ""       "required"  0}
        "polarity"        {"store"         ""       "optional"  0}
    }

    ## Parse arguments
    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    set core          [ipx::current_core]
    set name          $parsed_args(interface_name)
    set rtl_port_name $parsed_args(rtl_port_name)
    set description   $parsed_args(description)
    set display_name  $parsed_args(display_name)

    switch -exact $parsed_args(mode) {
      master {
        set interface_mode "master"
      }
      slave {
        set interface_mode "slave"
      }
      monitor {
        set interface_mode "monitor"
      }
      default {
        set interface_mode "master"
      }
    }

    # Add the bus interface
    set interface_instance [pack_utils::create_interface_instance ${name}                        \
                                                                  -vendor        xilinx.com      \
                                                                  -library       signal          \
                                                                  -name          reset           \
                                                                  -version       1.0             \
                                                                  -description   $description    \
                                                                  -display_name  $display_name   \
                                                                  -mode          $interface_mode \
                                                                  ]

    if {${interface_instance} == ""} {
      puts "ERROR: There was an error creating the interface instance"
      return 1
    }

    pack_utils::map_interface_port ${name}                              \
                                   -interface_port_name RST             \
                                   -rtl_port_name       $rtl_port_name

    if {$parsed_args(polarity) != ""} {
        puts "Setting reset polarity of $parsed_args(rtl_port_name) as $parsed_args(polarity)"
        pack_utils::configure_interface_parameter ${name} -parameter_name POLARITY -value $parsed_args(polarity)
    } else {
        pack_utils::configure_interface_parameter ${name} -parameter_name POLARITY -value "ACTIVE_LOW"
    }
}
