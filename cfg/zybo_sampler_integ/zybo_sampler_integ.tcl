############################################
## Integration script for the Zybo Sampler
############################################

set integ_script_dir [file normalize [file dirname [info script]]]

## Integrate design for synthesis
source ${integ_script_dir}/zybo_sampler_integ_synth.tcl
## Integrate design for simulation
#source ${integ_script_dir}/zybo_sampler_integ_sim.tcl