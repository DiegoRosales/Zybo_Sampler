## Run simulation

## Create the base project
source $build_stages_path/stage_impl_base.tcl

if {[info exists STAGE_SIM_ARGS(SIM_TB)]} {
  set testbench $STAGE_SIM_ARGS(SIM_TB)
} else {
  puts "ERROR - Testbench not specified"
}

if {[info exists STAGE_SIM_ARGS(SIM_TC)]} {
  set testcase $STAGE_SIM_ARGS(SIM_TC)
} else {
  puts "ERROR - Testcase not specified"
}

set plusargs "-testplusarg UVM_TESTNAME=${testcase}"

set_property top $testbench [get_filesets uvm_simulation]
set_property -name {xsim.simulate.xsim.more_options}   -value $plusargs -objects [get_filesets uvm_simulation]
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm}  -objects [get_filesets uvm_simulation]
set_property -name {xsim.compile.xvlog.more_options}   -value {-L uvm}  -objects [get_filesets uvm_simulation]

launch_simulation -simset [get_filesets uvm_simulation ]
run 1ms