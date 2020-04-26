
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
  // Record
  input  wire ac_recdat , // I2S Recorded Data
  input  wire ac_reclrc , // I2S Recorded Channel Clock (Left/Right)  

  /////////////////////////////
  //// Input Data Signals  ////
  /////////////////////////////
  input wire [1:0] word_length, // Indicates if the data is 16, 20, 24 or 32 bits.

  /////////////////////////////
  //// Input Data Signals  ////
  /////////////////////////////

  output wire          m_axis_tready,
  input  wire          m_axis_tvalid,
  input  wire [63 : 0] m_axis_tdata,

  //////////////////////////////
  //// Output Data Signals  ////
  //////////////////////////////

  input  wire          s_axis_tready,
  output wire          s_axis_tvalid,
  output wire [63 : 0] s_axis_tdata,

  ////////////////////////////
  //// Misc Data Signals  ////
  ////////////////////////////

  output wire DOWNSTREAM_missed,
  input  wire justification
);

// Data out
reg [63:0] audio_data_out_shift_reg;
// Data in
reg [63:0] audio_data_in_shift_reg;
reg [63:0] audio_data_in_to_fifo;

// Data Read Register
reg data_rd_reg;
// Write the data to the FIFO
reg audio_data_in_wr;

reg DOWNSTREAM_missed_reg;
reg justification_sampled;

// Data to be serialized
wire  [63:0] audio_data_in;
logic [63:0] audio_data_out_pre;

// Input data for the FIFO
wire [63:0] audio_data_in_pre;

// Ouptut serial data
//assign ac_pbdat = audio_data_out_shift_reg[0];
assign ac_pbdat = (justification) ? audio_data_out_shift_reg[0] : audio_data_out_shift_reg[63];
// Output Data Read
assign m_axis_tready = data_rd_reg;

// Input data write
assign s_axis_tvalid = audio_data_in_wr;
assign s_axis_tdata  = audio_data_in_to_fifo;

assign audio_data_in = m_axis_tdata;

assign DOWNSTREAM_missed = DOWNSTREAM_missed_reg;

// Select the data based on the word length
// All modes shift out LSB first
// The least significant bits are the Left channel
// The most significant bits are the Right channel

always_comb begin
  if(justification_sampled == 1'b0) begin
    // Left Justified
    case(word_length)
      2'b00:   audio_data_out_pre = {audio_data_in[15:0], audio_data_in[47:32], {32{1'b0}}}; // 16-bit
      2'b01:   audio_data_out_pre = {audio_data_in[19:0], audio_data_in[51:32], {24{1'b0}}}; // 20-bit
      2'b10:   audio_data_out_pre = {audio_data_in[23:0], audio_data_in[55:32], {16{1'b0}}}; // 24-bit
      2'b11:   audio_data_out_pre = {audio_data_in[31:0], audio_data_in[63:32]};             // 32-bit
      default: audio_data_out_pre = 'h0;
    endcase
  end 
  else begin
    // Right Justified
    case(word_length)
      2'b00:   audio_data_out_pre = {{32{1'b0}}, audio_data_in[47:32], audio_data_in[15:0]}; // 16-bit
      2'b01:   audio_data_out_pre = {{24{1'b0}}, audio_data_in[51:32], audio_data_in[19:0]}; // 20-bit
      2'b10:   audio_data_out_pre = {{16{1'b0}}, audio_data_in[55:32], audio_data_in[23:0]}; // 24-bit
      2'b11:   audio_data_out_pre = {            audio_data_in[63:32], audio_data_in[31:0]}; // 32-bit
      default: audio_data_out_pre = 'h0;
    endcase
  end
end


// Shift Register for the output data
always_ff @(posedge ac_bclk) begin
  data_rd_reg       <= 1'b0;
  // Get the new data
  if ( ac_pblrc ) begin
    data_rd_reg <= 1'b1; // Assert the Data RD to get the data for the next cycle
    // To avoid weird noises, when there's no data, send 0
    if ( m_axis_tvalid ) audio_data_out_shift_reg <= audio_data_out_pre;
    else audio_data_out_shift_reg <= 'h0;
  end
  // Shift the data
  else begin
    // Output Data
    if(justification == 1'b0) audio_data_out_shift_reg <= { audio_data_out_shift_reg[62:0], audio_data_out_shift_reg[63]   };
    else                      audio_data_out_shift_reg <= { audio_data_out_shift_reg[0]   , audio_data_out_shift_reg[63:1] };
  end
end

// Pulse whenever the CODEC is requesting data and there's no valid data
always_ff @(posedge ac_bclk) begin
  DOWNSTREAM_missed_reg <= 1'b0;
  if (ac_pblrc && ~m_axis_tvalid) begin
    DOWNSTREAM_missed_reg <= 1'b1;
  end
  else if ( ac_pblrc && m_axis_tvalid ) begin
    DOWNSTREAM_missed_reg <= 1'b0;
  end
end

// Select the data based on the word length
// All modes shift in MSB first
// The least significant bits are the Left channel
// The most significant bits are the Right channel
assign audio_data_in_pre = (word_length == 2'b00) ? { {16{1'b0}}, audio_data_in_shift_reg[63:48], {16{1'b0}}, audio_data_in_shift_reg[47:32]} : // 16-bit
                           (word_length == 2'b01) ? { {12{1'b0}}, audio_data_in_shift_reg[63:44], {12{1'b0}}, audio_data_in_shift_reg[43:24]} : // 20-bit
                           (word_length == 2'b10) ? { {8{1'b0}} , audio_data_in_shift_reg[63:40], {8{1'b0}} , audio_data_in_shift_reg[39:16]} : // 24-bit
                           (word_length == 2'b11) ? {             audio_data_in_shift_reg[63:32],             audio_data_in_shift_reg[31:0]}  : // 32-bit
                           'h0;

// Shift Register for the input data
always_ff @(posedge ac_bclk) begin
  audio_data_in_wr  <= 1'b0;

  // Write the new data
  if ( ac_reclrc && s_axis_tready ) begin
    audio_data_in_to_fifo <= audio_data_in_pre;
    audio_data_in_wr      <= 1'b1;
  end
  // Shift the data
  else begin
    // Input Data
    audio_data_in_shift_reg  <= { ac_recdat, audio_data_in_shift_reg[63:1]};
  end
end

always_ff @(posedge ac_bclk) justification_sampled <= justification;


endmodule