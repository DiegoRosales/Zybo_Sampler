// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4.1 (win64) Build 2117270 Tue Jan 30 15:32:00 MST 2018
// Date        : Sat Oct 27 15:43:50 2018
// Host        : DESKTOP-AFP64EE running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/FPGA/Xilinx/audio_sampler/source/generated_ips/codec_audio_clock_generator/codec_audio_clock_generator_stub.v
// Design      : codec_audio_clock_generator
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z010iclg225-1L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module codec_audio_clock_generator(codec_mclk, reset, locked, clock_in_125)
/* synthesis syn_black_box black_box_pad_pin="codec_mclk,reset,locked,clock_in_125" */;
  output codec_mclk;
  input reset;
  output locked;
  input clock_in_125;
endmodule
