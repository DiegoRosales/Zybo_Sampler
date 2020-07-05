## Call XSCT from Vivado

puts "Running FW Workspace build command"

## Get the full path of the tool
set xsct [file normalize $::env(XILINX_VITIS)/bin/xsct.bat]

## Make the command
set cmd "$xsct [file normalize [info script]] -cfg [file normalize $parsed_args(cfg)] -stages BUILD_WS"

## Run the command
puts "Running command \'$cmd\'"
catch {exec [split $cmd]} output
puts "Output:"
puts $output

puts "\n"
puts "Done!"