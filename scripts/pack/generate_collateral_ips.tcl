
###############################
## This script generates Xilinx IPs
## needed for the design such 
## as FIFOs and MMCMs
###############################

####################################
## PROCEDURE TO GENERATE A NEW IP ##
## AND RETURN THE IP RUN FOR      ##
## SYNTHESIS                      ##
####################################
proc generate_new_ip {path ip_name ip_version ip_vendor ip_library component_name ip_parameters} {
    ## Global Variables
    global generated_ip_file_list
    global ip_runs
    ## IP Variables
    set ip_xci_path ${path}/${component_name}/${component_name}.xci
    set ip_dcp_path ${path}/${component_name}/${component_name}.dcp
    set ip_run "none"

    ## If it doesn't exist, create it
    if { [file exists ${ip_dcp_path}] == 0 } {
        ## Step 1 - Create the IP if it doesn't exist
        if { [file exists ${ip_xci_path}] == 0 } {
            ## Step 1.1 - Create the IP
            create_ip -name ${ip_name} -vendor ${ip_vendor} -library ${ip_library} -version ${ip_version} -module_name ${component_name} -dir ${path}

            ## Step 1.2 - Configure the IP
            set_property -dict ${ip_parameters} [get_ips ${component_name}]

            ## Step 1.3 - Generate the collateral files
            generate_target all  [get_files ${ip_xci_path}]
        } else {
            ## Import the IP if it already exists
            add_files ${ip_xci_path}
        }

        ## Step 2 - Create the IP run for synthesis
        set ip_run [create_ip_run [get_files ${ip_xci_path}]]
        puts ${ip_run}
    } else {
        ## Import the IP if it already exists
        add_files ${ip_xci_path}
    }

    ## Append the .xci to the filelist
    set generated_ip_file_list [lappend generated_ip_file_list ${ip_xci_path}]
    ## Append the IP Run
    set ip_runs [ lappend ip_runs ${ip_run}]

    return ${ip_run}
}

set ip_runs {}

source ${collateral_ip_list}

foreach ip ${collateral_ips} {
    set ip_path [subst ${ip}]
    puts "sourcing ${ip_path} ..."
    source ${ip_path}
}

foreach ip_run ${ip_runs} {
    if { ${ip_run} != "none" } {
        puts "launching ${ip_run} ..."
        launch_runs ${ip_run}
    }
}

## Wait for the runs to finish
foreach ip_run ${ip_runs} {
    if { ${ip_run} != "none" } {
        puts "Waiting on ${ip_run}"
        wait_on_run ${ip_run}
        puts "IP Run ${ip_run} is done!"
    }
}

