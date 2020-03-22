##############################
## TCL utilities
##############################

proc lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc arg_parser { arg_list parsed_args args } {
    upvar $parsed_args  parsed_args_int
    upvar $arg_list     arg_list_int
    upvar $args         args_int

    set   required_list {}
    set   exit_status   0
    
    ## Fill defaults
    foreach arg_name [array names arg_list_int] {
        set default_value     [lindex $arg_list_int($arg_name) 1]
        set argument_req      [lindex $arg_list_int($arg_name) 2]

        if {$argument_req == "optional"} {
            set parsed_args_int($arg_name) $default_value
        } else {
            puts "$arg_name is required"
            lappend required_list $arg_name
        }
    }

    ## Parse arguments
    set cur_arg_pos 1
    while { [llength $args_int] } {
        set arg [lshift args_int]
        puts "arg = $arg"

        if {$arg != ""} {
            ## If argument starts with '-' (-something)
            if {[string index $arg 0] == "-"} {
                set arg_name [string range $arg 1 end]

                ## Search for the argument in the argument list
                if {[lsearch -exact [array names arg_list_int] "$arg_name"] != -1} {
                    set action        [lindex $arg_list_int($arg_name) 0]
                    #puts "$arg_name is in arg_list"
                    switch -exact -- $action {
                        store {
                            set parsed_args_int($arg_name) [lshift args_int]
                            puts "$arg_name = $parsed_args_int($arg_name)"
                        }
                        
                        store_true {
                            set parsed_args_int($arg_name) 1
                        }

                        store_false {
                            set parsed_args_int($arg_name) 0
                        }
                    }
                }
            ## If it doesn't start with '-' check if it's a positional argument
            } else {
                #puts "Checking if this is an indexed argument"
                set found_arg 0
                foreach arg_name [array names arg_list_int] {
                    set argument_position [lindex $arg_list_int($arg_name) 3]
                    if {$argument_position == $cur_arg_pos} {
                        set parsed_args_int($arg_name) $arg
                        set found_arg 1
                        puts "$arg_name = $parsed_args_int($arg_name)"
                        break
                    }
                }

                if {$found_arg == 0} {
                    puts "ERROR - Unknown argument $arg"
                    set exit_status 1
                }
            }
        }

        incr cur_arg_pos
    }

    ## Check if there are missing
    puts "Checking for missing arguments"
    foreach required_arg $required_list {
        #puts "Required arg is $required_arg"
        if {[lsearch -exact [array names parsed_args_int] "$required_arg"] == -1} {
            puts "ERROR: Missing argument $required_arg"
            set exit_status 1
        }
    }

    if {$exit_status == 0} {
        puts "Argument parsing OK"
        puts "-------------------"
    } else {
        puts "ERROR: Argument parsing failed"
        puts "-------------------"

    }
    return $exit_status
}


array set my_arglist {
    "test"  {"store" "" "optional" 0}
    "test2" {"store" "" "optional" 1}
}

set my_args {test2_arg -test test_arg}
arg_parser my_arglist my_parsedargs my_args

puts "test = $my_parsedargs(test)"
puts "test2 = $my_parsedargs(test2)"
lsearch -exact [array names my_arglist] "-test2"