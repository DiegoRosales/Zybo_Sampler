//// Sampler Top
module sampler_top #(
  // Max Voices
  parameter MAX_VOICES = 4,
  ///////////////////////
  parameter C_S00_AXI_DATA_WIDTH = 32,
  parameter C_S00_AXI_ADDR_WIDTH = 8,

  // Parameters of Axi Master Bus Interface AXI_DMA_MASTER
  parameter  C_AXI_DMA_MASTER_TARGET_SLAVE_BASE_ADDR = 32'h40000000,
  parameter integer C_AXI_DMA_MASTER_BURST_LEN       = 16,
  parameter integer C_AXI_DMA_MASTER_ID_WIDTH        = 6,
  parameter integer C_AXI_DMA_MASTER_ADDR_WIDTH      = 32,
  parameter integer C_AXI_DMA_MASTER_DATA_WIDTH      = 32,
  parameter integer C_AXI_DMA_MASTER_AWUSER_WIDTH    = 0,
  parameter integer C_AXI_DMA_MASTER_ARUSER_WIDTH    = 0,
  parameter integer C_AXI_DMA_MASTER_WUSER_WIDTH     = 0,
  parameter integer C_AXI_DMA_MASTER_RUSER_WIDTH     = 0,
  parameter integer C_AXI_DMA_MASTER_BUSER_WIDTH     = 0,

  // Parameters of Axi Master Bus Interface AXI_STREAM_MASTER
  parameter integer C_AXI_STREAM_MASTER_TDATA_WIDTH = 32,
  parameter integer C_AXI_STREAM_MASTER_START_COUNT = 32,

  // Parameters of Axi Slave Bus Interface AXI_LITE_SLAVE
  parameter integer C_AXI_LITE_SLAVE_DATA_WIDTH = 32,
  parameter integer C_AXI_LITE_SLAVE_ADDR_WIDTH = 13,

  // Parameters of Axi Slave Bus Interface S_AXI_INTR
  parameter integer C_S_AXI_INTR_DATA_WIDTH = 32,
  parameter integer C_S_AXI_INTR_ADDR_WIDTH = 5,
  parameter integer C_NUM_OF_INTR           = 1,
  parameter         C_INTR_SENSITIVITY      = 32'hFFFFFFFF,
  parameter         C_INTR_ACTIVE_STATE     = 32'hFFFFFFFF,
  parameter integer C_IRQ_SENSITIVITY       = 1,
  parameter integer C_IRQ_ACTIVE_STATE      = 1      

) (
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  //// Clocks and Resets
  input wire board_clk,
  input wire reset,

  //// GPIOs
  // Switches
  input wire sw[3:0],
  // Push Buttons
  input wire btn[3:0],
  // LEDs
  output wire led[3:0],

  /////////////////////////////////////////////////
  ///////////// CODEC SIGNALS (Audio) ///////////// 
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

  /////////////////////////////////////////////////
  //////////// CODEC SIGNALS (Control) //////////// 
  inout wire i2c_scl,
  inout wire i2c_sda,

  //********************************************//
  //            AXI Clock Domain                //
  //********************************************//
  // Ports of Axi Slave Bus Interface S00_AXI
	input  wire                                  s00_axi_aclk,
	input  wire                                  s00_axi_aresetn,
	input  wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr,
	input  wire [2 : 0]                          s00_axi_awprot,
	input  wire                                  s00_axi_awvalid,
	output wire                                  s00_axi_awready,
	input  wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata,
	input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input  wire                                  s00_axi_wvalid,
	output wire                                  s00_axi_wready,
	output wire [1 : 0]                          s00_axi_bresp,
	output wire                                  s00_axi_bvalid,
	input  wire                                  s00_axi_bready,
	input  wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr,
	input  wire [2 : 0]                          s00_axi_arprot,
	input  wire                                  s00_axi_arvalid,
	output wire                                  s00_axi_arready,
	output wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_rdata,
	output wire [1 : 0]                          s00_axi_rresp,
	output wire                                  s00_axi_rvalid,
	input  wire                                  s00_axi_rready,

  ////////////////////////////////////////////////
  ///////////// AXI4 Stream Signals //////////////
  // Clock and Reset
  input  wire          s_axis_aclk,
  input  wire          s_axis_aresetn,
  // Clock and Reset
  input  wire          m_axis_aclk,
  input  wire          m_axis_aresetn,  

  // Slave Interface Signals (DMA -> CODEC) //
  output wire          s_axis_tready,  // Ready
  input  wire          s_axis_tvalid,  // Data Valid (WR)
  input  wire [63 : 0] s_axis_tdata,   // Data

  // Master Interface Signals (CODEC -> DMA) //
  input  wire          m_axis_tready,  // Ready (RD)
  output wire          m_axis_tvalid,  // Data Valid
  output wire [63 : 0] m_axis_tdata,   // Data
  output wire          m_axis_tlast,

  ///////////////////////////
  //// Interrupt Signals ////
  ///////////////////////////
  output wire DOWNSTREAM_almost_empty,
  
  ////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////// Sampler DMA Signals /////////////////////////////

  ///////////////////////////////////////////////////////////
  // Ports of Axi Master Bus Interface AXI_DMA_MASTER
  ///////////////////////////////////////////////////////////
  input  wire                                       axi_dma_master_init_axi_txn ,
  output wire                                       axi_dma_master_txn_done     ,
  output wire                                       axi_dma_master_error        ,
  input  wire                                       axi_dma_master_aclk         ,
  input  wire                                       axi_dma_master_aresetn      ,
  output wire [C_AXI_DMA_MASTER_ID_WIDTH-1 : 0]     axi_dma_master_awid         ,
  output wire [C_AXI_DMA_MASTER_ADDR_WIDTH-1 : 0]   axi_dma_master_awaddr       ,
  output wire [7 : 0]                               axi_dma_master_awlen        ,
  output wire [2 : 0]                               axi_dma_master_awsize       ,
  output wire [1 : 0]                               axi_dma_master_awburst      ,
  output wire                                       axi_dma_master_awlock       ,
  output wire [3 : 0]                               axi_dma_master_awcache      ,
  output wire [2 : 0]                               axi_dma_master_awprot       ,
  output wire [3 : 0]                               axi_dma_master_awqos        ,
  output wire [C_AXI_DMA_MASTER_AWUSER_WIDTH-1 : 0] axi_dma_master_awuser       ,
  output wire                                       axi_dma_master_awvalid      ,
  input  wire                                       axi_dma_master_awready      ,
  output wire [C_AXI_DMA_MASTER_DATA_WIDTH-1 : 0]   axi_dma_master_wdata        ,
  output wire [C_AXI_DMA_MASTER_DATA_WIDTH/8-1 : 0] axi_dma_master_wstrb        ,
  output wire                                       axi_dma_master_wlast        ,
  output wire [C_AXI_DMA_MASTER_WUSER_WIDTH-1 : 0]  axi_dma_master_wuser        ,
  output wire                                       axi_dma_master_wvalid       ,
  input  wire                                       axi_dma_master_wready       ,
  input  wire [C_AXI_DMA_MASTER_ID_WIDTH-1 : 0]     axi_dma_master_bid          ,
  input  wire [1 : 0]                               axi_dma_master_bresp        ,
  input  wire [C_AXI_DMA_MASTER_BUSER_WIDTH-1 : 0]  axi_dma_master_buser        ,
  input  wire                                       axi_dma_master_bvalid       ,
  output wire                                       axi_dma_master_bready       ,
  output wire [C_AXI_DMA_MASTER_ID_WIDTH-1 : 0]     axi_dma_master_arid         ,
  output wire [C_AXI_DMA_MASTER_ADDR_WIDTH-1 : 0]   axi_dma_master_araddr       ,
  output wire [7 : 0]                               axi_dma_master_arlen        ,
  output wire [2 : 0]                               axi_dma_master_arsize       ,
  output wire [1 : 0]                               axi_dma_master_arburst      ,
  output wire                                       axi_dma_master_arlock       ,
  output wire [3 : 0]                               axi_dma_master_arcache      ,
  output wire [2 : 0]                               axi_dma_master_arprot       ,
  output wire [3 : 0]                               axi_dma_master_arqos        ,
  output wire [C_AXI_DMA_MASTER_ARUSER_WIDTH-1 : 0] axi_dma_master_aruser       ,
  output wire                                       axi_dma_master_arvalid      ,
  input  wire                                       axi_dma_master_arready      ,
  input  wire [C_AXI_DMA_MASTER_ID_WIDTH-1 : 0]     axi_dma_master_rid          ,
  input  wire [C_AXI_DMA_MASTER_DATA_WIDTH-1 : 0]   axi_dma_master_rdata        ,
  input  wire [1 : 0]                               axi_dma_master_rresp        ,
  input  wire                                       axi_dma_master_rlast        ,
  input  wire [C_AXI_DMA_MASTER_RUSER_WIDTH-1 : 0]  axi_dma_master_ruser        ,
  input  wire                                       axi_dma_master_rvalid       ,
  output wire                                       axi_dma_master_rready       ,

  ///////////////////////////////////////////////////////////
  // Ports of Axi Master Bus Interface AXI_STREAM_MASTER
  ///////////////////////////////////////////////////////////
  // Not needed ATM // input  wire                                             axi_stream_master_aclk    ,
  // Not needed ATM // input  wire                                             axi_stream_master_aresetn ,
  // Not needed ATM // output wire                                             axi_stream_master_tvalid  ,
  // Not needed ATM // output wire [C_AXI_STREAM_MASTER_TDATA_WIDTH-1 : 0]     axi_stream_master_tdata   ,
  // Not needed ATM // output wire [(C_AXI_STREAM_MASTER_TDATA_WIDTH/8)-1 : 0] axi_stream_master_tstrb   ,
  // Not needed ATM // output wire                                             axi_stream_master_tlast   ,
  // Not needed ATM // input  wire                                             axi_stream_master_tready  ,

  ///////////////////////////////////////////////////////////
  // Ports of Axi Slave Bus Interface AXI_LITE_SLAVE
  ///////////////////////////////////////////////////////////
  input  wire                                         axi_lite_slave_aclk    ,
  input  wire                                         axi_lite_slave_aresetn ,
  input  wire [C_AXI_LITE_SLAVE_ADDR_WIDTH-1 : 0]     axi_lite_slave_awaddr  ,
  input  wire [2 : 0]                                 axi_lite_slave_awprot  ,
  input  wire                                         axi_lite_slave_awvalid ,
  output wire                                         axi_lite_slave_awready ,
  input  wire [C_AXI_LITE_SLAVE_DATA_WIDTH-1 : 0]     axi_lite_slave_wdata   ,
  input  wire [(C_AXI_LITE_SLAVE_DATA_WIDTH/8)-1 : 0] axi_lite_slave_wstrb   ,
  input  wire                                         axi_lite_slave_wvalid  ,
  output wire                                         axi_lite_slave_wready  ,
  output wire [1 : 0]                                 axi_lite_slave_bresp   ,
  output wire                                         axi_lite_slave_bvalid  ,
  input  wire                                         axi_lite_slave_bready  ,
  input  wire [C_AXI_LITE_SLAVE_ADDR_WIDTH-1 : 0]     axi_lite_slave_araddr  ,
  input  wire [2 : 0]                                 axi_lite_slave_arprot  ,
  input  wire                                         axi_lite_slave_arvalid ,
  output wire                                         axi_lite_slave_arready ,
  output wire [C_AXI_LITE_SLAVE_DATA_WIDTH-1 : 0]     axi_lite_slave_rdata   ,
  output wire [1 : 0]                                 axi_lite_slave_rresp   ,
  output wire                                         axi_lite_slave_rvalid  ,
  input  wire                                         axi_lite_slave_rready  

  ///////////////////////////////////////////////////////////
  // Ports of Axi Slave Bus Interface S_AXI_INTR
  ///////////////////////////////////////////////////////////
// Not needed ATM //  input  wire                                     s_axi_intr_aclk    ,
// Not needed ATM //  input  wire                                     s_axi_intr_aresetn ,
// Not needed ATM //  input  wire [C_S_AXI_INTR_ADDR_WIDTH-1 : 0]     s_axi_intr_awaddr  ,
// Not needed ATM //  input  wire [2 : 0]                             s_axi_intr_awprot  ,
// Not needed ATM //  input  wire                                     s_axi_intr_awvalid ,
// Not needed ATM //  output wire                                     s_axi_intr_awready ,
// Not needed ATM //  input  wire [C_S_AXI_INTR_DATA_WIDTH-1 : 0]     s_axi_intr_wdata   ,
// Not needed ATM //  input  wire [(C_S_AXI_INTR_DATA_WIDTH/8)-1 : 0] s_axi_intr_wstrb   ,
// Not needed ATM //  input  wire                                     s_axi_intr_wvalid  ,
// Not needed ATM //  output wire                                     s_axi_intr_wready  ,
// Not needed ATM //  output wire [1 : 0]                             s_axi_intr_bresp   ,
// Not needed ATM //  output wire                                     s_axi_intr_bvalid  ,
// Not needed ATM //  input  wire                                     s_axi_intr_bready  ,
// Not needed ATM //  input  wire [C_S_AXI_INTR_ADDR_WIDTH-1 : 0]     s_axi_intr_araddr  ,
// Not needed ATM //  input  wire [2 : 0]                             s_axi_intr_arprot  ,
// Not needed ATM //  input  wire                                     s_axi_intr_arvalid ,
// Not needed ATM //  output wire                                     s_axi_intr_arready ,
// Not needed ATM //  output wire [C_S_AXI_INTR_DATA_WIDTH-1 : 0]     s_axi_intr_rdata   ,
// Not needed ATM //  output wire [1 : 0]                             s_axi_intr_rresp   ,
// Not needed ATM //  output wire                                     s_axi_intr_rvalid  ,
// Not needed ATM //  input  wire                                     s_axi_intr_rready  ,
// Not needed ATM //  output wire                                     irq

);

///////////////////////////////////////////
//// AXI Clock and Reset Signals
//// They all come from the same clock and reset
///////////////////////////////////////////
//// Clocks
//wire axi_dma_master_aclk       = s00_axi_aclk;
//wire axi_stream_master_aclk    = s00_axi_aclk;
//wire axi_lite_slave_aclk       = s00_axi_aclk;
//wire s_axi_intr_aclk           = s00_axi_aclk;
//// Resets
//wire axi_dma_master_aresetn    = s00_axi_aresetn;
//wire axi_stream_master_aresetn = s00_axi_aresetn;
//wire axi_lite_slave_aresetn    = s00_axi_aresetn;
//wire s_axi_intr_aresetn        = s00_axi_aresetn;
//////////////////////////////////////////


wire controller_busy;
wire init_done;
wire init_error;
wire missed_ack;
wire pll_locked;

wire [3:0]  led_status;

///////////////////////////////////
// Signals between the DMA FIFO and output FIFO
///////////////////////////////////
// Internal AXIS signals
wire [ 63 : 0 ] s_axis_tdata_int;
wire            s_axis_tready_int;
wire            s_axis_tvalid_int;
// DMA FIFO Read Signals
wire [ C_AXI_DMA_MASTER_DATA_WIDTH - 1 : 0 ] fifo_data_out;
wire                                         fifo_data_available;
wire                                         fifo_data_read;


assign led[0] = (sw[0] == 1) ? init_done      : led_status[0];
assign led[1] = (sw[0] == 1) ? init_error     : led_status[1];
assign led[2] = (sw[0] == 1) ? missed_ack     : led_status[2];
assign led[3] = (sw[0] == 1) ? controller_busy: led_status[3];

//assign m_axis_tlast = ~m_axis_tvalid;

codec_unit_top #(
  .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
) codec_unit(
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  // Board Clock and Reset
  .board_clk, // 50MHz
  .reset(btn[3]),

  // Misc
  .led_status,
  .test_mode(sw[3]),
  .justification(sw[2]),

  /////////////////////////////////////////////////
  ///////////// CODEC SIGNALS (Audio) ///////////// 
  // Clocks
  .ac_mclk  , // Master Clock
  .ac_bclk  , // I2S Serial Clock
  // Playback
  .ac_pblrc , // I2S Playback Channel Clock (Left/Right)
  .ac_pbdat , // I2S Playback Data
  // Record
  .ac_recdat, // I2S Recorded Data
  .ac_reclrc, // I2S Recorded Channel Clock (Left/Right)
  // Misc
  .ac_muten , // Digital Enable (Active Low)

  /////////////////////////////////////////////////
  //////////// CODEC SIGNALS (Control) //////////// 
  .i2c_scl,
  .i2c_sda,

  //********************************************//

  //********************************************//
  //            AXI Clock Domain                //
  //********************************************//

  // AXI Clock
  .axi_clk(clk_125),

  ///////////////////////////////////////////////
  /////////// I2C CONTROLLER SIGNALS ////////////
  .controller_busy,
  .init_done,
  .init_error,
  .missed_ack,
  
  ///////////////////////////////////////////////
  ///////////// CODEC DATA SIGNALS //////////////    

  ///////////////////////////////////////////////
  ////////// CODEC UNIT STATUS SIGNALS ////////// 
  .pll_locked,

  //********************************************//
  //---- AXI Clock Domain ----//
  .s00_axi_aclk,
  .s00_axi_aresetn,
  .s00_axi_awaddr,
  .s00_axi_awprot,
  .s00_axi_awvalid,
  .s00_axi_awready,
  .s00_axi_wdata,
  .s00_axi_wstrb,
  .s00_axi_wvalid,
  .s00_axi_wready,
  .s00_axi_bresp,
  .s00_axi_bvalid,
  .s00_axi_bready,
  .s00_axi_araddr,
  .s00_axi_arprot,
  .s00_axi_arvalid,
  .s00_axi_arready,
  .s00_axi_rdata,
  .s00_axi_rresp,
  .s00_axi_rvalid,
  .s00_axi_rready,

  ////////////////////////////////////////////////
  ///////////// AXI4 Stream Signals //////////////
  // Clock and Reset
  .axis_aclk    (s_axis_aclk   ), // input wire s_axis_aclk
  .axis_aresetn (s_axis_aresetn), // input wire s_axis_aresetn

  // Slave Interface Signals (DMA -> CODEC) //
  .s_axis_tready ( s_axis_tready_int ), // Ready
  .s_axis_tvalid ( s_axis_tvalid_int ), // Data Valid (WR)
  .s_axis_tdata  ( s_axis_tdata_int  ), // Data

  // Master Interface Signals (CODEC -> DMA) //
  .m_axis_tready , // Ready (RD)
  .m_axis_tvalid , // Data Valid
  .m_axis_tdata  , // Data
  .m_axis_tlast  ,

  ///////////////////////////
  //// Interrupt Signals ////
  ///////////////////////////
  .DOWNSTREAM_almost_empty

  );


  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////// Sampler DMA Signals /////////////////////////////

  // Glue logic for the AXIS FIFO in the CODEC interface
  assign fifo_data_read    = s_axis_tready_int;
  assign s_axis_tvalid_int = fifo_data_available;
  assign s_axis_tdata_int  = {16'h0, fifo_data_out[31:16], 16'h0, fifo_data_out[15:0]}; // 16 bit audio support at the moment

  sampler_dma_top #(
    .MAX_VOICES ( MAX_VOICES ),
    // Parameters of Axi Master Bus Interface AXI_DMA_MASTER
    .C_AXI_DMA_MASTER_TARGET_SLAVE_BASE_ADDR (C_AXI_DMA_MASTER_TARGET_SLAVE_BASE_ADDR),
    .C_AXI_DMA_MASTER_BURST_LEN              (C_AXI_DMA_MASTER_BURST_LEN             ),
    .C_AXI_DMA_MASTER_ID_WIDTH               (C_AXI_DMA_MASTER_ID_WIDTH              ),
    .C_AXI_DMA_MASTER_ADDR_WIDTH             (C_AXI_DMA_MASTER_ADDR_WIDTH            ),
    .C_AXI_DMA_MASTER_DATA_WIDTH             (C_AXI_DMA_MASTER_DATA_WIDTH            ),
    .C_AXI_DMA_MASTER_AWUSER_WIDTH           (C_AXI_DMA_MASTER_AWUSER_WIDTH          ),
    .C_AXI_DMA_MASTER_ARUSER_WIDTH           (C_AXI_DMA_MASTER_ARUSER_WIDTH          ),
    .C_AXI_DMA_MASTER_WUSER_WIDTH            (C_AXI_DMA_MASTER_WUSER_WIDTH           ),
    .C_AXI_DMA_MASTER_RUSER_WIDTH            (C_AXI_DMA_MASTER_RUSER_WIDTH           ),
    .C_AXI_DMA_MASTER_BUSER_WIDTH            (C_AXI_DMA_MASTER_BUSER_WIDTH           ),

    // Parameters of Axi Master Bus Interface AXI_STREAM_MASTER
    .C_AXI_STREAM_MASTER_TDATA_WIDTH(C_AXI_STREAM_MASTER_TDATA_WIDTH),
    .C_AXI_STREAM_MASTER_START_COUNT(C_AXI_STREAM_MASTER_START_COUNT),

    // Parameters of Axi Slave Bus Interface AXI_LITE_SLAVE
    .C_AXI_LITE_SLAVE_DATA_WIDTH (C_AXI_LITE_SLAVE_DATA_WIDTH),
    .C_AXI_LITE_SLAVE_ADDR_WIDTH (C_AXI_LITE_SLAVE_ADDR_WIDTH),

    // Parameters of Axi Slave Bus Interface S_AXI_INTR
    .C_S_AXI_INTR_DATA_WIDTH (C_S_AXI_INTR_DATA_WIDTH),
    .C_S_AXI_INTR_ADDR_WIDTH (C_S_AXI_INTR_ADDR_WIDTH),
    .C_NUM_OF_INTR           (C_NUM_OF_INTR          ),
    .C_INTR_SENSITIVITY      (C_INTR_SENSITIVITY     ),
    .C_INTR_ACTIVE_STATE     (C_INTR_ACTIVE_STATE    ),
    .C_IRQ_SENSITIVITY       (C_IRQ_SENSITIVITY      ),
    .C_IRQ_ACTIVE_STATE      (C_IRQ_ACTIVE_STATE     )

  ) sampler_dma_top (
    // Output FIFO Read signals
    .fifo_data_out       ( fifo_data_out       ),
    .fifo_data_available ( fifo_data_available ),
    .fifo_data_read      ( fifo_data_read      ),
    // AXI Signals
    .axi_dma_master_init_axi_txn (axi_dma_master_init_axi_txn) ,
    .axi_dma_master_txn_done     (axi_dma_master_txn_done    ) ,
    .axi_dma_master_error        (axi_dma_master_error       ) ,
    .axi_dma_master_aclk         (axi_dma_master_aclk        ) ,
    .axi_dma_master_aresetn      (axi_dma_master_aresetn     ) ,
    .axi_dma_master_awid         (axi_dma_master_awid        ) ,
    .axi_dma_master_awaddr       (axi_dma_master_awaddr      ) ,
    .axi_dma_master_awlen        (axi_dma_master_awlen       ) ,
    .axi_dma_master_awsize       (axi_dma_master_awsize      ) ,
    .axi_dma_master_awburst      (axi_dma_master_awburst     ) ,
    .axi_dma_master_awlock       (axi_dma_master_awlock      ) ,
    .axi_dma_master_awcache      (axi_dma_master_awcache     ) ,
    .axi_dma_master_awprot       (axi_dma_master_awprot      ) ,
    .axi_dma_master_awqos        (axi_dma_master_awqos       ) ,
    .axi_dma_master_awuser       (axi_dma_master_awuser      ) ,
    .axi_dma_master_awvalid      (axi_dma_master_awvalid     ) ,
    .axi_dma_master_awready      (axi_dma_master_awready     ) ,
    .axi_dma_master_wdata        (axi_dma_master_wdata       ) ,
    .axi_dma_master_wstrb        (axi_dma_master_wstrb       ) ,
    .axi_dma_master_wlast        (axi_dma_master_wlast       ) ,
    .axi_dma_master_wuser        (axi_dma_master_wuser       ) ,
    .axi_dma_master_wvalid       (axi_dma_master_wvalid      ) ,
    .axi_dma_master_wready       (axi_dma_master_wready      ) ,
    .axi_dma_master_bid          (axi_dma_master_bid         ) ,
    .axi_dma_master_bresp        (axi_dma_master_bresp       ) ,
    .axi_dma_master_buser        (axi_dma_master_buser       ) ,
    .axi_dma_master_bvalid       (axi_dma_master_bvalid      ) ,
    .axi_dma_master_bready       (axi_dma_master_bready      ) ,
    .axi_dma_master_arid         (axi_dma_master_arid        ) ,
    .axi_dma_master_araddr       (axi_dma_master_araddr      ) ,
    .axi_dma_master_arlen        (axi_dma_master_arlen       ) ,
    .axi_dma_master_arsize       (axi_dma_master_arsize      ) ,
    .axi_dma_master_arburst      (axi_dma_master_arburst     ) ,
    .axi_dma_master_arlock       (axi_dma_master_arlock      ) ,
    .axi_dma_master_arcache      (axi_dma_master_arcache     ) ,
    .axi_dma_master_arprot       (axi_dma_master_arprot      ) ,
    .axi_dma_master_arqos        (axi_dma_master_arqos       ) ,
    .axi_dma_master_aruser       (axi_dma_master_aruser      ) ,
    .axi_dma_master_arvalid      (axi_dma_master_arvalid     ) ,
    .axi_dma_master_arready      (axi_dma_master_arready     ) ,
    .axi_dma_master_rid          (axi_dma_master_rid         ) ,
    .axi_dma_master_rdata        (axi_dma_master_rdata       ) ,
    .axi_dma_master_rresp        (axi_dma_master_rresp       ) ,
    .axi_dma_master_rlast        (axi_dma_master_rlast       ) ,
    .axi_dma_master_ruser        (axi_dma_master_ruser       ) ,
    .axi_dma_master_rvalid       (axi_dma_master_rvalid      ) ,
    .axi_dma_master_rready       (axi_dma_master_rready      ) ,

    ///////////////////////////////////////////////////////////
    // Ports of Axi Master Bus Interface AXI_STREAM_MASTER
    ///////////////////////////////////////////////////////////
   .axi_stream_master_aclk    ( ), // Not needed ATM // ( axi_stream_master_aclk    ) ,
   .axi_stream_master_aresetn ( ), // Not needed ATM // ( axi_stream_master_aresetn ) ,
   .axi_stream_master_tvalid  ( ), // Not needed ATM // ( axi_stream_master_tvalid  ) ,
   .axi_stream_master_tdata   ( ), // Not needed ATM // ( axi_stream_master_tdata   ) ,
   .axi_stream_master_tstrb   ( ), // Not needed ATM // ( axi_stream_master_tstrb   ) ,
   .axi_stream_master_tlast   ( ), // Not needed ATM // ( axi_stream_master_tlast   ) ,
   .axi_stream_master_tready  ( ), // Not needed ATM // ( axi_stream_master_tready  ) ,

    ///////////////////////////////////////////////////////////
    // Ports of Axi Slave Bus Interface AXI_LITE_SLAVE
    ///////////////////////////////////////////////////////////
    .axi_lite_slave_aclk    (axi_lite_slave_aclk    ),
    .axi_lite_slave_aresetn (axi_lite_slave_aresetn ),
    .axi_lite_slave_awaddr  (axi_lite_slave_awaddr  ),
    .axi_lite_slave_awprot  (axi_lite_slave_awprot  ),
    .axi_lite_slave_awvalid (axi_lite_slave_awvalid ),
    .axi_lite_slave_awready (axi_lite_slave_awready ),
    .axi_lite_slave_wdata   (axi_lite_slave_wdata   ),
    .axi_lite_slave_wstrb   (axi_lite_slave_wstrb   ),
    .axi_lite_slave_wvalid  (axi_lite_slave_wvalid  ),
    .axi_lite_slave_wready  (axi_lite_slave_wready  ),
    .axi_lite_slave_bresp   (axi_lite_slave_bresp   ),
    .axi_lite_slave_bvalid  (axi_lite_slave_bvalid  ),
    .axi_lite_slave_bready  (axi_lite_slave_bready  ),
    .axi_lite_slave_araddr  (axi_lite_slave_araddr  ),
    .axi_lite_slave_arprot  (axi_lite_slave_arprot  ),
    .axi_lite_slave_arvalid (axi_lite_slave_arvalid ),
    .axi_lite_slave_arready (axi_lite_slave_arready ),
    .axi_lite_slave_rdata   (axi_lite_slave_rdata   ),
    .axi_lite_slave_rresp   (axi_lite_slave_rresp   ),
    .axi_lite_slave_rvalid  (axi_lite_slave_rvalid  ),
    .axi_lite_slave_rready  (axi_lite_slave_rready  )

    ///////////////////////////////////////////////////////////
    // Ports of Axi Slave Bus Interface S_AXI_INTR
    ///////////////////////////////////////////////////////////
//    .s_axi_intr_aclk    (s_axi_intr_aclk    ),
//    .s_axi_intr_aresetn (s_axi_intr_aresetn ),
//    .s_axi_intr_awaddr  (s_axi_intr_awaddr  ),
//    .s_axi_intr_awprot  (s_axi_intr_awprot  ),
//    .s_axi_intr_awvalid (s_axi_intr_awvalid ),
//    .s_axi_intr_awready (s_axi_intr_awready ),
//    .s_axi_intr_wdata   (s_axi_intr_wdata   ),
//    .s_axi_intr_wstrb   (s_axi_intr_wstrb   ),
//    .s_axi_intr_wvalid  (s_axi_intr_wvalid  ),
//    .s_axi_intr_wready  (s_axi_intr_wready  ),
//    .s_axi_intr_bresp   (s_axi_intr_bresp   ),
//    .s_axi_intr_bvalid  (s_axi_intr_bvalid  ),
//    .s_axi_intr_bready  (s_axi_intr_bready  ),
//    .s_axi_intr_araddr  (s_axi_intr_araddr  ),
//    .s_axi_intr_arprot  (s_axi_intr_arprot  ),
//    .s_axi_intr_arvalid (s_axi_intr_arvalid ),
//    .s_axi_intr_arready (s_axi_intr_arready ),
//    .s_axi_intr_rdata   (s_axi_intr_rdata   ),
//    .s_axi_intr_rresp   (s_axi_intr_rresp   ),
//    .s_axi_intr_rvalid  (s_axi_intr_rvalid  ),
//    .s_axi_intr_rready  (s_axi_intr_rready  ),
//    .irq                (irq                ) 
  );



endmodule
