///////////////////////////////////////////////////////////////
// Sampler DMA Top
///////////////////
// This is the top module of the custom DMA engine
// The purpose of this engine is to enable a way to fetch
// multiple samples from memory simultaneously using a simple trigger
// i.e. when the user presses a note from the keyboard, this
// engine must fetch the corresponding sample from memory
// and when a user presses a different note while the other one
// is playing, it must fetch both of them and combine them in real time
////////////////////
// Features
// - 64 concurrent voices
// -- DMA engine must support fetch and combination (sum) of 64 DMA regions
// - There shouldn't be any perceptible delay/latency (target < 2ms)
// - Simple trigger to play and release
///////////////////////////////////////////////////////////////

module sampler_dma_top #(
    parameter MAX_VOICES = 4,
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
    parameter integer C_AXI_LITE_SLAVE_ADDR_WIDTH = 4,

    // Parameters of Axi Slave Bus Interface S_AXI_INTR
    parameter integer C_S_AXI_INTR_DATA_WIDTH = 32,
    parameter integer C_S_AXI_INTR_ADDR_WIDTH = 5,
    parameter integer C_NUM_OF_INTR           = 1,
    parameter         C_INTR_SENSITIVITY      = 32'hFFFFFFFF,
    parameter         C_INTR_ACTIVE_STATE     = 32'hFFFFFFFF,
    parameter integer C_IRQ_SENSITIVITY       = 1,
    parameter integer C_IRQ_ACTIVE_STATE      = 1    
) (

    // Output FIFO Read
	output wire [ C_AXI_DMA_MASTER_ADDR_WIDTH : 0 ]     fifo_data_out,
	output wire                                         fifo_data_available,
	input  wire                                         fifo_data_read,
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
    input  wire                                             axi_stream_master_aclk    ,
    input  wire                                             axi_stream_master_aresetn ,
    output wire                                             axi_stream_master_tvalid  ,
    output wire [C_AXI_STREAM_MASTER_TDATA_WIDTH-1 : 0]     axi_stream_master_tdata   ,
    output wire [(C_AXI_STREAM_MASTER_TDATA_WIDTH/8)-1 : 0] axi_stream_master_tstrb   ,
    output wire                                             axi_stream_master_tlast   ,
    input  wire                                             axi_stream_master_tready  ,

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

//    ///////////////////////////////////////////////////////////
//    // Ports of Axi Slave Bus Interface S_AXI_INTR
//    ///////////////////////////////////////////////////////////
//    input  wire                                     s_axi_intr_aclk    ,
//    input  wire                                     s_axi_intr_aresetn ,
//    input  wire [C_S_AXI_INTR_ADDR_WIDTH-1 : 0]     s_axi_intr_awaddr  ,
//    input  wire [2 : 0]                             s_axi_intr_awprot  ,
//    input  wire                                     s_axi_intr_awvalid ,
//    output wire                                     s_axi_intr_awready ,
//    input  wire [C_S_AXI_INTR_DATA_WIDTH-1 : 0]     s_axi_intr_wdata   ,
//    input  wire [(C_S_AXI_INTR_DATA_WIDTH/8)-1 : 0] s_axi_intr_wstrb   ,
//    input  wire                                     s_axi_intr_wvalid  ,
//    output wire                                     s_axi_intr_wready  ,
//    output wire [1 : 0]                             s_axi_intr_bresp   ,
//    output wire                                     s_axi_intr_bvalid  ,
//    input  wire                                     s_axi_intr_bready  ,
//    input  wire [C_S_AXI_INTR_ADDR_WIDTH-1 : 0]     s_axi_intr_araddr  ,
//    input  wire [2 : 0]                             s_axi_intr_arprot  ,
//    input  wire                                     s_axi_intr_arvalid ,
//    output wire                                     s_axi_intr_arready ,
//    output wire [C_S_AXI_INTR_DATA_WIDTH-1 : 0]     s_axi_intr_rdata   ,
//    output wire [1 : 0]                             s_axi_intr_rresp   ,
//    output wire                                     s_axi_intr_rvalid  ,
//    input  wire                                     s_axi_intr_rready  ,
//    output wire                                     irq

);
//////////////////////////////
// Internal Signals
//////////////////////////////

// Register signals
wire [ 31 : 0 ] dma_control[ MAX_VOICES - 1 : 0 ];
wire [ 31 : 0 ] dma_base_addr[ MAX_VOICES - 1 : 0 ];
wire [ 31 : 0 ] dma_status[ MAX_VOICES - 1 : 0 ];
wire [ 31 : 0 ] dma_curr_addr[ MAX_VOICES - 1 : 0 ];

// Instantiation of Axi Bus Interface AXI_DMA_MASTER
    sampler_dma_v1_0_AXI_DMA_MASTER # (
        // Max voices
        .MAX_VOICES                ( MAX_VOICES                              ),
        // AXI Parameters
        .C_M_TARGET_SLAVE_BASE_ADDR( C_AXI_DMA_MASTER_TARGET_SLAVE_BASE_ADDR ),
        .C_M_AXI_BURST_LEN         ( C_AXI_DMA_MASTER_BURST_LEN              ),
        .C_M_AXI_ID_WIDTH          ( C_AXI_DMA_MASTER_ID_WIDTH               ),
        .C_M_AXI_ADDR_WIDTH        ( C_AXI_DMA_MASTER_ADDR_WIDTH             ),
        .C_M_AXI_DATA_WIDTH        ( C_AXI_DMA_MASTER_DATA_WIDTH             ),
        .C_M_AXI_AWUSER_WIDTH      ( C_AXI_DMA_MASTER_AWUSER_WIDTH           ),
        .C_M_AXI_ARUSER_WIDTH      ( C_AXI_DMA_MASTER_ARUSER_WIDTH           ),
        .C_M_AXI_WUSER_WIDTH       ( C_AXI_DMA_MASTER_WUSER_WIDTH            ),
        .C_M_AXI_RUSER_WIDTH       ( C_AXI_DMA_MASTER_RUSER_WIDTH            ),
        .C_M_AXI_BUSER_WIDTH       ( C_AXI_DMA_MASTER_BUSER_WIDTH            )
    ) sampler_dma_v1_0_AXI_DMA_MASTER_inst (
        // Register inputs
        .dma_control   ( dma_control   ),
        .dma_base_addr ( dma_base_addr ),
        .dma_status    ( dma_status    ),
        .dma_curr_addr ( dma_curr_addr ),
        // FIFO Output
        .fifo_data_out       ( fifo_data_out       ),
        .fifo_data_available ( fifo_data_available ),
        .fifo_data_read      ( fifo_data_read      ),        
        // AXI Signals
        .INIT_AXI_TXN  ( axi_dma_master_init_axi_txn ),
        .TXN_DONE      ( axi_dma_master_txn_done     ),
        .ERROR         ( axi_dma_master_error        ),
        .M_AXI_ACLK    ( axi_dma_master_aclk         ),
        .M_AXI_ARESETN ( axi_dma_master_aresetn      ),
        .M_AXI_AWID    ( axi_dma_master_awid         ),
        .M_AXI_AWADDR  ( axi_dma_master_awaddr       ),
        .M_AXI_AWLEN   ( axi_dma_master_awlen        ),
        .M_AXI_AWSIZE  ( axi_dma_master_awsize       ),
        .M_AXI_AWBURST ( axi_dma_master_awburst      ),
        .M_AXI_AWLOCK  ( axi_dma_master_awlock       ),
        .M_AXI_AWCACHE ( axi_dma_master_awcache      ),
        .M_AXI_AWPROT  ( axi_dma_master_awprot       ),
        .M_AXI_AWQOS   ( axi_dma_master_awqos        ),
        .M_AXI_AWUSER  ( axi_dma_master_awuser       ),
        .M_AXI_AWVALID ( axi_dma_master_awvalid      ),
        .M_AXI_AWREADY ( axi_dma_master_awready      ),
        .M_AXI_WDATA   ( axi_dma_master_wdata        ),
        .M_AXI_WSTRB   ( axi_dma_master_wstrb        ),
        .M_AXI_WLAST   ( axi_dma_master_wlast        ),
        .M_AXI_WUSER   ( axi_dma_master_wuser        ),
        .M_AXI_WVALID  ( axi_dma_master_wvalid       ),
        .M_AXI_WREADY  ( axi_dma_master_wready       ),
        .M_AXI_BID     ( axi_dma_master_bid          ),
        .M_AXI_BRESP   ( axi_dma_master_bresp        ),
        .M_AXI_BUSER   ( axi_dma_master_buser        ),
        .M_AXI_BVALID  ( axi_dma_master_bvalid       ),
        .M_AXI_BREADY  ( axi_dma_master_bready       ),
        .M_AXI_ARID    ( axi_dma_master_arid         ),
        .M_AXI_ARADDR  ( axi_dma_master_araddr       ),
        .M_AXI_ARLEN   ( axi_dma_master_arlen        ),
        .M_AXI_ARSIZE  ( axi_dma_master_arsize       ),
        .M_AXI_ARBURST ( axi_dma_master_arburst      ),
        .M_AXI_ARLOCK  ( axi_dma_master_arlock       ),
        .M_AXI_ARCACHE ( axi_dma_master_arcache      ),
        .M_AXI_ARPROT  ( axi_dma_master_arprot       ),
        .M_AXI_ARQOS   ( axi_dma_master_arqos        ),
        .M_AXI_ARUSER  ( axi_dma_master_aruser       ),
        .M_AXI_ARVALID ( axi_dma_master_arvalid      ),
        .M_AXI_ARREADY ( axi_dma_master_arready      ),
        .M_AXI_RID     ( axi_dma_master_rid          ),
        .M_AXI_RDATA   ( axi_dma_master_rdata        ),
        .M_AXI_RRESP   ( axi_dma_master_rresp        ),
        .M_AXI_RLAST   ( axi_dma_master_rlast        ),
        .M_AXI_RUSER   ( axi_dma_master_ruser        ),
        .M_AXI_RVALID  ( axi_dma_master_rvalid       ),
        .M_AXI_RREADY  ( axi_dma_master_rready       )
    );    

// Instantiation of Axi Bus Interface AXI_LITE_SLAVE
    sampler_dma_v1_0_AXI_LITE_SLAVE # ( 
        .MAX_VOICES         (  MAX_VOICES                 ),
        .C_S_AXI_DATA_WIDTH ( C_AXI_LITE_SLAVE_DATA_WIDTH ),
        .C_S_AXI_ADDR_WIDTH ( C_AXI_LITE_SLAVE_ADDR_WIDTH )
    ) sampler_dma_v1_0_AXI_LITE_SLAVE_inst (
        // Register outputs
        .dma_control   ( dma_control   ),
        .dma_base_addr ( dma_base_addr ),
        .dma_status    ( dma_status    ),
        .dma_curr_addr ( dma_curr_addr ),
        // AXI Signals
        .S_AXI_ACLK    ( axi_lite_slave_aclk    ),
        .S_AXI_ARESETN ( axi_lite_slave_aresetn ),
        .S_AXI_AWADDR  ( axi_lite_slave_awaddr  ),
        .S_AXI_AWPROT  ( axi_lite_slave_awprot  ),
        .S_AXI_AWVALID ( axi_lite_slave_awvalid ),
        .S_AXI_AWREADY ( axi_lite_slave_awready ),
        .S_AXI_WDATA   ( axi_lite_slave_wdata   ),
        .S_AXI_WSTRB   ( axi_lite_slave_wstrb   ),
        .S_AXI_WVALID  ( axi_lite_slave_wvalid  ),
        .S_AXI_WREADY  ( axi_lite_slave_wready  ),
        .S_AXI_BRESP   ( axi_lite_slave_bresp   ),
        .S_AXI_BVALID  ( axi_lite_slave_bvalid  ),
        .S_AXI_BREADY  ( axi_lite_slave_bready  ),
        .S_AXI_ARADDR  ( axi_lite_slave_araddr  ),
        .S_AXI_ARPROT  ( axi_lite_slave_arprot  ),
        .S_AXI_ARVALID ( axi_lite_slave_arvalid ),
        .S_AXI_ARREADY ( axi_lite_slave_arready ),
        .S_AXI_RDATA   ( axi_lite_slave_rdata   ),
        .S_AXI_RRESP   ( axi_lite_slave_rresp   ),
        .S_AXI_RVALID  ( axi_lite_slave_rvalid  ),
        .S_AXI_RREADY  ( axi_lite_slave_rready  )
    );

//// Instantiation of Axi Bus Interface S_AXI_INTR
//    sampler_dma_v1_0_S_AXI_INTR # ( 
//        .C_S_AXI_DATA_WIDTH(C_S_AXI_INTR_DATA_WIDTH),
//        .C_S_AXI_ADDR_WIDTH(C_S_AXI_INTR_ADDR_WIDTH),
//        .C_NUM_OF_INTR(C_NUM_OF_INTR),
//        .C_INTR_SENSITIVITY(C_INTR_SENSITIVITY),
//        .C_INTR_ACTIVE_STATE(C_INTR_ACTIVE_STATE),
//        .C_IRQ_SENSITIVITY(C_IRQ_SENSITIVITY),
//        .C_IRQ_ACTIVE_STATE(C_IRQ_ACTIVE_STATE)
//    ) sampler_dma_v1_0_S_AXI_INTR_inst (
//        .S_AXI_ACLK(s_axi_intr_aclk),
//        .S_AXI_ARESETN(s_axi_intr_aresetn),
//        .S_AXI_AWADDR(s_axi_intr_awaddr),
//        .S_AXI_AWPROT(s_axi_intr_awprot),
//        .S_AXI_AWVALID(s_axi_intr_awvalid),
//        .S_AXI_AWREADY(s_axi_intr_awready),
//        .S_AXI_WDATA(s_axi_intr_wdata),
//        .S_AXI_WSTRB(s_axi_intr_wstrb),
//        .S_AXI_WVALID(s_axi_intr_wvalid),
//        .S_AXI_WREADY(s_axi_intr_wready),
//        .S_AXI_BRESP(s_axi_intr_bresp),
//        .S_AXI_BVALID(s_axi_intr_bvalid),
//        .S_AXI_BREADY(s_axi_intr_bready),
//        .S_AXI_ARADDR(s_axi_intr_araddr),
//        .S_AXI_ARPROT(s_axi_intr_arprot),
//        .S_AXI_ARVALID(s_axi_intr_arvalid),
//        .S_AXI_ARREADY(s_axi_intr_arready),
//        .S_AXI_RDATA(s_axi_intr_rdata),
//        .S_AXI_RRESP(s_axi_intr_rresp),
//        .S_AXI_RVALID(s_axi_intr_rvalid),
//        .S_AXI_RREADY(s_axi_intr_rready),
//        .irq(irq)
//    );

endmodule