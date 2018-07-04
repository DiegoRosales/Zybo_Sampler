module codec_unit_top (
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  // Board Clock and Reset
  input wire clk, // 125MHz
  input wire reset,

  ///////////////////////////////////////////////
  ///////////////// I2S SIGNALS ///////////////// 
  output wire i2s_bclk,
  output wire i2s_wclk,
  output wire i2s_data,

  ///////////////////////////////////////////////
  ///////////////// I2C SIGNALS ///////////////// 
  output wire i2c_scl,
  inout  wire i2c_sda,

  //********************************************//

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
  output wire       controller_busy,

  ///////////////////////////////////////////////
  /////////// I2C CONTROLLER SIGNALS ////////////
  input  wire       i2c_ctrl_rd,
  input  wire [2:0] i2c_ctrl_addr,
  output wire [7:0] i2c_ctrl_data,
  
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
wire i2c_data_out;
wire i2c_rw_select;
wire i2c_data_wr;
wire i2c_data_in;
wire i2c_data_rd;
// I2C
wire        i2c_scl_i;
wire        i2c_scl_o;
wire        i2c_scl_t;
wire        i2c_sda_i;
wire        i2c_sda_o;
wire        i2c_sda_t;
wire scl_pin, sda_pin;
// wishbone
wire  [2:0] wbs_adr;   // ADR_I() address
wire  [7:0] wbs_dat_i;   // DAT_I() data in
wire  [7:0] wbs_dat_o;   // DAT_O() data out
wire        wbs_we;   // WE_I write enable input
wire        wbs_stb;   // STB_I strobe input
wire        wbs_ack;   // ACK_O acknowledge output
wire        wbs_cyc;   // CYC_I cycle input

// Synchronizer
wire       codec_rd_en_sync;
wire       codec_wr_en_sync;
wire [7:0] codec_reg_addr_sync;
wire [7:0] codec_data_wr_sync;
wire       controller_busy_sync1; 
wire       controller_busy_sync2;
wire [7:0] codec_data_rd_sync1; 
wire [7:0] codec_data_rd_sync2;
wire [2:0] i2c_ctrl_addr_sync;
wire       i2c_ctrl_rd_sync;
wire [7:0] i2c_ctrl_data_sync;

assign pll_locked = mmcm_locked;

assign i2c_scl = scl_pin;
assign scl_pin = i2c_scl_o;

assign codec_data_rd = codec_data_rd_sync2;
assign controller_busy = controller_busy_sync2;

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
  // Wishbone
  .wbs_adr_o(wbs_adr),
  .wbs_dat_o(wbs_dat_o),
  .wbs_dat_i(wbs_dat_i),
  .wbs_we_o(wbs_we),
  .wbs_stb_o(wbs_stb),
  .wbs_ack_i(wbs_ack),
  .wbs_cyc_o(wbs_cyc),

  .fifo_empty(fifo_empty),
  .i2s_busy(i2s_busy),

  // CODEC RW signals
  .codec_rd_en(codec_rd_en_sync),
  .codec_wr_en(codec_wr_en_sync),
  .codec_reg_addr(codec_reg_addr_sync),
  .codec_data_wr(codec_data_wr_sync),
  .codec_data_rd(codec_data_rd_sync1),
  .controller_busy(controller_busy_sync1),
  .i2c_ctrl_rd(i2c_ctrl_rd_sync),
  .i2c_ctrl_addr(i2c_ctrl_addr_sync),
  .i2c_ctrl_data(i2c_ctrl_data)
  //.i2c_data_out(i2c_data_out),
  //.i2c_rw_select(i2c_rw_select),
  //.i2c_data_wr(i2c_data_wr),
  //.i2c_data_in(i2c_data_in),
  //.i2c_data_rd(i2c_data_rd)
  );

i2c_master_wbs_8
#()
i2c_master_inst(
  .clk(clk_125mhz),
  .rst(reset),
  // Wishbone
  .wbs_adr_i(wbs_adr),
  .wbs_dat_i(wbs_dat_o),
  .wbs_dat_o(wbs_dat_i),
  .wbs_we_i(wbs_we),
  .wbs_stb_i(wbs_stb),
  .wbs_ack_o(wbs_ack),
  .wbs_cyc_i(wbs_cyc),

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
    .data_in(controller_busy_sync1),
    .data_out(controller_busy_sync2)
  );
  clk_sync
  #(.DATA_W(8))
  codec_data_rd_sync_inst(
    .clk1(clk_125mhz),
    .clk2(axi_clk),
    .data_in(codec_data_rd_sync1),
    .data_out(codec_data_rd_sync2)
  );

  
  // AXI to CODEC
  clk_sync codec_rd_en_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(codec_rd_en),
    .data_out(codec_rd_en_sync)
  );
  clk_sync codec_wr_en_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125),
    .data_in(codec_wr_en),
    .data_out(codec_wr_en_sync)
  );
  clk_sync  
  #(.DATA_W(8))
  codec_reg_addr_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(codec_reg_addr),
    .data_out(codec_reg_addr_sync)
  );
  clk_sync 
  #(.DATA_W(8))
  codec_data_wr_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(codec_data_wr),
    .data_out(codec_data_wr_sync)
  );

  // I2C to AXI
  clk_sync i2c_ctrl_rd_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(i2c_ctrl_rd),
    .data_out(i2c_ctrl_rd_sync)
  );
  clk_sync 
  #(.DATA_W(3))
  i2c_ctrl_addr_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(i2c_ctrl_addr),
    .data_out(i2c_ctrl_addr_sync)
  );

  // AXI to I2C
  clk_sync 
  #(.DATA_W(8))
  i2c_ctrl_data_sync_inst(
    .clk1(axi_clk),
    .clk2(clk_125mhz),
    .data_in(i2c_ctrl_data),
    .data_out(i2c_ctrl_data_sync)
  );
endmodule
