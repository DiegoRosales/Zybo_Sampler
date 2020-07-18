####################
## Common RTL filelist
####################

set synthesis_file_list {
    ${core_root}/rtl/pulse_synchronizer.sv
    ${core_root}/rtl/synchronizer.sv
    ${core_root}/rtl/axi_slave_controller.sv
}

## Simulation files
set uvm_simulation_file_list {
    ${core_root}/verif/i2s_vip/i2s_vip_env.sv
}

## Simulation include files
set uvm_simulation_env_file_list {
    ${core_root}/verif/i2s_vip/i2s_vip_agent.svh
    ${core_root}/verif/i2s_vip/i2s_vip_driver.svh
    ${core_root}/verif/i2s_vip/i2s_vip_sequencer.svh
    ${core_root}/verif/i2s_vip/i2s_vip_transfer.svh
    ${core_root}/verif/i2s_vip/i2s_vip_pkg.svh
    ${core_root}/verif/i2s_vip/i2s_if.svh
}
