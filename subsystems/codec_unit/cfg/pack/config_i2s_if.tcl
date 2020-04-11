## Create the I2S Interface
set i2s_master_interface_name "i2s_master"
set interface_instance [pack_utils::create_interface_instance ${i2s_master_interface_name}                \
                                                              -vendor        analog                       \
                                                              -library       user                         \
                                                              -name          i2s_master                   \
                                                              -version       1.0                          \
                                                              -description   "I2S Master Interface"       \
                                                              -display_name  "i2s_master"                 \
                                                              -mode          "master"                     \
                                                              ]

pack_utils::map_interface_port $i2s_master_interface_name      \
                               -interface_port_name "MCLK"     \
                               -rtl_port_name       "ac_mclk"

pack_utils::map_interface_port $i2s_master_interface_name      \
                               -interface_port_name "BCLK"     \
                               -rtl_port_name       "ac_bclk"

pack_utils::map_interface_port $i2s_master_interface_name      \
                               -interface_port_name "PBLRC"    \
                               -rtl_port_name       "ac_pblrc"

pack_utils::map_interface_port $i2s_master_interface_name      \
                               -interface_port_name "PBDAT"    \
                               -rtl_port_name       "ac_pbdat"

pack_utils::map_interface_port $i2s_master_interface_name      \
                               -interface_port_name "RECDAT"   \
                               -rtl_port_name       "ac_recdat"

pack_utils::map_interface_port $i2s_master_interface_name      \
                               -interface_port_name "RECLRC"   \
                               -rtl_port_name       "ac_reclrc"

pack_utils::map_interface_port $i2s_master_interface_name      \
                               -interface_port_name "MUTEN"    \
                               -rtl_port_name       "ac_muten"

pack_utils::finalize_current_interface