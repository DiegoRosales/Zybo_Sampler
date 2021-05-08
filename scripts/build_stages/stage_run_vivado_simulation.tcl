## Run simulation
set simulation_env [proj_utils::extract_from_all_cores -variable simulation -split -debug]
set incremental_sim 0
set error           ""
set no_tb           0
set no_tc           0
set testbench       ""

append help_message "--- To relaunch the simulation ---\n"
append help_message "\% relaunch_sim\n"
append help_message "\n"
append help_message "--- To relaunch the simulation from scratch ---\n"
append help_message "\% close_sim\n"
append help_message "\% launch_simulation -absolute_path -simset \[get_filesets $testbench\]\n"
append help_message "\n"
append help_message "--- To compile & elaborate the simulation ---\n"
append help_message "\% launch_simulation -absolute_path -step Compile   \[get_filesets $testbench\]\n"
append help_message "\% launch_simulation -absolute_path -step Elaborate \[get_filesets $testbench\]\n"

## Get the arguments from the command line
if {[info exists STAGE_SIM_ARGS(SIM_INCREMENTAL)]} {
  set incremental_sim $STAGE_SIM_ARGS(SIM_INCREMENTAL)
}

if {[info exists STAGE_SIM_ARGS(SIM_TB)]} {
  set testbench $STAGE_SIM_ARGS(SIM_TB)
} else {
  puts "ERROR: Testbench not specified"
  set no_tb 1
}

if {[info exists STAGE_SIM_ARGS(SIM_TC)]} {
  set testcase $STAGE_SIM_ARGS(SIM_TC)
  set simulate_options "-testplusarg UVM_TESTNAME=${testcase}"
} else {
  puts "ERROR: Testcase not specified"
  set no_tc 1
}


set libraries ""
foreach {core sim_env} $simulation_env {
  set libname ${core}_lib
  puts "Configuring $libname"
  dict set curr_lib "compile" [dict get $sim_env simulation_compile]
  dict set curr_lib "incdir"  [dict get $sim_env simulation_incdir]

  puts "Adding files for compile"
  foreach file [dict get $curr_lib compile] {
    puts " - $file"
  }
  
  puts "Adding include directories"
  foreach dir [dict get $curr_lib incdir] {
    puts " - $dir"
  }
  puts "-------\n" 
  
  dict set libraries $libname $curr_lib
}

if {$incremental_sim} {
  if {[catch {current_project} result ]} {
    puts "Opening project ${project_impl_path}/${project_name}.xpr"
    open_project ${project_impl_path}/${project_name}.xpr
  } else {
    puts "$result is already open"
  }
} else {
  if {![catch {current_project} result ]} {
    puts "Closing project $result"
    close_project
  }
  source scripts/build_stages/stage_impl_base.tcl
}

## Setup the filesets
foreach {core sim_env} $simulation_env {
  ## Check if there's a testbench
  if {[dict exists $sim_env "top"]} {
    set curr_testbench [dict get $sim_env "top"]
  } else {
    continue
  }

  if {[get_filesets -quiet $curr_testbench] == ""} {
    puts "Configuring testbench: $curr_testbench"
    ## Create the fileset for this testbench
    create_fileset -simset $curr_testbench
    set all_incdir ""

    ## Check if there are any dependencies
    if {[dict exists $sim_env "required_libs"]} {
      set required_libs [dict get $sim_env "required_libs"]
      puts "Required libraries: $required_libs"
      foreach lib $required_libs {
        if {![dict exists $libraries $lib]} {
          set err_msg "ERROR: Library $lib is missing. Make sure you configured the project correctly"
          lappend error $err_msg
          puts $err_msg
        } else {
          set curr_lib [dict get $libraries $lib]
          ## Add compile files
          if {[dict exists $curr_lib compile]} {
            foreach file [dict get $curr_lib compile] {
              if {[file exists $file]} {
                puts "Adding file: $file"
                add_files -fileset $curr_testbench -norecurse $file
                set_property USED_IN {simulation} [get_files $file]
                ## TODO: Figure how to make Vivado properly compile multiple libraries
                ## set_property library $lib         [get_files $file]
              } else {
                set err_msg "ERROR: File doesn't exist: $file"
                lappend error $err_msg
                puts $err_msg
              }
            }
          }

          ## Add include dirs
          if {[dict exists $curr_lib incdir]} {
            foreach dir [dict get $curr_lib incdir] {
              puts "Adding include dir: $dir"
              lappend all_incdir $dir
            }
          }
        }
      }
    }

    set_property INCLUDE_DIRS                      $all_incdir      [get_filesets $curr_testbench]
    set_property top                               $curr_testbench  [get_filesets $curr_testbench]

    ## Setup UVM
    set_property -name {xsim.compile.xvlog.more_options}   -value {-L uvm} -objects [get_filesets $curr_testbench]
    set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets $curr_testbench]
  }
}

if {$error != ""} {
  puts "ERROR: There was an error generating the simulation environment"
  foreach err_msg $error {
    puts "  $err_msg"
  }
} else {
  ## Launch simulation
  if {$no_tb == 0 && $no_tc == 0} {
    ## Set the testcase
    set_property -name {xsim.simulate.xsim.more_options} -value $simulate_options -objects [get_filesets $testbench]
    launch_simulation -absolute_path -simset [get_filesets $testbench]
    restart
    run 1ms
  } elseif {$no_tb == 0 && $no_tc == 1} {
    puts "Running only Compile and Elaboration"
    launch_simulation -absolute_path -step Compile   [get_filesets $testbench]
    launch_simulation -absolute_path -step Elaborate [get_filesets $testbench]
  } else {
    puts "ERROR: No testbench specified"
  }
}

puts $help_message