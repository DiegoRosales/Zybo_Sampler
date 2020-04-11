## Create the AXI Stream Master port mapping
set interface_name "axis_interface_master"
set interface_prefix "axi_stream_master"
set interface_instance [pack_utils::create_interface_instance $interface_name                             \
                                                              -vendor        xilinx.com                   \
                                                              -library       interface                    \
                                                              -name          axis                         \
                                                              -version       1.0                          \
                                                              -description   "CODEC AXI Stream Interface" \
                                                              -display_name  $interface_name              \
                                                              -mode          "master"                     \
                                                              ]

pack_utils::map_interface_port $interface_name                         \
                               -interface_port_name "TDATA"         \
                               -rtl_port_name       "${interface_prefix}_tdata"

pack_utils::map_interface_port $interface_name                         \
                               -interface_port_name "TREADY"        \
                               -rtl_port_name       "${interface_prefix}_tready"

pack_utils::map_interface_port $interface_name                         \
                               -interface_port_name "TVALID"        \
                               -rtl_port_name       "${interface_prefix}_tvalid"

pack_utils::map_interface_port $interface_name                         \
                               -interface_port_name "TLAST"         \
                               -rtl_port_name       "${interface_prefix}_tlast"

pack_utils::map_interface_port $interface_name                         \
                               -interface_port_name "TSTRB"         \
                               -rtl_port_name       "${interface_prefix}_tstrb"

## AXI Reset
set rst_name        ${interface_prefix}_aresetn
set rst_description "AXI4 Reset"
set rst_polarity    "ACTIVE_LOW"
pack_utils::create_xilinx_reset_interface $rst_name \
                                          -rtl_port_name $rst_name \
                                          -description   $rst_description \
                                          -display_name  $rst_name \
                                          -polarity      $rst_polarity \
                                          -mode          slave