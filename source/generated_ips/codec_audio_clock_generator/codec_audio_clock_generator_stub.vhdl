-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4.1 (win64) Build 2117270 Tue Jan 30 15:32:00 MST 2018
-- Date        : Sat Oct 27 15:43:50 2018
-- Host        : DESKTOP-AFP64EE running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               D:/FPGA/Xilinx/audio_sampler/source/generated_ips/codec_audio_clock_generator/codec_audio_clock_generator_stub.vhdl
-- Design      : codec_audio_clock_generator
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z010iclg225-1L
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity codec_audio_clock_generator is
  Port ( 
    codec_mclk : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clock_in_125 : in STD_LOGIC
  );

end codec_audio_clock_generator;

architecture stub of codec_audio_clock_generator is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "codec_mclk,reset,locked,clock_in_125";
begin
end;
