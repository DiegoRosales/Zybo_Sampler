## Create the AXI Stream Master port mapping
set axis_m_name "axis_interface_master"
lappend axi_interfaces $axis_m_name
set interface_instance [pack_utils::create_interface_instance ${axis_m_name}                              \
                                                              -vendor        xilinx.com                   \
                                                              -library       interface                    \
                                                              -name          axis                         \
                                                              -version       1.0                          \
                                                              -description   "CODEC AXI Stream Interface" \
                                                              -display_name  ${axis_m_name}               \
                                                              -mode          "master"                     \
                                                              ]

pack_utils::map_interface_port $axis_m_name                         \
                               -interface_port_name "TDATA"         \
                               -rtl_port_name       "m_axis_tdata"

pack_utils::map_interface_port $axis_m_name                         \
                               -interface_port_name "TREADY"        \
                               -rtl_port_name       "m_axis_tready"

pack_utils::map_interface_port $axis_m_name                         \
                               -interface_port_name "TVALID"        \
                               -rtl_port_name       "m_axis_tvalid"

pack_utils::map_interface_port $axis_m_name                         \
                               -interface_port_name "TLAST"         \
                               -rtl_port_name       "m_axis_tlast"

## Create the AXI Stream Slave port mapping
set axis_s_name "axis_interface_slave"
lappend axi_interfaces $axis_s_name
set interface_instance [pack_utils::create_interface_instance ${axis_s_name}                                    \
                                                              -vendor        xilinx.com                         \
                                                              -library       interface                          \
                                                              -name          axis                               \
                                                              -version       1.0                                \
                                                              -description   "CODEC AXI Stream Slave Interface" \
                                                              -display_name  ${axis_s_name}                     \
                                                              -mode          "slave"                            \
                                                              ]

pack_utils::map_interface_port $axis_s_name                         \
                               -interface_port_name "TREADY"        \
                               -rtl_port_name       "s_axis_tready"

pack_utils::map_interface_port $axis_s_name                         \
                               -interface_port_name "TVALID"        \
                               -rtl_port_name       "s_axis_tvalid"

pack_utils::map_interface_port $axis_s_name                         \
                               -interface_port_name "TDATA"         \
                               -rtl_port_name       "s_axis_tdata"

## AXI Reset
set rst_name          "axis_aresetn"
set rst_description   "AXIS Reset"
set rst_polarity      "ACTIVE_LOW"
pack_utils::create_xilinx_reset_interface $rst_name \
                                          -rtl_port_name $rst_name \
                                          -description   $rst_description \
                                          -display_name  $rst_name \
                                          -polarity      $rst_polarity \
                                          -mode          slave