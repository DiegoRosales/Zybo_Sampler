## Create the AXI4 Interface
set interface_name    "axi4_lite_interface"
set interface_prefix  "axi_lite_slave"
set register_map_name "dma_controller_regmap"
set interface_instance [pack_utils::create_interface_instance $interface_name                                    \
                                                              -vendor        xilinx.com                          \
                                                              -library       interface                           \
                                                              -name          aximm                               \
                                                              -version       1.0                                 \
                                                              -description   "AXI Interface for register access" \
                                                              -display_name  $interface_name                     \
                                                              -mode          "slave"                             \
                                                              ]


## Add register map
pack_utils::add_register_map -interface_instance $interface_name -reg_name $register_map_name -range_dependency "pow(2,(C_AXI_LITE_SLAVE_ADDR_WIDTH - 1) + 1)"

## Map the ports
pack_utils::map_interface_port $interface_name \
                               -interface_port_name "AWADDR" \
                               -rtl_port_name "${interface_prefix}_awaddr"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "AWPROT" \
                               -rtl_port_name "${interface_prefix}_awprot"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "AWVALID" \
                               -rtl_port_name "${interface_prefix}_awvalid"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "AWREADY" \
                               -rtl_port_name "${interface_prefix}_awready"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "WDATA" \
                               -rtl_port_name "${interface_prefix}_wdata"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "WSTRB" \
                               -rtl_port_name "${interface_prefix}_wstrb"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "WVALID" \
                               -rtl_port_name "${interface_prefix}_wvalid"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "WREADY" \
                               -rtl_port_name "${interface_prefix}_wready"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "BRESP" \
                               -rtl_port_name "${interface_prefix}_bresp"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "BVALID" \
                               -rtl_port_name "${interface_prefix}_bvalid"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "BREADY" \
                               -rtl_port_name "${interface_prefix}_bready"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "ARADDR" \
                               -rtl_port_name "${interface_prefix}_araddr"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "ARPROT" \
                               -rtl_port_name "${interface_prefix}_arprot"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "ARVALID" \
                               -rtl_port_name "${interface_prefix}_arvalid"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "ARREADY" \
                               -rtl_port_name "${interface_prefix}_arready"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "RDATA" \
                               -rtl_port_name "${interface_prefix}_rdata"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "RRESP" \
                               -rtl_port_name "${interface_prefix}_rresp"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "RVALID" \
                               -rtl_port_name "${interface_prefix}_rvalid"

pack_utils::map_interface_port $interface_name \
                               -interface_port_name "RREADY" \
                               -rtl_port_name "${interface_prefix}_rready"

## AXI Reset
set rst_name          ${interface_prefix}_aresetn
set rst_description   "AXI4 Reset"
set rst_polarity      "ACTIVE_LOW"
pack_utils::create_xilinx_reset_interface $rst_name \
                                          -rtl_port_name $rst_name \
                                          -description   $rst_description \
                                          -display_name  $rst_name \
                                          -polarity      $rst_polarity \
                                          -mode          slave