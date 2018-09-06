///////////////////////////////////////////////////////////
// Codec Unit Top                                        //
// Author: Diego Rosales                                 //
///////////////////////////////////////////////////////////
// Description                                           //
//////////////                                           //
// This module controls the CODEC in the Digilent Zybo   //
// The CODEC Part Number is:                             //
// This module translates instructions into rd/wr        //
// sequences for the CODEC for easy interfacing          //
// This module is also responsible for transmitting the  //
// audio stream to the CODEC                             //
///////////////////////////////////////////////////////////
// Rev 0.1 - Init                                        //
///////////////////////////////////////////////////////////

module codec_unit_top (
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  ///////////////////////////////////////////////
  /////////////// CLOCK AND RESET /////////////// 
  input wire clk, // 125MHz
  input wire reset,

  ///////////////////////////////////////////////
  ///////////// I2S SIGNALS (Audio) ///////////// 
  output wire i2s_bclk,
  output wire i2s_wclk,
  output wire i2s_data,

  ///////////////////////////////////////////////
  //////////// I2C SIGNALS (Control) //////////// 
  output wire i2c_scl,
  inout  wire i2c_sda,


  //********************************************//
  //            AXI Clock Domain                //
  //********************************************//

  // AXI Clock
  input wire axi_clk,

  ///////////////////////////////////////////////
  //////////// CODEC CONTROL SIGNALS ////////////
  input wire       output_en,    // CODEC Output Enable

  input wire [2:0] frequency,    // Sample Frequency Select
  input wire       apply_config, // Apply Configuration

  ///////////////////////////////////////////////
  /////////// CODEC REGISTER SIGNALS ////////////
  input  wire       codec_rd_en,
  input  wire       codec_wr_en,
  input  wire [7:0] codec_reg_addr,
  input  wire [7:0] codec_data_wr,
  output wire [7:0] codec_data_rd,
  output wire       codec_data_rd_valid,

  ///////////////////////////////////////////////
  /////////// I2C CONTROLLER SIGNALS ////////////
  input  wire       i2c_ctrl_rd,
  input  wire [2:0] i2c_ctrl_addr,
  output wire [7:0] i2c_ctrl_data,
  output wire       controller_busy,
  
  ///////////////////////////////////////////////
  ///////////// CODEC DATA SIGNALS //////////////    
  input wire [47:0] data_in, // Audio Data
  input wire        data_wr, // Data Write to the data FIFO

  ///////////////////////////////////////////////
  ////////// CODEC UNIT STATUS SIGNALS ////////// 
  output wire pll_locked

  //********************************************//

);

wire [47:0] fifo_data;
wire fifo_rd;
wire mmcm_locked;
wire clk_24mhz;
wire clk_125mhz;
wire clk_44_1_24b;
wire clk_48_16b;
wire clk_48_24b;
wire fifo_empty;
wire i2s_busy;

// I2C
wire        i2c_scl_i;
wire        i2c_scl_o;
wire        i2c_scl_t;
wire        i2c_sda_i;
wire        i2c_sda_o;
wire        i2c_sda_t;
wire scl_pin, sda_pin;

// Synchronizer
wire       codec_rd_en_SYNC;
wire       codec_wr_en_SYNC;
wire [7:0] codec_reg_addr_SYNC;
wire [7:0] codec_data_wr_SYNC;
wire       controller_busy_SYNC; 
wire       codec_data_rd_valid_SYNC;
wire [7:0] codec_data_rd_SYNC; 
wire [2:0] i2c_ctrl_addr_SYNC;
wire       i2c_ctrl_rd_SYNC;
wire [7:0] i2c_ctrl_data_SYNC;

assign pll_locked = mmcm_locked;

assign i2c_scl = scl_pin;
assign scl_pin = i2c_scl_o;

IOBUF sda_iobuf (
    .I  (i2c_scl_i), 
    .IO (i2c_sda), 
    .O  (i2c_scl_o), 
    .T  (i2c_scl_t));   

IOBUF scl_iobuf (
  .I  (i2c_scl_i), 
  .IO (i2c_sda), 
  .O  (i2c_scl_o), 
  .T  (i2c_scl_t));   

controller_unit_top controller_unit(
  .clk(clk_125mhz),
  .reset(reset),

  // CODEC RW signals
  .codec_rd_en(codec_rd_en_SYNC),                  // Input
  .codec_wr_en(codec_wr_en_SYNC),                  // Input
  .codec_reg_addr(codec_reg_addr_SYNC),            // Input
  .codec_data_wr(codec_data_wr_SYNC),              // Input
  .codec_data_rd(codec_data_rd_SYNC),             // Output
  .codec_data_rd_valid(codec_data_rd_valid_SYNC), // Output
  .controller_busy(controller_busy_SYNC),         // Output

  // I2C Signals
  .i2c_scl_i(i2c_scl_i),
  .i2c_scl_o(i2c_scl_o),
  .i2c_scl_t(i2c_scl_t),
  .i2c_sda_i(i2c_sda_i),
  .i2c_sda_o(i2c_sda_o),
  .i2c_sda_t(i2c_sda_t)
  );


i2s_controller i2s_controller(
  .clk(clk_24mhz),
  .reset(reset),
  .data(fifo_data),
  .data_rd(fifo_rd),
  .i2s_bclk(i2s_bclk),
  .i2s_wclk(i2s_wclk),
  .i2s_data(i2s_data));

i2s_fifo_48x64 fifo (
  .clk(clk_125mhz),       // input wire clk
  .srst(reset),           // input wire srst
  .din(data_in),          // input wire [47 : 0] din
  .wr_en(data_wr),        // input wire wr_en
  .rd_en(fifo_rd),        // input wire rd_en
  .dout(fifo_data),       // output wire [47 : 0] dout
  .full(),                // output wire full
  .almost_full(),         // output wire almost_full
  .empty(fifo_empty)      // output wire empty
);

  audio_clk_mmcm audio_clk_mmcm(
  // Clock out ports
  //.clk_out1(clk_44_1_16b),
  .clk_out1(clk_24mhz),
  .clk_out2(clk_125mhz),
  // .clk_out3(clk_48_16b),
  // .clk_out4(clk_48_24b),
  // Status and control signals
  .reset(1'b0),
  .locked(mmcm_locked),
 // Clock in ports
  .clk_in1(clk)
  );


//---- Synchronizers --------//

    // CODEC to AXI
  clk_sync controller_busy_sync_inst(
    .clk1(clk_125mhz),
    .clk2(axi_clk),
    .data_in(controller_busy_SYNC),
    .data_out(controller_busy)
  );

  clk_sync codec_data_rd_valid_sync_inst(
    .clk1(clk_125mhz),
    .clk2(axi_clk),
    .data_in(codec_data_rd_SYNC),
    .data_out(codec_data_rd)
  );

  clk_sync
  #(.DATA_W(8))
  codec_data_rd_sync_inst(
    .clk1(clk_125mhz),
    .clk2(axi_clk),
    .data_in(codec_data_rd_SYNC),
    .data_out(codec_data_rd)
  );

  
  // AXI to CODEC
  clk_sync codec_rd_en_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(codec_rd_en),
    .data_out(codec_rd_en_SYNC)
  );
  clk_sync codec_wr_en_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125),
    .data_in(codec_wr_en),
    .data_out(codec_wr_en_SYNC)
  );
  clk_sync  
  #(.DATA_W(8))
  codec_reg_addr_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(codec_reg_addr),
    .data_out(codec_reg_addr_SYNC)
  );
  clk_sync 
  #(.DATA_W(8))
  codec_data_wr_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(codec_data_wr),
    .data_out(codec_data_wr_SYNC)
  );

  // I2C to AXI
  clk_sync i2c_ctrl_rd_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(i2c_ctrl_rd),
    .data_out(i2c_ctrl_rd_SYNC)
  );
  clk_sync 
  #(.DATA_W(3))
  i2c_ctrl_addr_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(i2c_ctrl_addr),
    .data_out(i2c_ctrl_addr_SYNC)
  );

  // AXI to I2C
  clk_sync 
  #(.DATA_W(8))
  i2c_ctrl_data_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(i2c_ctrl_data),
    .data_out(i2c_ctrl_data_SYNC)
  );
endmodule
