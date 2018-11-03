
/////////////////////////////////////////////////////
// This module is the I2S interface between the    //
// Audio CODEC and the Audio Data Producer         //
// The Audio CODEC should be configured in Master  //
// mode to save FPGA Clocking resources            //
///////////////                                    //
// In Master Mode, the FPGA should only supply the //
// Master Clock (ac_mclk) and the CODEC will       //
// generate the appropriate I2S Serial Clock for   //
// the preferred Sampling Rate.                    //
// The CODEC will also supply the LR Clock         //
/////////////////////////////////////////////////////
// Rev. 0.1 - Init                                 //
/////////////////////////////////////////////////////

module audio_unit_top(
  // Clock and Reset
  input clock,
  input reset,

  /////////////////////////////////
  //// CODEC I2S Audio Signals ////
  /////////////////////////////////
  // Clocks
  output wire ac_mclk   , // Master Clock
  input  wire ac_bclk   , // I2S Serial Clock
  // Playback
  input  wire ac_pblrc  , // I2S Playback Channel Clock (Left/Right)
  output wire ac_pbdat  , // I2S Playback Data
  // Record
  input  wire ac_recdat , // I2S Recorded Data
  input  wire ac_reclrc , // I2S Recorded Channel Clock (Left/Right)
  // Misc
  output wire ac_muten  , // Digital Enable (Active Low)

  /////////////////////////////
  //// Input Data Signals  ////
  /////////////////////////////

  input  wire [63:0] audio_data_in,
  input  wire        audio_data_wr,
  output wire [63:0] audio_data_out,
  input  wire        audio_data_rd,
  output wire        audio_buffer_full

);

////////////////////////////////////
// Audio Clock Generator
////////////////////////////////////

  codec_audio_clock_generator instance_name
   (
    .reset        (reset ), // input reset
    .locked       (locked), // output locked

    .clock_in_125 (clock  ), // Input Clock
    .codec_mclk   (ac_mclk) // Output Clock

    );      // input clock_in_125


  reg [63:0] counter;

  always @ (posedge ac_bclk or negedge locked) begin
    if (locked == 1'b0) counter <= 'h0;
    else counter <= counter + 1;
  end

  assign audio_data_out = counter;
    
endmodule