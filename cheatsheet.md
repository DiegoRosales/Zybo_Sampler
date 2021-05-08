## Tools Required
 - Xilinx Vivado 2020.1
 - Xilinx Vitis 2020.1

Before you build, you need to setup the environment. To do that, you need to run the Vivado and Vitis (previously Xilinx SDK) setup scripts like this
```bash
## From the Windows CMD shell
# Vivado
[CMD]>> call S:\Xilinx\Vivado\2021.1\settings64.bat
# Xilinx Vitis (previously Xilinx SDK)
[CMD]>> call S:\Xilinx\Vitis\2021.1\settings64.bat
## From the Linux Bash shell (TODO)
...
```
### Binary build
```bash
## Run the complete build flow from scratch
>> vivado -mode batch -source scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json

## Run only specific stages
# Stages: PACK | INTEG | GEN_XILINX_IP | IMPL | BUILD_WS | LINT (optional)
>> vivado -mode batch -source scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json -stages "<STAGE1>+<STAGE2>+..."
# Example
>> vivado -mode batch -source scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json -stages "INTEG+IMPL"
>> vivado -mode tcl   -source scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json -stages "LINT"

## Run with stage arguments
>> vivado -mode batch -source scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json -stages "<STAGE1>+<STAGE2>+..." --stage_args "<STAGE1>_ARG1=1" "<STAGE2>_ARG2=MyValue" --
# Example
>> vivado -mode tcl -source scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json -stages "SIM" --stage_args "SIM_TB=codec_unit_top_tb" "SIM_TC=codec_unit_top_testcase_1" --
```

### Firmware build
```bash
# Note 1: This stage can also be executed from Vivado, but it will be calling this command
# Note 2: This stage will only build the Vitis Workspace. 
#         You will need to load Vitis to compile the firmware and program the board
# Note 3: For Vitis 2019.2, there's a Windows bug related to the Xilinx Software Command Tool (xsct) 
#         You may need to apply this patch: https://www.xilinx.com/support/answers/73252.html
>> xsct scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json -stages "BUILD_WS"
```

### UVM Simulation
```bash
# To run the UVM simulation, you need to use a Vivado version equal or greater than 2019.2 -- That's when they added support for UVM
# You need to provide the Testbench name and the Testcase name using "SIM_TB=<testbench>" and "SIM_TC=<testcase>"
# Right now the testbench and testcases are dummy placeholders
# Example
>> vivado -mode tcl -source scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json -stages "SIM" --stage_args "SIM_TB=codec_unit_top_tb" "SIM_TC=codec_unit_top_testcase_1" --
```
