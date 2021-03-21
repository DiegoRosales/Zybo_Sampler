// Testbench

`include "uvm_macros.svh"

`default_nettype none
module codec_unit_top_tb ();

  import uvm_pkg::*;
  import codec_unit_top_pkg::*;

  `include "codec_unit_top_testlib.svh"

  codec_unit_top_base_test base_test; // Contains the TB environment


  localparam C_S00_AXI_DATA_WIDTH = 32;
  localparam C_S00_AXI_ADDR_WIDTH = 8;

  // Interfaces
  clock_and_reset_if clock_and_reset_if0();
  i2s_if             i2s_if0(.ac_mclk(ac_mclk));
  axi4_lite_if       axi4_bfm_if0(.clock(axi_clk), .reset_n(reset));

  logic                                  board_clk;
  logic                                  reset;
  logic                                  ac_mclk;
  logic                                  axi_clk;
  logic                                  s00_axi_aresetn;
  logic [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr;
  logic [2 : 0]                          s00_axi_awprot;
  logic                                  s00_axi_awvalid;
	logic                                  s00_axi_awready;
  logic [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata;
  logic [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
  logic                                  s00_axi_wvalid;
	logic                                  s00_axi_wready;
	logic [1 : 0]                          s00_axi_bresp;
	logic                                  s00_axi_bvalid;
  logic                                  s00_axi_bready;
  logic [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr;
  logic [2 : 0]                          s00_axi_arprot;
  logic                                  s00_axi_arvalid;
	logic                                  s00_axi_arready;
	logic [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_rdata;
	logic [1 : 0]                          s00_axi_rresp;
	logic                                  s00_axi_rvalid;
  logic                                  s00_axi_rready;
  logic                                  axis_aresetn;
  logic                                  s_axis_tvalid;
  logic [32 : 0]                         s_axis_tdata;
  logic                                  m_axis_tready;
  logic                                  i2c_scl;
  logic                                  i2c_sda;

  assign board_clk       = clock_and_reset_if0.clock;
  assign reset           = clock_and_reset_if0.reset;
  assign axi_clk         = board_clk;
  assign s00_axi_aresetn = reset;

  //////////////////////////////////////////////
  ///////////// AXI4-Lite Signals //////////////
  // Ports of Axi Slave Bus Interface S00_AXI
  // Write
	assign s00_axi_awaddr       = axi4_bfm_if0.awaddr;
	assign s00_axi_awprot       = axi4_bfm_if0.awprot;
	assign s00_axi_awvalid      = axi4_bfm_if0.awvalid;
	assign axi4_bfm_if0.awready = s00_axi_awready;
	assign s00_axi_wdata        = axi4_bfm_if0.wdata;
	assign s00_axi_wstrb        = axi4_bfm_if0.wstrb;
	assign s00_axi_wvalid       = axi4_bfm_if0.wvalid;
	assign axi4_bfm_if0.wready  = s00_axi_wready;
	assign axi4_bfm_if0.bresp   = s00_axi_bresp;
	assign axi4_bfm_if0.bvalid  = s00_axi_bvalid;
	assign s00_axi_bready       = axi4_bfm_if0.bready;
  // Read
	assign s00_axi_araddr       = axi4_bfm_if0.araddr;
	assign s00_axi_arprot       = axi4_bfm_if0.arprot;
	assign s00_axi_arvalid      = axi4_bfm_if0.arvalid;
	assign axi4_bfm_if0.arready = s00_axi_arready;
	assign axi4_bfm_if0.rdata   = s00_axi_rdata;
	assign axi4_bfm_if0.rresp   = s00_axi_rresp;
	assign axi4_bfm_if0.rvalid  = s00_axi_rvalid;
	assign s00_axi_rready       = axi4_bfm_if0.rready;

  // Connect the interfaces with the driver
  // uvm_test_top is the base test
  initial begin
    uvm_config_db#(virtual i2s_if            )::set(uvm_root::get(), "uvm_test_top.test_env.i2s_agent*",             "i2s_vif",    i2s_if0);
    uvm_config_db#(virtual clock_and_reset_if)::set(uvm_root::get(), "uvm_test_top.test_env.clock_and_reset_agent*", "virtual_if", clock_and_reset_if0);
    uvm_config_db#(virtual axi4_lite_if      )::set(uvm_root::get(), "uvm_test_top.test_env.axi4_lite_agent.driver", "vif",        axi4_bfm_if0);
  end


  codec_unit_top  #(
    .C_S00_AXI_DATA_WIDTH ( C_S00_AXI_DATA_WIDTH ),
    .C_S00_AXI_ADDR_WIDTH ( C_S00_AXI_ADDR_WIDTH )
  ) dut (
    //********************************************//
    //            Board Clock Domain              //
    //********************************************//
    ///////////////////////////////////////////////
    /////////////// CLOCK AND RESET /////////////// 
    .board_clk  ( board_clk ), // 125MHz
    .reset      ( reset     ),

    // Misc
    .led_status  ( ),

    /////////////////////////////////////////////////
    ///////////// CODEC SIGNALS (Audio) ///////////// 
    // Clocks
    .ac_mclk    ( ac_mclk           ), // Master Clock
    .ac_bclk    ( i2s_if0.ac_bclk   ), // I2S Serial Clock
    // Playback
    .ac_pblrc   ( i2s_if0.ac_pblrc  ), // I2S Playback Channel Clock (Left/Right)
    .ac_pbdat   ( i2s_if0.ac_pbdat  ), // I2S Playback Data
    // Record
    .ac_recdat  ( i2s_if0.ac_recdat ), // I2S Recorded Data
    .ac_reclrc  ( i2s_if0.ac_reclrc ), // I2S Recorded Channel Clock (Left/Right)
    // Misc
    .ac_muten   ( i2s_if0.ac_muten  ), // Digital Enable (Active Low)

    /////////////////////////////////////////////////
    //////////// CODEC SIGNALS (Control) //////////// 
    .i2c_scl ( ),
    .i2c_sda ( ),


    //********************************************//
    //            AXI Clock Domain                //
    //********************************************//
    .axi_clk  ( axi_clk ),

    //////////////////////////////////////////////
    ///////////// AXI4-Lite Signals //////////////
    // Ports of Axi Slave Bus Interface S00_AXI
    .s00_axi_aresetn  ( s00_axi_aresetn ),
    .s00_axi_awaddr   ( s00_axi_awaddr  ),
    .s00_axi_awprot   ( s00_axi_awprot  ),
    .s00_axi_awvalid  ( s00_axi_awvalid ),
    .s00_axi_awready  ( s00_axi_awready ),
    .s00_axi_wdata    ( s00_axi_wdata   ),
    .s00_axi_wstrb    ( s00_axi_wstrb   ),
    .s00_axi_wvalid   ( s00_axi_wvalid  ),
    .s00_axi_wready   ( s00_axi_wready  ),
    .s00_axi_bresp    ( s00_axi_bresp   ),
    .s00_axi_bvalid   ( s00_axi_bvalid  ),
    .s00_axi_bready   ( s00_axi_bready  ),
    .s00_axi_araddr   ( s00_axi_araddr  ),
    .s00_axi_arprot   ( s00_axi_arprot  ),
    .s00_axi_arvalid  ( s00_axi_arvalid ),
    .s00_axi_arready  ( s00_axi_arready ),
    .s00_axi_rdata    ( s00_axi_rdata   ),
    .s00_axi_rresp    ( s00_axi_rresp   ),
    .s00_axi_rvalid   ( s00_axi_rvalid  ),
    .s00_axi_rready   ( s00_axi_rready  ),


    ////////////////////////////////////////////////
    ///////////// AXI Stream Signals ///////////////
    // Clock and Reset
    .axis_aresetn  ( axis_aresetn ),

    // Slave Interface Signals (DMA -> CODEC) //
    .s_axis_tready  ( ),  // Ready
    .s_axis_tvalid  ( s_axis_tvalid ),  // Data Valid (WR)
    .s_axis_tdata  ( s_axis_tdata ),   // Data

    // Master Interface Signals (CODEC -> DMA) //
    .m_axis_tready  ( m_axis_tready ),  // Ready (RD)
    .m_axis_tvalid  ( ),  // Data Valid
    .m_axis_tdata  ( ),   // Data
    .m_axis_tlast  ( ),

    ///////////////////////////
    //// Interrupt Signals ////  
    .DOWNSTREAM_almost_empty ( )
  );

  initial begin
    run_test();
  end

endmodule
`default_nettype wire