## Synthesis and PAR

## Create the base project
source $build_stages_path/stage_impl_base.tcl

## Create the synthesis run
create_run synthesis -constrset constraints -flow {Vivado Synthesis 2019}
## Create the place and route run
create_run place_and_route -parent_run synthesis -constrset constraints -flow {Vivado Implementation 2019}

## Launch Synthesis
puts "Starting Synthesis"
launch_runs synthesis -jobs 8
wait_on_run -run synthesis
puts "Synthesis Done!"
## Launch Place and route
puts "Starting Place and Route"
launch_runs place_and_route -to_step write_bitstream -jobs 8
wait_on_run -run place_and_route
puts "Place and Route Done!"

## Open the place and route run
current_run [get_runs place_and_route]
open_run place_and_route

## Export the HW Platform for the Vitis Workspace
write_hw_platform -fixed -force  -include_bit -file ${workspace_project_path}/${platform_project_name}.xsa

## Export the debug probes in case an ILA has been instantiated
if {[get_cells -quiet -filter {REF_NAME =~ dbg_hub}] != {}} {
    puts "Writing debug probes"
    write_debug_probes -force ${workspace_project_path}/${platform_project_name}.ltx
}

if {$parsed_args(debug) == 0} {
    close_project
}
