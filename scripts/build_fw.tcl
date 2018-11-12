source scripts/common_variables.tcl 

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

## Step 1 - Set the Workspace
setws ${worskpace_project_path}

## Step 2 - Create a Hardware Project
if {[file exists "${worskpace_project_path}/${hw_project_name}"] == 0} {
  createhw -name ${hw_project_name} -hwspec ${worskpace_project_path}/${block_design_hdf}
}

## Step 3 - Create the application
if {[file exists "${worskpace_project_path}/${sdk_project_name}"] == 0} {
    createapp -name ${sdk_project_name} -hwproject ${hw_project_name} -bsp ${sdk_project_name}_bsp -proc ${processor} -os standalone -lang C -app {Empty Application}
}

## Step 4 - Build the project
projects -build
## Step 4 - Add the Sources
#repo -set ${fw_source_path}