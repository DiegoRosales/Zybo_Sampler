## Create the AXI4 Interface
set axi4_lite_name "axi4_lite_interface"
lappend axi_interfaces $axi4_lite_name
set interface_instance [pack_utils::create_interface_instance ${axi4_lite_name}                                  \
                                                              -vendor        xilinx.com                          \
                                                              -library       interface                           \
                                                              -name          aximm                               \
                                                              -version       1.0                                 \
                                                              -description   "AXI Interface for register access" \
                                                              -display_name  $axi4_lite_name                     \
                                                              -mode          "slave"                             \
                                                              ]

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "AWADDR" \
                               -rtl_port_name "s00_axi_awaddr"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "AWPROT" \
                               -rtl_port_name "s00_axi_awprot"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "AWVALID" \
                               -rtl_port_name "s00_axi_awvalid"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "AWREADY" \
                               -rtl_port_name "s00_axi_awready"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "WDATA" \
                               -rtl_port_name "s00_axi_wdata"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "WSTRB" \
                               -rtl_port_name "s00_axi_wstrb"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "WVALID" \
                               -rtl_port_name "s00_axi_wvalid"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "WREADY" \
                               -rtl_port_name "s00_axi_wready"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "BRESP" \
                               -rtl_port_name "s00_axi_bresp"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "BVALID" \
                               -rtl_port_name "s00_axi_bvalid"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "BREADY" \
                               -rtl_port_name "s00_axi_bready"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "ARADDR" \
                               -rtl_port_name "s00_axi_araddr"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "ARPROT" \
                               -rtl_port_name "s00_axi_arprot"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "ARVALID" \
                               -rtl_port_name "s00_axi_arvalid"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "ARREADY" \
                               -rtl_port_name "s00_axi_arready"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "RDATA" \
                               -rtl_port_name "s00_axi_rdata"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "RRESP" \
                               -rtl_port_name "s00_axi_rresp"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "RVALID" \
                               -rtl_port_name "s00_axi_rvalid"

pack_utils::map_interface_port $axi4_lite_name \
                               -interface_port_name "RREADY" \
                               -rtl_port_name "s00_axi_rready"

## Add register map
pack_utils::add_register_map -interface_instance $axi4_lite_name -reg_name "codec_controller_regmap" -range_dependency "pow(2,(C_S00_AXI_ADDR_WIDTH - 1) + 1)"

## AXI Reset
set rst_name          "s00_axi_aresetn"
set rst_description   "AXIS Reset"
set rst_polarity      "ACTIVE_LOW"
pack_utils::create_xilinx_reset_interface $rst_name \
                                          -rtl_port_name $rst_name \
                                          -description   $rst_description \
                                          -display_name  $rst_name \
                                          -polarity      $rst_polarity \
                                          -mode          slave