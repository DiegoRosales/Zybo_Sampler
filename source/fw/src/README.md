# Firmware Code Structure
The firmware code is divided into 2 main parts:

1) **Common/Main code**: This is code that doesn't neccessarily relate to the peripherals created in the Programmable Logic. This code is also meant to contain the higher-level applications

2) **Peripheral code**: This is code that is meant to interface directly with the corresponding peripheral

## Common/Main code

The code currently includes

####  FreeRTOS (tuned for Xilinx Zynq platforms)
This was taken from the [Xilinx Embedded Repository](https://github.com/Xilinx/embeddedsw) and modified a little bit to fit my requirements

**Location**
```bash
REPO_ROOT/source/fw/repo/freertos10_xilinx_sampler_v1_4
```

####  FreeRTOS+CLI with the Zynq serial drivers
This was made from the [demo code in the FreeRTOS website](https://freertos.org/FreeRTOS-Plus/FreeRTOS_Plus_CLI/FreeRTOS_Plus_CLI_Demos.html)

**Location**
```bash
$REPO_ROOT/source/fw/src/FreeRTOS-Plus-CLI <--- FreeRTOS+CLI
$REPO_ROOT/source/fw/src/ZyboCLI           <--- Zynq Serial Drivers
```

####  FreeRTOS+FAT with the Zynq SD Card drivers (provided by Xilinx)
This was made from the [demo code in the FreeRTOS website](https://freertos.org/FreeRTOS-Plus/FreeRTOS_Plus_TCP/TCP_FAT_demo_projects.html)

**Location**
```bash
$REPO_ROOT/source/fw/src/FreeRTOS-Plus-FAT <--- FreeRTOS+FAT
$REPO_ROOT/source/fw/src/ZyboSD            <--- Zynq SD Card driver wrapper
$REPO_ROOT/source/fw/repo/sdps_v3_5        <--- Zynq SD Card drivers
```

####  jsmn - A light JSON parser for embedded applications
This was taken directly from the [jsmn repository](https://github.com/zserge/jsmn)

**Location**
```bash
$REPO_ROOT/source/fw/src/jsmn
```

####  Sampler code
This is the code that is supposed to load the samples from the SD card and play them back

**Location**
```bash
$REPO_ROOT/source/fw/src/sampler             <--- Sampler engine
$REPO_ROOT/source/fw/src/fat_CLI_apps.c      <--- Misc commands to navigate the SD card
$REPO_ROOT/source/fw/src/main.c              <--- Main function
```

## Peripheral Code
The code that is meant to interface with the PL Peripherals is inside each subsystem.

**Location**
```bash
$REPO_ROOT/subsystems/<SUBSYSTEM>/fw
```