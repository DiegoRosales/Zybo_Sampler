####################
## Common RTL filelist
####################

set synthesis_file_list {
    ${core_root}/rtl/pulse_synchronizer.sv
    ${core_root}/rtl/synchronizer.sv
    ${core_root}/rtl/axi_slave_controller.sv
}

## Simulation include dirs
set uvm_simulation_env_incdir_list {
    ${core_root}/gen
    ${core_root}/verif/i2s_vip/
    ${core_root}/verif/axi4_lite_bfm/
}