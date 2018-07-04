## This file is a general .xdc for the ZYBO Rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used signals according to the project

create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];
