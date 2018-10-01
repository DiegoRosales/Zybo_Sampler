## This file is a general .xdc for the ZYBO Rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used signals according to the project

## Board clock - 50MHz
create_clock -period 20.000 -name board_clk -waveform {0.000 4.000} -add [get_ports board_clk]

