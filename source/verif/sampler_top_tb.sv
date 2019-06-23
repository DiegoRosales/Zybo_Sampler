//// Sampler Top
module sampler_top_tb (
);

//////////////////
// Clocks
//////////////////

reg clk_125  = 1'b0;
reg clk_50   = 1'b0;
reg reset    = 1'b0;
wire reset_n = ~reset;
initial force sampler_top.codec_unit.controller_unit.i2c_sda_i = 1'b0;
initial forever #(4ns) clk_125 = ~clk_125;
initial forever #(10ns) clk_50 = ~clk_50;

initial begin
   #(1ns) reset   = 1'b1;
   #(200ns) reset = 1'b0;
   #(500000ns) force   sampler_top.codec_unit.register_unit.codec_registers.controller_reset = 1'b1;
   #(500100ns) release sampler_top.codec_unit.register_unit.codec_registers.controller_reset;
   //#(128200ns) force   sampler_top.codec_unit.register_unit.axi_slave_controller_inst.codec_registers.controller_reset = 1'b0;
   //#(128300ns) release sampler_top.codec_unit.register_unit.axi_slave_controller_inst.codec_registers.controller_reset;
end

//initial begin
//  #(500ns) force sampler_top.sampler_dma_top.sampler_dma_registers.dma_base_addr[0] = 32'hbcd00000;
//  #(50500ns) force sampler_top.sampler_dma_top.sampler_dma_registers.dma_control[0] = 1;
//end

//initial begin
  //#(500ns) force sampler_top.sampler_dma_top.sampler_dma_v1_0_AXI_DMA_MASTER_inst.indiv_voice_fsm[0].dma_voice_fsm_inst = 32'hbcd00000;
  //#(50500ns) force sampler_top.sampler_dma_top.sampler_dma_v1_0_AXI_LITE_SLAVE_inst.sampler_dma_registers.dma_control[0] = 1;
//end

wire i2c_sda;
wire i2c_scl;

wire i2c_sda_pin;
wire i2c_sda_i;
wire i2c_sda_t;
assign i2c_sda_pin = 1'b0;
assign i2c_sda_t   = 1'b1;//(i2c_sda_i === 1'b0) ? 1'b1 : 1'b0;

wire codec_mclk;
wire lr_clk;
reg [5:0] counter = 'h0;
always @(posedge codec_mclk) counter <= counter + 1;
assign lr_clk = &counter;


IOBUF sda_iobuf (
  .I  (i2c_sda_pin), 
  .IO (i2c_sda  ), 
  .O  (i2c_sda_i), 
  .T  (i2c_sda_t)
  ); 

pullup(i2c_sda);
pullup(i2c_scl);

wire s_trdy;
wire m_trdy;
wire m_tvalid;
wire m_tlast;

assign m_trdy = 1'b0;//m_tvalid;

sampler_top sampler_top (
  .board_clk(clk_125),
  .reset(reset),
  .s00_axi_aclk(clk_125),
  .s00_axi_aresetn(reset_n),

  .sw({reset, reset, reset, reset}),

  .led(),

  .btn({reset, reset, reset, reset}),

  // CODEC I2S Audio Data Signals
 // .i2s_bclk(),
 // .i2s_wclk(),
 // .i2s_data(),

  // CODEC Misc Signals
  .ac_bclk(codec_mclk), // Loopback
  .ac_mclk(codec_mclk),
  .ac_muten(),
  .ac_pbdat(),
  .ac_pblrc(lr_clk),
  .ac_recdat(1'b1),
  .ac_reclrc(lr_clk),

  // CODEC I2C Control Signals
  .i2c_scl,
  .i2c_sda,

  ////////////////////////////////////////////////
  ///////////// AXI4 Stream Signals //////////////
  // Clock and Reset
  .s_axis_aclk(clk_125),
  .s_axis_aresetn(reset_n),
  // Clock and Reset
  .m_axis_aclk(clk_125),
  .m_axis_aresetn(reset_n),  

  // Slave Interface Signals (DMA -> CODEC) //
  .s_axis_tready(s_trdy),       // Ready
  .s_axis_tvalid(s_trdy),  // Data Valid (WR)
  .s_axis_tdata(64'hcafecafe_deadbeef),   // Data

  // Master Interface Signals (CODEC -> DMA) //
  .m_axis_tready(m_trdy),    // Ready (RD)
  .m_axis_tvalid(m_tvalid),  // Data Valid
  .m_axis_tdata(),         // Data
  .m_axis_tlast(m_tlast),

  .axi_dma_master_aclk    ( clk_125     ),
  .axi_dma_master_aresetn ( reset_n     ),
  .axi_lite_slave_aclk    ( clk_125     ),
  .axi_lite_slave_aresetn ( reset_n     ),
  .axi_dma_master_arready ( 1'b1        ),
  .axi_dma_master_rdata   ( 'hafaf_0000 ),
  .axi_dma_master_rid     ( 'h0         ),
  .axi_dma_master_rvalid  ( 'h0         ),
  .axi_dma_master_rlast   ( 'h0         )

);



endmodule
