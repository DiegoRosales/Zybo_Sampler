## Run simulation

## Create the base project
source $build_stages_path/stage_impl_base.tcl
set no_tc 0
set no_tb 0

## Enable UVM
current_fileset -simset [get_filesets uvm_simulation]
set_property    -name {xsim.elaborate.xelab.more_options} -value {-L uvm}  -objects [get_filesets uvm_simulation]
set_property    -name {xsim.compile.xvlog.more_options}   -value {-L uvm}  -objects [get_filesets uvm_simulation]


if {[info exists STAGE_SIM_ARGS(SIM_TB)]} {
  set testbench $STAGE_SIM_ARGS(SIM_TB)
  set_property top $testbench [get_filesets uvm_simulation]
} else {
  puts "ERROR - Testbench not specified"
  set no_tb 1
}

if {[info exists STAGE_SIM_ARGS(SIM_TC)]} {
  set testcase $STAGE_SIM_ARGS(SIM_TC)
  set plusargs "-testplusarg UVM_TESTNAME=${testcase}"
  set_property -name {xsim.simulate.xsim.more_options}   -value $plusargs -objects [get_filesets uvm_simulation]
} else {
  puts "ERROR - Testcase not specified"
  set no_tc 1
}

if {$no_tb == 0 && $no_tc == 0} {
  launch_simulation -absolute_path -simset [get_filesets uvm_simulation]
  restart
  run 1ms
} elseif {$no_tb == 0 && $no_tc == 1} {
  puts "Running only Compile and Elaboration"
  launch_simulation -absolute_path -step Compile
  launch_simulation -absolute_path -step Elaborate
}