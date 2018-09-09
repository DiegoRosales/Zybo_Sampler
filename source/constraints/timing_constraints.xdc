## This file is a general .xdc for the ZYBO Rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used signals according to the project

## Board clock - 50MHz
create_clock -add -name board_clk -period 20 -waveform {0 4} [get_ports { board_clk }];
