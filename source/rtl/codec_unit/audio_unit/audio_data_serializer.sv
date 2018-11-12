
////////////////////////////////////////////////////////////
// This module receives the audio data from the           //
// audio producer and serializes it according to the      //
// DSP/PCM standard.                                      //
////////////////////                                      //
// Note. The CODEC is configured as Master                //
// The Serial data configuration is the following         //
// DSP/PCM Mode Audio Input Submode 2 (SM2) [Bit LRP = 1] //
////////////////////////////////////////////////////////////
// Rev. 0.1 - Init                                        //
////////////////////////////////////////////////////////////

module audio_data_serializer(
  /////////////////////////////////
  //// CODEC I2S Audio Signals ////
  /////////////////////////////////
  // Clocks
  input  wire ac_bclk, // I2S Serial Clock
  // Playback
  input  wire ac_pblrc, // I2S Playback Channel Clock (Left/Right)
  output wire ac_pbdat, // I2S Playback Data

  /////////////////////////////
  //// Input Data Signals  ////
  /////////////////////////////
  input wire [1:0] word_length, // Indicates if the data is 16, 20, 24 or 32 bits.

  /////////////////////////////
  //// Input Data Signals  ////
  /////////////////////////////

  input  wire [63:0] audio_data_in,     // Data for the L and R channels
  output wire        audio_data_rd      // Read the data from the buffer
);

// Data out
reg [63:0] audio_data_shift_reg;
reg [63:0] audio_data_pre;

// Data Read Register
reg data_rd_reg;

// Ouptut serial data
assign ac_pbdat = audio_data_shift_reg[63];
// Output Data Read
assign audio_data_rd = data_rd_reg;

// Select the data based on the word length
// All modes shift out MSB first
assign audio_data_pre = (word_length == 2'b00) ? {audio_data_in[15:0], audio_data_in[47:32], {32{1'b0}}} : // 16-bit
                        (word_length == 2'b01) ? {audio_data_in[19:0], audio_data_in[51:32], {24{1'b0}}} : // 20-bit
                        (word_length == 2'b10) ? {audio_data_in[23:0], audio_data_in[55:32], {16{1'b0}}} : // 24-bit
                        (word_length == 2'b11) ? {audio_data_in[31:0], audio_data_in[63:32]}             : // 32-bit
                        'h0;

// Shift Register
always_ff @(posedge ac_bclk) begin
  
  data_rd_reg <= 1'b0;

  // Get the new data
  if (ac_pblrc) begin
    audio_data_shift_reg <= audio_data_pre;
    data_rd_reg          <= 1'b1; // Assert the Data RD to get the data for the next cycle
  end
  // Shift the data
  else begin
    audio_data_shift_reg <= { audio_data_shift_reg[62:0], audio_data_shift_reg[63] };
  end
  
end

endmodule