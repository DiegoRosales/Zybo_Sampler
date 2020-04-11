# Verilog I2C interface

For more information and updates: http://alexforencich.com/wiki/en/verilog/i2c/start

GitHub repository: https://github.com/alexforencich/verilog-i2c

## Introduction

I2C interface components.  Includes full MyHDL testbench with intelligent bus
cosimulation endpoints.

## Documentation

### i2c_init module

Template module for peripheral initialization via I2C.  For use when one or
more peripheral devices (i.e. PLL chips, jitter attenuators, clock muxes,
etc.) need to be initialized on power-up without the use of a general-purpose
processor.  

### i2c_master module

I2C master module with AXI stream interfaces to control logic.  

### i2c_master_wbs_8 module

I2C master module with 8-bit Wishbone slave interface.

### Source Files

    axis_fifo.v             : AXI stream FIFO
    i2c_init.v              : Template I2C bus init state machine module
    i2c_master.v            : I2C master module
    i2c_master_wbs_8.v      : I2C master module (8-bit Wishbone slave)

## Testing

Running the included testbenches requires MyHDL and Icarus Verilog.  Make sure
that myhdl.vpi is installed properly for cosimulation to work correctly.  The
testbenches can be run with a Python test runner like nose or py.test, or the
individual test scripts can be run with python directly.

### Testbench Files

    tb/axis_ep.py        : MyHDL AXI Stream endpoints
    tb/i2c.py            : MyHDL I2C master and slave models
    tb/wb.py             : MyHDL Wishbone master model and RAM model
