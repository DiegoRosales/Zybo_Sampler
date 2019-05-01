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

[**DONE**] Enable FreeRTOS+FAT to access the SD card

[**DONE***] Custom DMA engine to support up to 64 different DMA regions (64 voices) <sup><sup><sup>***DMA is functional, but currently tested at 4 voices to facilitate debug**</sup></sup></sup>

[**DONE**] Develop application to download samples to memory from an SD Card

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
"${workspace_loc:/${ProjName}/src/fw/FreeRTOS-Plus-FAT}"
"${workspace_loc:/${ProjName}/src/fw/ZyboCLI}"
"${workspace_loc:/${ProjName}/src/fw/ZyboSD}"
"${workspace_loc:/${ProjName}/src/fw/nco}"
"${workspace_loc:/${ProjName}/src/fw/sampler}"
```

# Runtime instructions
Right now the project has very (**VERY**) limited functionality, but here's what you can do

## Launch the project
To launch the project, simply power on the Zybo and go into the Xilinx SDK with the compiled project. Once you're there go to `Xilinx -> Program FPGA`. Select the bitfile from the `results/audio_sampler_integ` directory and click on `Program`

Now that the bitfile has been downloaded, go to your Project Explorer and right click on the .elf file that is under `codec_fw -> Binaries -> codec_fw.elf`. On the menu, go to `Run As` and select `Run on Hardware (System Debugger)`.

## Interact with the CLI
To interact with the CLI, open a serial terminal (using a program like PuTTY) and configure the following settings

- `Baud Rate: 115200`
- `Data Bits: 8`
- `Stop Bits: 1`
- `Parity: None`

Once the settings have been configured, open the serial connection. You should be greeted with a screen like this one. You can type `help` to see the commands available.

## Example

### Hello Screen

![SerialHello](https://i.imgur.com/oDWW7r2.png)

### SD Card Initialization
Command
```>> sd_init```

![sd_init](https://i.imgur.com/Yg0IEvA.png)

### Show files in current directory
Command (after sd_init)
```>> dir```

![dir](https://i.imgur.com/YUeOLMs.png)

# Instrument Definition
The sampler currently supports only one instrument at a time. Each instrument should be defined using a file in JSON format. The structure of such file is the following

## Instrument name
The instrument name should be located in the first layer of the JSON file (preferrably at the beginning) like this
```json
{
    "instrument_name": "My Piano Library",
    ...
}
```

## Sample definition
The samples related to this instrument should be defined in a second layer called "samples" like this
```json
{
    ...
    "samples": {
        ...
    }
}
```

Inside this section, the samples for each note should be defined as follows
```<NOTE_NAME><NOTE_NUMBER>(_S)```
where:
- ```<NOTE_NAME>``` Is the name of the note (A to G).
- ```<NOTE_NUMBER>``` Is note number (0 to 8).
- ```(_S)``` Is optional. It represents a "sharp" note

Example: "```A4_S```" is equivalent to A4#

Each has its own sub_fields, such as sample path (relative to the .json file) and minimum and maximum velocities (Note. Right now only 1 velocity range is supported, but this will be expanded for multi-sampled instruments). The field names are:

- ```sample_file``` This points to the sample file relative to the .json file
- ```velocity_min``` Minimum velocity
- ```velocity_max``` Maximum velocity

Example:

```json
{
    ...
    "samples": {
        ...
        "C3_S": {
            "sample_file": "samples/piano_c3_sharp.wav",
            "velocity_min": 0,
            "velocity_max": 255,
        }
        ...
    }
}
```