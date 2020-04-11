## Create the AXI4 Interface
set interface_name "axi_dma_interface"
set interface_prefix "axi_dma_master"
set interface_instance [pack_utils::create_interface_instance $interface_name                                    \
                                                              -vendor        xilinx.com          \
                                                              -library       interface           \
                                                              -name          aximm               \
                                                              -version       1.0                 \
                                                              -description   "AXI DMA Interface" \
                                                              -display_name  $interface_name     \
                                                              -mode          "master"            \
                                                              ]

set addr_space_dependency "pow(2,(C_AXI_DMA_MASTER_ADDR_WIDTH - 1) + 1)"
pack_utils::add_address_space $interface_name -reg_name "axi_dma_master_addr_space" -range_dependency $addr_space_dependency

## Map the ports
pack_utils::map_interface_port $interface_name -interface_port_name "AWID" \
                                             -rtl_port_name "${interface_prefix}_awid"

pack_utils::map_interface_port $interface_name -interface_port_name "AWADDR" \
                                             -rtl_port_name "${interface_prefix}_awaddr"

pack_utils::map_interface_port $interface_name -interface_port_name "AWLEN" \
                                             -rtl_port_name "${interface_prefix}_awlen"

pack_utils::map_interface_port $interface_name -interface_port_name "AWSIZE" \
                                             -rtl_port_name "${interface_prefix}_awsize"

pack_utils::map_interface_port $interface_name -interface_port_name "AWBURST" \
                                             -rtl_port_name "${interface_prefix}_awburst"

pack_utils::map_interface_port $interface_name -interface_port_name "AWLOCK" \
                                             -rtl_port_name "${interface_prefix}_awlock"

pack_utils::map_interface_port $interface_name -interface_port_name "AWCACHE" \
                                             -rtl_port_name "${interface_prefix}_awcache"

pack_utils::map_interface_port $interface_name -interface_port_name "AWPROT" \
                                             -rtl_port_name "${interface_prefix}_awprot"

pack_utils::map_interface_port $interface_name -interface_port_name "AWQOS" \
                                             -rtl_port_name "${interface_prefix}_awqos"

pack_utils::map_interface_port $interface_name -interface_port_name "AWUSER" \
                                             -rtl_port_name "${interface_prefix}_awuser"

pack_utils::map_interface_port $interface_name -interface_port_name "AWVALID" \
                                             -rtl_port_name "${interface_prefix}_awvalid"

pack_utils::map_interface_port $interface_name -interface_port_name "AWREADY" \
                                             -rtl_port_name "${interface_prefix}_awready"

pack_utils::map_interface_port $interface_name -interface_port_name "WDATA" \
                                             -rtl_port_name "${interface_prefix}_wdata"

pack_utils::map_interface_port $interface_name -interface_port_name "WSTRB" \
                                             -rtl_port_name "${interface_prefix}_wstrb"

pack_utils::map_interface_port $interface_name -interface_port_name "WLAST" \
                                             -rtl_port_name "${interface_prefix}_wlast"

pack_utils::map_interface_port $interface_name -interface_port_name "WUSER" \
                                             -rtl_port_name "${interface_prefix}_wuser"

pack_utils::map_interface_port $interface_name -interface_port_name "WVALID" \
                                             -rtl_port_name "${interface_prefix}_wvalid"

pack_utils::map_interface_port $interface_name -interface_port_name "WREADY" \
                                             -rtl_port_name "${interface_prefix}_wready"

pack_utils::map_interface_port $interface_name -interface_port_name "BID" \
                                             -rtl_port_name "${interface_prefix}_bid"

pack_utils::map_interface_port $interface_name -interface_port_name "BRESP" \
                                             -rtl_port_name "${interface_prefix}_bresp"

pack_utils::map_interface_port $interface_name -interface_port_name "BUSER" \
                                             -rtl_port_name "${interface_prefix}_buser"

pack_utils::map_interface_port $interface_name -interface_port_name "BVALID" \
                                             -rtl_port_name "${interface_prefix}_bvalid"

pack_utils::map_interface_port $interface_name -interface_port_name "BREADY" \
                                             -rtl_port_name "${interface_prefix}_bready"

pack_utils::map_interface_port $interface_name -interface_port_name "ARID" \
                                             -rtl_port_name "${interface_prefix}_arid"

pack_utils::map_interface_port $interface_name -interface_port_name "ARADDR" \
                                             -rtl_port_name "${interface_prefix}_araddr"

pack_utils::map_interface_port $interface_name -interface_port_name "ARLEN" \
                                             -rtl_port_name "${interface_prefix}_arlen"

pack_utils::map_interface_port $interface_name -interface_port_name "ARSIZE" \
                                             -rtl_port_name "${interface_prefix}_arsize"

pack_utils::map_interface_port $interface_name -interface_port_name "ARBURST" \
                                             -rtl_port_name "${interface_prefix}_arburst"

pack_utils::map_interface_port $interface_name -interface_port_name "ARLOCK" \
                                             -rtl_port_name "${interface_prefix}_arlock"

pack_utils::map_interface_port $interface_name -interface_port_name "ARCACHE" \
                                             -rtl_port_name "${interface_prefix}_arcache"

pack_utils::map_interface_port $interface_name -interface_port_name "ARPROT" \
                                             -rtl_port_name "${interface_prefix}_arprot"

pack_utils::map_interface_port $interface_name -interface_port_name "ARQOS" \
                                             -rtl_port_name "${interface_prefix}_arqos"

pack_utils::map_interface_port $interface_name -interface_port_name "ARUSER" \
                                             -rtl_port_name "${interface_prefix}_aruser"

pack_utils::map_interface_port $interface_name -interface_port_name "ARVALID" \
                                             -rtl_port_name "${interface_prefix}_arvalid"

pack_utils::map_interface_port $interface_name -interface_port_name "ARREADY" \
                                             -rtl_port_name "${interface_prefix}_arready"

pack_utils::map_interface_port $interface_name -interface_port_name "RID" \
                                             -rtl_port_name "${interface_prefix}_rid"

pack_utils::map_interface_port $interface_name -interface_port_name "RDATA" \
                                             -rtl_port_name "${interface_prefix}_rdata"

pack_utils::map_interface_port $interface_name -interface_port_name "RRESP" \
                                             -rtl_port_name "${interface_prefix}_rresp"

pack_utils::map_interface_port $interface_name -interface_port_name "RLAST" \
                                             -rtl_port_name "${interface_prefix}_rlast"

pack_utils::map_interface_port $interface_name -interface_port_name "RUSER" \
                                             -rtl_port_name "${interface_prefix}_ruser"

pack_utils::map_interface_port $interface_name -interface_port_name "RVALID" \
                                             -rtl_port_name "${interface_prefix}_rvalid"

pack_utils::map_interface_port $interface_name -interface_port_name "RREADY" \
                                             -rtl_port_name "${interface_prefix}_rready"


## AXI Reset
set rst_name          ${interface_prefix}_aresetn
set rst_description   "AXI DMA Reset"
set rst_polarity      "ACTIVE_LOW"
pack_utils::create_xilinx_reset_interface $rst_name \
                                          -rtl_port_name $rst_name \
                                          -description   $rst_description \
                                          -display_name  $rst_name \
                                          -polarity      $rst_polarity \
                                          -mode          slave