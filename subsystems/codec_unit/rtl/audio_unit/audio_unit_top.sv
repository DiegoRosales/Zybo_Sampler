
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
  input reset_n,

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
  //// AXI4 Stream Signals ////
  /////////////////////////////
  // Clock and Reset
  input  wire          axis_aclk,
  input  wire          axis_aresetn,

  // Slave Interface Signals (DMA -> CODEC) //
  output wire          s_axis_tready,  // Ready
  input  wire          s_axis_tvalid,  // Data Valid (WR)
  input  wire [63 : 0] s_axis_tdata,   // Data

  // Master Interface Signals (CODEC -> DMA) //
  input  wire          m_axis_tready,  // Ready (RD)
  output wire          m_axis_tvalid,  // Data Valid
  output wire [63 : 0] m_axis_tdata,   // Data
  output wire          m_axis_tlast,

  //////////////////////
  //// Misc Signals ////
  //////////////////////
  output wire [3:0]    heartbeat,
  input  wire          justification,

  /////////////////////////
  //// Counter Signals ////
  /////////////////////////
  // AXI CLK //
  output wire [31:0] DOWNSTREAM_axis_wr_data_count,
  output wire [31:0] UPSTREAM_axis_rd_data_count,
  // Audio CLK //
  output wire [31:0] DOWNSTREAM_axis_rd_data_count,
  output wire [31:0] UPSTREAM_axis_wr_data_count,

  ///////////////////////////
  //// Interrupt Signals ////
  ///////////////////////////
  output wire DOWNSTREAM_almost_empty

);

  localparam TEST_SIGNAL_1 = 32'h0000_1fff;
  localparam TEST_SIGNAL_2 = 32'h0000_0000;

  wire [63:0] serializer_audio_in;
  reg  [31:0] test_signal_reg;
  reg  [31:0] test_counter;

  /////////////////////////
  // Input FIFO Signals  //
  /////////////////////////
  wire        audio_data_IN_ready;
  wire        audio_data_IN_valid;
  wire [63:0] audio_data_IN_data;
  wire        audio_data_IN_last;

  //////////////////////////
  // Output FIFO Signals  //
  //////////////////////////
  wire        audio_data_OUT_ready;
  wire        audio_data_OUT_valid;
  wire        audio_data_OUT_valid2;
  wire [63:0] audio_data_OUT_data;

  //////////////////////////
  //       COUNTERS       //
  //////////////////////////
  reg [63:0] axi_fifo_rd_counter;        // Read from the DMA
  reg [63:0] serializer_fifo_wr_counter; // Write from the Serializer
  reg [63:0] axi_fifo_wr_counter;        // Write from the DMA
  reg [63:0] serializer_fifo_rd_counter; // Read from the Serializer
  reg [63:0] DOWNSTREAM_missed_counter;  // Downstream missed packet counter
  wire DMA_fifo_wr;                      // DMA Write to the FIFO
  wire DMA_fifo_rd;                      // DMA Read from the FIFO

  wire DOWNSTREAM_missed;

  //assign m_axis_tlast = (UPSTREAM_axis_rd_data_count <= 3) ? 1'b1 : 1'b0;
  assign audio_data_IN_last      = serializer_fifo_wr_counter[7:0] == 8'h10;
  assign DOWNSTREAM_almost_empty = DOWNSTREAM_axis_rd_data_count < 30;
  ////////////////////////////////////
  assign serializer_audio_in   = (test_mode) ? {test_signal_reg, test_signal_reg} : audio_data_OUT_data;
  assign ac_muten              = 1'b1;
  assign audio_data_OUT_valid2 = audio_data_OUT_valid | test_mode;

  // Counter for the AXI FIFO Reset
  reg [4:0] reset_counter;
  wire      axi_fifo_reset_n;

  assign axi_fifo_reset_n = &reset_counter;

  always @(posedge ac_bclk or negedge locked)
    if (locked == 1'b0) reset_counter <= 5'h0;
    else reset_counter <= (axi_fifo_reset_n == 1'b0) ? reset_counter + 1'b1 : reset_counter;

  // Counter for a heartbeat signal to make sure that the clock from the CODEC is running
  assign heartbeat = {
                      DOWNSTREAM_missed_counter[14], // Bit 3
                      DOWNSTREAM_missed_counter[4],  // Bit 2
                      axi_fifo_wr_counter[14],       // Bit 1
                      serializer_fifo_rd_counter[14] // Bit 0
                      };


  /////////////////////////////////////////
  ////////////// COUNTERS /////////////////

  // Read counter (DMA Reading from FIFO)
  assign DMA_fifo_rd = m_axis_tready && m_axis_tvalid;
  always @(posedge axis_aclk or negedge axis_aresetn)
    if (axis_aresetn == 1'b0) axi_fifo_rd_counter <= 'h0;
    else axi_fifo_rd_counter <= (DMA_fifo_rd) ? axi_fifo_rd_counter + 1 : axi_fifo_rd_counter;

  // Write counter (DMA Writing to FIFO)
  assign DMA_fifo_wr = s_axis_tvalid && s_axis_tready;
  always @(posedge axis_aclk or negedge axis_aresetn)
    if (axis_aresetn == 1'b0) axi_fifo_wr_counter <= 'h0;
    else axi_fifo_wr_counter <= (DMA_fifo_wr) ? axi_fifo_wr_counter + 1 : axi_fifo_wr_counter;


  // Read counter (Serializer reading from FIFO)
  always @(posedge ac_bclk or negedge locked)
    if (locked == 1'b0) serializer_fifo_rd_counter <= 'h0;
    else serializer_fifo_rd_counter <= (audio_data_OUT_ready) ? serializer_fifo_rd_counter + 1 : serializer_fifo_rd_counter;

  // Write counter (Serializer writing to FIFO)
  always @(posedge ac_bclk or negedge locked)
    if (locked == 1'b0) serializer_fifo_wr_counter <= 'h0;
    else serializer_fifo_wr_counter <= (audio_data_IN_valid) ? serializer_fifo_wr_counter + 1 : serializer_fifo_wr_counter;

  // Data Missed counter
  always @(posedge ac_bclk or negedge locked)
    if (locked == 1'b0) DOWNSTREAM_missed_counter <= 'h0;
    else DOWNSTREAM_missed_counter <= (DOWNSTREAM_missed) ? DOWNSTREAM_missed_counter + 1 : DOWNSTREAM_missed_counter;

////////////////////////////////////////

  // Test Tone Generator
  // Generates a 440Hz Square Wave
  always @ (posedge ac_bclk or negedge locked) begin
    if (locked == 1'b0) begin
      test_signal_reg <= 'h0;
      test_counter    <= 'h0;
    end
    else begin
      test_counter <= test_counter;
      if (m_axis_tready) begin
        test_counter <= test_counter + 1'b1;
        if (test_counter[7] == 0) begin
          test_signal_reg <= TEST_SIGNAL_1;
        end
        else begin
          test_signal_reg <= TEST_SIGNAL_2;
        end
      end
    end
  end


  ////////////////////////////////////
  // Audio Clock Generator
  ////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////
  //             +-----------------------------+              CODEC
  //             |         MMCM                |         +----------------+
  //             |       +------+              |         |                |
  //             |       |      |              |         |                |
  //  board_clk  | 125MHz|      |    12MHz     |ac_mclk  |                |
  // +------------------>+      +----------------------->+                +---+
  //             |       |      |              |         |                |   |
  //             |       +------+              |         |                |   |
  //             |                             |         |                |   |
  //             |                             |         |                |   |
  //             |                             |         |                |   |
  //             |                             |         |                |   |
  //             |                             |         |                |   |
  //             |                             |         |                |   |
  //             |          Serializer         |         |                |   |
  //             |       +--------------+      |         |                |   |
  //             |       |              |      |         |                |   |
  //      ac_bclk| 24MHz |              |      |i2s_data |                |   |
  //    +---------------->              +--------------->+                |   |
  //    |        |       |              |      |         |                |   |
  //    |        |       |              |      |         |                |   |
  //    |        |       |              |      |         +----------------+   |
  //    |        |       +--------------+      |                              |
  //    |        |                             |                              |
  //    |        +-----------------------------+                              |
  //    |                                                                     |
  //    +---------------------------------------------------------------------+
  /////////////////////////////////////////////////////////////////////////////////

  // PLL To generate the 12MHz clock for the CODEC
  codec_audio_clock_generator codec_audio_clock_generator_inst (
    .reset        ( ~reset_n ), // input reset
    .locked       ( locked   ), // output locked
    .clock_in_125 ( clock    ), // Input Clock
    .codec_mclk   ( ac_mclk  )  // Output Clock (12MHz)
  );

  audio_data_serializer audio_data_serializer_inst(
    /////////////////////////////////
    //// CODEC I2S Audio Signals ////
    /////////////////////////////////
    // Clocks
    .ac_bclk   ( ac_bclk   ), // I2S Serial Clock
    // Playback
    .ac_pblrc  ( ac_pblrc  ), // I2S Playback Channel Clock (Left/Right)
    .ac_pbdat  ( ac_pbdat  ), // I2S Playback Data
    // Record
    .ac_recdat ( ac_recdat ), // I2S Recorded Data
    .ac_reclrc ( ac_reclrc ), // I2S Recorded Channel Clock (Left/Right)

    /////////////////////////////
    //// Input Data Signals  ////
    /////////////////////////////
    .word_length( 2'b00 ), // Indicates if the data is 16, 20, 24 or 32 bits.

    /////////////////////////////
    //// Input Data Signals  ////
    /////////////////////////////
    .m_axis_tready ( audio_data_OUT_ready  ),
    .m_axis_tvalid ( audio_data_OUT_valid2 ),
    .m_axis_tdata  ( serializer_audio_in   ),

    //////////////////////////////
    //// Output Data Signals  ////
    //////////////////////////////
    .s_axis_tready ( audio_data_IN_ready ),
    .s_axis_tvalid ( audio_data_IN_valid ),
    .s_axis_tdata  ( audio_data_IN_data  ),

    ////////////////////////////
    //// Misc Data Signals  ////
    ////////////////////////////
    .DOWNSTREAM_missed ( DOWNSTREAM_missed ),
    .justification     ( justification     )

  );

  //////////////////////////////////////////////
  // AXI Streaming FIFO for the output signal
  //////////////////////////////////////////////
  // DMA --|--> FIFO --|--> CODEC
  audio_data_fifo audio_data_OUT_fifo_inst (
    /////////////////////////////////////
    // Slave Clock Domain (I2S Codec)
    /////////////////////////////////////
    .m_axis_aclk    ( ac_bclk              ), // input  wire          m_axis_aclk
    .m_axis_tready  ( audio_data_OUT_ready ), // input  wire          m_axis_tready
    .m_axis_tvalid  ( audio_data_OUT_valid ), // output wire          m_axis_tvalid
    .m_axis_tdata   ( audio_data_OUT_data  ), // output wire [63 : 0] m_axis_tdata
    .m_axis_tlast   (                      ),

    /////////////////////////////////////////
    // Master Clock Domain (Zynq Processor)
    /////////////////////////////////////////
    .s_axis_aclk    ( axis_aclk     ), // input  wire          s_axis_aclk
    .s_axis_aresetn ( axis_aresetn  ), // input  wire          s_axis_aresetn
    .s_axis_tready  ( s_axis_tready ), // output wire          s_axis_tready
    .s_axis_tvalid  ( s_axis_tvalid ), // input  wire          s_axis_tvalid
    .s_axis_tdata   ( s_axis_tdata  ), // input  wire [63 : 0] s_axis_tdata
    .s_axis_tlast   (               ),

    /// MISC
    .axis_wr_data_count ( DOWNSTREAM_axis_wr_data_count ), // output wire [31 : 0] axis_wr_data_count
    .axis_rd_data_count ( DOWNSTREAM_axis_rd_data_count )  // output wire [31 : 0] axis_rd_data_count
  );

  //////////////////////////////////////////////
  // AXI Streaming FIFO for the input signal
  //////////////////////////////////////////////
  // CODEC --|--> FIFO --|--> DMA
  audio_data_fifo audio_data_IN_fifo_inst (
    /////////////////////////////////////
    // Slave Clock Domain (Zynq Processor)
    /////////////////////////////////////
    .m_axis_aclk   ( axis_aclk     ), // input  wire          m_axis_aclk
    .m_axis_tready ( m_axis_tready ), // input  wire          m_axis_tready
    .m_axis_tvalid ( m_axis_tvalid ), // output wire          m_axis_tvalid
    .m_axis_tdata  ( m_axis_tdata  ), // output wire [63 : 0] m_axis_tdata
    .m_axis_tlast  ( m_axis_tlast  ), //

    /////////////////////////////////////////
    // Master Clock Domain (I2S Codec)
    /////////////////////////////////////////
    .s_axis_aclk    ( ac_bclk             ), // input  wire          s_axis_aclk
    .s_axis_aresetn ( axi_fifo_reset_n    ), // input  wire          s_axis_aresetn
    .s_axis_tready  ( audio_data_IN_ready ), // output wire          s_axis_tready
    .s_axis_tvalid  ( audio_data_IN_valid ), // input  wire          s_axis_tvalid
    .s_axis_tdata   ( audio_data_IN_data  ), // input  wire [63 : 0] s_axis_tdata
    .s_axis_tlast   ( audio_data_IN_last  ),

    /// MISC
    .axis_wr_data_count ( UPSTREAM_axis_wr_data_count ), // output wire [31 : 0] axis_wr_data_count
    .axis_rd_data_count ( UPSTREAM_axis_rd_data_count )  // output wire [31 : 0] axis_rd_data_count
  );

endmodule