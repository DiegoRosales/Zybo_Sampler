
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

  ////////////////////////////////
  //// Input Control Signals  ////
  ////////////////////////////////  
  input wire test_mode,

  /////////////////////////////
  //// Input Data Signals  ////
  /////////////////////////////

  input  wire [63:0] audio_data_in,
  input  wire        audio_data_wr,
  output wire [63:0] audio_data_out,
  input  wire        audio_data_rd,
  output wire        audio_buffer_full

);

localparam TEST_SIGNAL_1 = 32'h0000_1fff;
localparam TEST_SIGNAL_2 = 32'h0000_0000;

wire [63:0] serializer_audio_in;
reg  [31:0] test_signal_reg;
reg  [31:0]  test_counter;

////////////////////////////////////
assign serializer_audio_in = (test_mode) ? {test_signal_reg, test_signal_reg} : 'h0;
assign audio_data_out = /*(locked) ?*/ /*counter*/ {{60{1'b0}}, test_counter[18:17], counter[24:23]};// : 'hdeadbeef_deadcafe;
assign ac_muten = 1'b1;
////////////////////////////////////
// Audio Clock Generator
////////////////////////////////////

  codec_audio_clock_generator codec_audio_clock_generator_inst (
    .reset        (reset ), // input reset
    .locked       (locked), // output locked

    .clock_in_125 (clock  ), // Input Clock
    .codec_mclk   (ac_mclk) // Output Clock

    );      // input clock_in_125


  reg [63:0] counter;

  always @ (posedge ac_bclk or negedge locked) begin
    if (locked == 1'b0) counter <= 'hffffffff_cafecafe;
    else counter <= counter + 1;
  end

  

  // Test Tone Generator
  // Generates a 440Hz Square Wave
  always @ (posedge ac_bclk or negedge locked) begin
    if (locked == 1'b0) begin
      test_signal_reg <= 'h0;
      test_counter    <= 'h0;
    end
    else begin
      test_counter <= test_counter;
      if (audio_data_rd) begin
        test_counter <= test_counter + 1'b1;
        if (test_counter[6] == 0) begin
          test_signal_reg <= TEST_SIGNAL_1;
        end 
        else begin
          test_signal_reg <= TEST_SIGNAL_2;
        end
      end
    end
  end


  audio_data_serializer audio_data_serializer_inst(
    /////////////////////////////////
    //// CODEC I2S Audio Signals ////
    /////////////////////////////////
    // Clocks
    .ac_bclk,  // I2S Serial Clock
    // Playback
    .ac_pblrc, // I2S Playback Channel Clock (Left/Right)
    .ac_pbdat, // I2S Playback Data

    /////////////////////////////
    //// Input Data Signals  ////
    /////////////////////////////
    .word_length(2'b00), // Indicates if the data is 16, 20, 24 or 32 bits.

    /////////////////////////////
    //// Input Data Signals  ////
    /////////////////////////////

    .audio_data_in(serializer_audio_in), // Data for the L and R channels
    .audio_data_rd                       // Read the data from the buffer
  );
    
endmodule