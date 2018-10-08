# Zybo Sampler
![Zybo](https://reference.digilentinc.com/_media/reference/programmable-logic/zybo/zybo-0.png)

----
This is an **Audio Sampler** and (maybe) **Syntheziser** project created for the **Digilent Zybo** board. The idea is to recreate the audio engine of the Keyboard Workstations of the mid-late 2000's (like the **Fantom X series** from **Roland**) to create an open source **Hardware** sampler powerful enough to recreate any sound from the last decade... Let's see if this FPGA can do it.

You can find more about the board over at https://reference.digilentinc.com/reference/programmable-logic/zybo/start

Note that this board has been discontinued and replaced with the Zybo Z7 which is contains a larger FPGA from the same family as the regular Zybo

---
## Milestones

[**DONE**] Created the git repo

[**DONE**] CODEC control module (I2C)

[**DONE**] AXI Registers module

[**DONE**] Basic FW Interface to the RTL registers 

[**IN PROGRESS**] I2S Interface to the CODEC

[**NOT STARTED**] DMA Interface between the ARM core and the I2S controller

---
# Build instructions
To build the project, you need to execute 1 script using Vivado: `run_design.tcl`. This script can take parameters to build whatever you need. Here are some examples

```
## Run the complete flow from scratch and burn the bitfile once it is done
[CMD]>> vivado -mode batch -source scripts\run_design.tcl -tclargs all
## Run only the Design Integration
[CMD]>> vivado -mode batch -source scripts\run_design.tcl -tclargs integ
## Only burn the bitfile
[CMD]>> vivado -mode batch -source scripts\run_design.tcl -tclargs burn_only
```

This script calls two scripts `create_packaged_ip.tcl` and `create_integrated_design.tcl`.

The first script will create a packaged ip so that it can be integrated with the Zynq Processor in the second script.
The second script will also run Synthesis and Place and Route, as well as the bitstream generation (aka: the *bitfile*)