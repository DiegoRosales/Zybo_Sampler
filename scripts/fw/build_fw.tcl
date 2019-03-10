source scripts/common_variables.tcl 

##################################################
## Process to get the processor name
##################################################
proc get_processor_name {hw_project_name} {
  set periphs [getperipherals $hw_project_name]
  # For each line of the peripherals table
  foreach line [split $periphs "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If the last column is "PROCESSOR", then get the "IP INSTANCE" name (1st col)
    if {[lindex $values end] == "PROCESSOR"} {
      return [lindex $values 0]
    }
  }
  return ""
}

########################################
## Setup the project
########################################

## Step 1 - Set the Workspace (from the common variables)
setws ${worskpace_project_path}

## Step 2 - Add the customized FreeRTOS repo to the local repositories
repo -set ${fw_source_path}/repo

## Step 3 - Create a Hardware Project
if {[file exists "${worskpace_project_path}/${hw_project_name}"] == 0} {
  createhw -name ${hw_project_name} -hwspec ${worskpace_project_path}/${block_design_hdf}
}

## Step 4 - Create the application
if {[file exists "${worskpace_project_path}/${sdk_project_name}"] == 0} {
    createapp -name ${sdk_project_name} -hwproject ${hw_project_name} -bsp ${sdk_project_name}_bsp -proc ${processor} -os freertos10_xilinx_sampler -lang C -app {Empty Application}
}

## Step 5 - Build the project (Generate the BSP sources)
projects -build
