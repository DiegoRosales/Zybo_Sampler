########################################
## Timing constraints
########################################

## Board clock - 125MHz
create_clock -period 8.000 -name board_clk -waveform {0.000 4.000} -add [get_ports board_clk]

## I2S Serial Clock - 24MHz
create_clock -period 41.667 -name codec_bclk -add [get_ports codec_i2s_bclk]

set_clock_groups -name board_clk_grp  -asynchronous -group [get_clocks board_clk]
set_clock_groups -name codec_bclk_grp -asynchronous -group [get_clocks codec_bclk]
