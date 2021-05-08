
#################################################################
## Sample info fetcher ILA
#################################################################
# Xilinx IP Settings
set ip_name        "ila"
set ip_version     6.2
set ip_vendor      "xilinx.com"
set ip_library     "ip"
puts "probe_widths = $probe_widths"

lappend {*}configuration_parameters CONFIG.C_NUM_OF_PROBES         ${number_of_probes}
lappend {*}configuration_parameters CONFIG.C_INPUT_PIPE_STAGES     ${number_of_input_pipe_stages}
lappend {*}configuration_parameters CONFIG.C_ADV_TRIGGER           {false}

foreach {probe_num width} $probe_widths {
  puts "Setting $probe_num = $width"
  lappend {*}configuration_parameters CONFIG.C_${probe_num}_WIDTH $width
}
lappend {*}configuration_parameters CONFIG.ALL_PROBE_SAME_MU_CNT   ${number_of_comparators}
