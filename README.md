# Zybo Sampler
![Zybo](https://reference.digilentinc.com/_media/reference/programmable-logic/zybo/zybo-0.png)

----
This is an **Audio Sampler** and (maybe) a **Syntheziser** project created for the **Digilent Zybo** board. The idea is to recreate the audio engine of the Keyboard Workstations of the mid-late 2000's (like the **Fantom X series** from **Roland**) to create an open source **Hardware** sampler powerful enough to recreate any sound from the last decade... Let's see if this FPGA can do it.

I am basing this design on the architectures used in Roland and Korg keyboard, where the CPU is used to handle basic tasks like managing the display, lights, buttons, etc. and a dedicated sound engine is used to load the samples and perform DSP. From the processor speed and memory perspective, this board and FPGA should outperform the hardware present in those keyboards. However it is difficult to tell if the same will be true for the DSP and DMA capabilities present in those keyboards ASICs. Note that the idea is to end up with a user-friendly UI with a display and buttons and knobs and whatnot.

![FantomX](https://i.imgur.com/VdELW5Z.png)


**Note** that this Zybo board has been discontinued and replaced by the Zybo Z7-10 and the Z7-20. The upgrades include more ram, faster clocks, a MIPI connector, a second HDMI port and (in the case of the Z7-20) a larger FPGA. This project will continue targeting the old Zybo because I'm not a Rockefeller.

You can find more about the board over at https://reference.digilentinc.com/reference/programmable-logic/zybo/start

---
# Milestones

## Phase 1 [**DONE**]: Enable and test basic IO 

[**DONE**] Created the git repo

[**DONE**] CODEC control module (I2C)

[**DONE**] AXI Registers module

[**DONE**] Basic FW Interface to the RTL registers 

[**DONE**] Basic interrupt handler mechanism for the board buttons

[**DONE**] I2S Serializer + test tone

[**DONE**] I2S HW Control Registers

[**DONE**] DMA Interface between the ARM core and the I2S controller

[**DONE**] FW Test Sine Wave Tone Generator (Using DDS)

[**DONE**] FreeRTOS CLI Interface over UART to the PS

## Phase 2 [**IN PROGRESS**]: Enable and test advanced IO

[**IN PROGRESS**] Custom DMA engine to support up to 88 different DMA regions (88 keys in a piano)

[**NOT STARTED**] Enable FreeRTOS+FAT to download samples to memory from an SD Card

[**NOT STARTED**] Enable a MIDI bridge using UART

## Phase 3 [**NOT STARTED**]: Sound Playback

[**NOT STARTED**] Playback samples from the FamtomX libary

[**NOT STARTED**] Square Wave Synthesizer

[**NOT STARTED**] Sine Wave Synthesizer

[**NOT STARTED**] Sawtooth Wave Synthesizer

## Phase 4 [**NOT PLANNED**]: TBD

[**NOT STARTED**] Enabled the full system in the verification environment

---
# Setup instructions
Before you build, you need to setup the environment. To do that, you need to run the Vivado and Xilinx SDK setup scripts like this
```bash
## From the Windows CMD shell
# Vivado
[CMD]>> call D:\Xilinx\Vivado\2018.2\settings64.bat
# Xilinx SDK
[CMD]>> call D:\Xilinx\SDK\2018.2\settings64.bat
## From the Linux Bash shell (TODO)
...
```

# Build instructions
To build the project, you need to execute 1 script using Vivado: `run_design.tcl`. This script can take parameters using the `-tclparams <param>` argument to build whatever you need. Here are some examples

```bash
## Run the complete flow from scratch and burn the bitfile once it is done
[CMD]>> vivado -mode batch -source scripts\run_design.tcl -tclargs all
## Run only the Design Integration (optional)
[CMD]>> vivado -mode batch -source scripts\run_design.tcl -tclargs integ
## To update the RTL (optional)
[CMD]>> vivado -mode batch -source scripts\run_design.tcl -tclargs all_update
## Only burn the bitfile (optional)
[CMD]>> vivado -mode batch -source scripts\run_design.tcl -tclargs burn_only

## To create the SDK Workspace
[CMD]>> vivado -mode batch -source scripts\run_design.tcl -tclargs export_ws
## To make the BSP (note, this won't add the source code to the workspace)
[CMD]>> xsdk -batch scripts\fw\build_fw.tcl
```

To add the source code to the SDK Workspace, right clic on `src` and select `New -> Folder`. Then click on `Advanced` and select `Link to alternate location`. Browse to the `source\fw` directory and add click `Ok` and `Finish`.
Once it has been added, Right click on the project and go to `C/C++ Build Settings`. Then go to `Directories` in the compiler section and add the following directories

```tcl
"${workspace_loc:/${ProjName}/src/fw/FreeRTOS-Plus-CLI}"
"${workspace_loc:/${ProjName}/src/fw/ZyboCLI}"
```