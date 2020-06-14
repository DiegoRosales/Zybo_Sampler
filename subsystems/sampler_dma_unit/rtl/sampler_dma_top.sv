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
    parameter integer C_AXI_STREAM_TDATA_WIDTH = 32,
    parameter integer C_AXI_STREAM_TUSER_WIDTH = 32,

    // Parameters of Axi Slave Bus Interface AXI_LITE_SLAVE
    parameter integer C_AXI_LITE_SLAVE_DATA_WIDTH = 32,
    parameter integer C_AXI_LITE_SLAVE_ADDR_WIDTH = 16,

    // Debug
    parameter FETCHER_ENABLE_DEBUG       = 1,
    parameter DMA_REQUESTER_ENABLE_DEBUG = 1,
    parameter DMA_RECEIVER_ENABLE_DEBUG  = 1
) (

    // AXI Clock
    input wire axi_clk,

    ///////////////////////////////////////////////////////////
    // Ports of Axi Master Bus Interface AXI_DMA_MASTER
    ///////////////////////////////////////////////////////////
    input  wire                                       axi_dma_master_aresetn,
    input  wire                                       axi_dma_master_init_axi_txn,
    output wire                                       axi_dma_master_txn_done,
    output wire                                       axi_dma_master_error,
    output wire [C_AXI_DMA_MASTER_ID_WIDTH-1 : 0]     axi_dma_master_awid,
    output wire [C_AXI_DMA_MASTER_ADDR_WIDTH-1 : 0]   axi_dma_master_awaddr,
    output wire [7 : 0]                               axi_dma_master_awlen,
    output wire [2 : 0]                               axi_dma_master_awsize,
    output wire [1 : 0]                               axi_dma_master_awburst,
    output wire                                       axi_dma_master_awlock,
    output wire [3 : 0]                               axi_dma_master_awcache,
    output wire [2 : 0]                               axi_dma_master_awprot,
    output wire [3 : 0]                               axi_dma_master_awqos,
    output wire [C_AXI_DMA_MASTER_AWUSER_WIDTH-1 : 0] axi_dma_master_awuser,
    output wire                                       axi_dma_master_awvalid,
    input  wire                                       axi_dma_master_awready,
    output wire [C_AXI_DMA_MASTER_DATA_WIDTH-1 : 0]   axi_dma_master_wdata,
    output wire [C_AXI_DMA_MASTER_DATA_WIDTH/8-1 : 0] axi_dma_master_wstrb,
    output wire                                       axi_dma_master_wlast,
    output wire [C_AXI_DMA_MASTER_WUSER_WIDTH-1 : 0]  axi_dma_master_wuser,
    output wire                                       axi_dma_master_wvalid,
    input  wire                                       axi_dma_master_wready,
    input  wire [C_AXI_DMA_MASTER_ID_WIDTH-1 : 0]     axi_dma_master_bid,
    input  wire [1 : 0]                               axi_dma_master_bresp,
    input  wire [C_AXI_DMA_MASTER_BUSER_WIDTH-1 : 0]  axi_dma_master_buser,
    input  wire                                       axi_dma_master_bvalid,
    output wire                                       axi_dma_master_bready,
    output wire [C_AXI_DMA_MASTER_ID_WIDTH-1 : 0]     axi_dma_master_arid,
    output wire [C_AXI_DMA_MASTER_ADDR_WIDTH-1 : 0]   axi_dma_master_araddr,
    output wire [7 : 0]                               axi_dma_master_arlen,
    output wire [2 : 0]                               axi_dma_master_arsize,
    output wire [1 : 0]                               axi_dma_master_arburst,
    output wire                                       axi_dma_master_arlock,
    output wire [3 : 0]                               axi_dma_master_arcache,
    output wire [2 : 0]                               axi_dma_master_arprot,
    output wire [3 : 0]                               axi_dma_master_arqos,
    output wire [C_AXI_DMA_MASTER_ARUSER_WIDTH-1 : 0] axi_dma_master_aruser,
    output wire                                       axi_dma_master_arvalid,
    input  wire                                       axi_dma_master_arready,
    input  wire [C_AXI_DMA_MASTER_ID_WIDTH-1 : 0]     axi_dma_master_rid,
    input  wire [C_AXI_DMA_MASTER_DATA_WIDTH-1 : 0]   axi_dma_master_rdata,
    input  wire [1 : 0]                               axi_dma_master_rresp,
    input  wire                                       axi_dma_master_rlast,
    input  wire [C_AXI_DMA_MASTER_RUSER_WIDTH-1 : 0]  axi_dma_master_ruser,
    input  wire                                       axi_dma_master_rvalid,
    output wire                                       axi_dma_master_rready,
    ///////////////////////////////////////////////////////////
    // Ports of Axi Master Bus Interface AXI_STREAM_MASTER
    ///////////////////////////////////////////////////////////
    output wire [C_AXI_STREAM_TDATA_WIDTH-1 : 0]        axi_stream_master_tdata,
    input  wire                                         axi_stream_master_tready,
    output wire                                         axi_stream_master_tvalid,
    output wire                                         axi_stream_master_tlast,
    output wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0]        axi_stream_master_tuser,

    ///////////////////////////////////////////////////////////
    // Ports of Axi Slave Bus Interface AXI_LITE_SLAVE
    ///////////////////////////////////////////////////////////
    input  wire                                         axi_lite_slave_aresetn,
    input  wire [C_AXI_LITE_SLAVE_ADDR_WIDTH-1 : 0]     axi_lite_slave_awaddr,
    input  wire [2 : 0]                                 axi_lite_slave_awprot,
    input  wire                                         axi_lite_slave_awvalid,
    output wire                                         axi_lite_slave_awready,
    input  wire [C_AXI_LITE_SLAVE_DATA_WIDTH-1 : 0]     axi_lite_slave_wdata,
    input  wire [(C_AXI_LITE_SLAVE_DATA_WIDTH/8)-1 : 0] axi_lite_slave_wstrb,
    input  wire                                         axi_lite_slave_wvalid,
    output wire                                         axi_lite_slave_wready,
    output wire [1 : 0]                                 axi_lite_slave_bresp,
    output wire                                         axi_lite_slave_bvalid,
    input  wire                                         axi_lite_slave_bready,
    input  wire [C_AXI_LITE_SLAVE_ADDR_WIDTH-1 : 0]     axi_lite_slave_araddr,
    input  wire [2 : 0]                                 axi_lite_slave_arprot,
    input  wire                                         axi_lite_slave_arvalid,
    output wire                                         axi_lite_slave_arready,
    output wire [C_AXI_LITE_SLAVE_DATA_WIDTH-1 : 0]     axi_lite_slave_rdata,
    output wire [1 : 0]                                 axi_lite_slave_rresp,
    output wire                                         axi_lite_slave_rvalid,
    input  wire                                         axi_lite_slave_rready  
);
//////////////////////////////
// Internal Signals
//////////////////////////////

// Number of bits needed to address all internal registers
localparam integer OPT_MEM_ADDR_BITS = C_AXI_LITE_SLAVE_ADDR_WIDTH - 3;

// Output from the registers
wire [ C_AXI_LITE_SLAVE_DATA_WIDTH - 1 : 0 ] reg_data_out;
wire [ OPT_MEM_ADDR_BITS  - 1 : 0 ]          reg_wr_addr;
wire [ OPT_MEM_ADDR_BITS  - 1 : 0 ]          reg_rd_addr;
wire                                         reg_wr_en;

// Interface between the AXI bridge and the receiver
wire [C_AXI_STREAM_TDATA_WIDTH-1 : 0]  dma_receiver_axi_stream_slave_tdata;
wire                                   dma_receiver_axi_stream_slave_tready;
wire                                   dma_receiver_axi_stream_slave_tvalid;
wire                                   dma_receiver_axi_stream_slave_tlast;
wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0]  dma_receiver_axi_stream_slave_tuser;

// Control Registers
(* keep = "true" *) wire start;
(* keep = "true" *) wire stop;

// Interface between the fetcher and the BRAM registers
(* keep = "true" *) wire             bram_B_we;
(* keep = "true" *) wire [ 5 : 0 ]   bram_B_addr;
(* keep = "true" *) wire [ 127 : 0 ] bram_B_din;
(* keep = "true" *) wire [ 127 : 0 ] bram_B_dout;

// Interface between the fetcher and the DMA requester
(* keep = "true" *) wire [ 31 : 0 ] sample_addr;
(* keep = "true" *) wire [ 5 : 0 ]  sample_id;
(* keep = "true" *) wire            sample_valid;
(* keep = "true" *) wire            sample_overflow;
(* keep = "true" *) wire            sample_last;
(* keep = "true" *) wire            load_next_sample;

// Interface between the DMA requester and the receiver
(* keep = "true" *) wire           all_samples_received;
(* keep = "true" *) wire           last_request_sent;
(* keep = "true" *) wire [ 5 : 0 ] last_request_id;
(* keep = "true" *) wire           all_samples_invalid;

// Interface between the AXI bridge and the receiver //
(* keep = "true" *) wire [ 31 : 0 ] axi_sample_data;
(* keep = "true" *) wire [ 5 : 0 ]  axi_sample_id;
(* keep = "true" *) wire            axi_sample_valid;
(* keep = "true" *) wire            axi_sample_data_last;
(* keep = "true" *) wire            axi_sample_receiver_ready;

// Interface between the AXI bridge and the requester //
(* keep = "true" *) wire [ 31 : 0 ] dma_sample_req_addr;
(* keep = "true" *) wire [ 5 : 0 ]  dma_sample_req_id;
(* keep = "true" *) wire [ 7 : 0 ]  dma_sample_req_len;
(* keep = "true" *) wire            dma_sample_req_valid;
(* keep = "true" *) wire            dma_sample_req_done;

    axi_dma_bridge # (
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
        .C_M_AXI_BUSER_WIDTH       ( C_AXI_DMA_MASTER_BUSER_WIDTH            ),
        // AXI Stream Parameters
        .C_AXI_STREAM_TDATA_WIDTH  ( C_AXI_STREAM_TDATA_WIDTH                ),
        .C_AXI_STREAM_TUSER_WIDTH  ( C_AXI_STREAM_TUSER_WIDTH                )
    ) axi_dma_bridge (
		////////////////////////////////////////////////////
		// Interface to the user logic
		////////////////////////////////////////////////////

		// Interface between the AXI bridge and the receiver //
        // Output AXI Stream interface
        .axi_stream_master_tdata  ( dma_receiver_axi_stream_slave_tdata  ),
        .axi_stream_master_tready ( dma_receiver_axi_stream_slave_tready ),
        .axi_stream_master_tvalid ( dma_receiver_axi_stream_slave_tvalid ),
        .axi_stream_master_tlast  ( dma_receiver_axi_stream_slave_tlast  ),
        .axi_stream_master_tuser  ( dma_receiver_axi_stream_slave_tuser  ),


		// Interface between the AXI bridge and the requester //
		.dma_sample_req_addr  ( dma_sample_req_addr  ),
		.dma_sample_req_id    ( dma_sample_req_id    ),
		.dma_sample_req_len   ( dma_sample_req_len   ),
		.dma_sample_req_valid ( dma_sample_req_valid ),
		.dma_sample_req_done  ( dma_sample_req_done  ),

		////////////////////////////////////////////////////
		// Interface to the AXI fabric
		////////////////////////////////////////////////////
        // AXI Signals
        .INIT_AXI_TXN  ( axi_dma_master_init_axi_txn ),
        .TXN_DONE      ( axi_dma_master_txn_done     ),
        .ERROR         ( axi_dma_master_error        ),
        .M_AXI_ACLK    ( axi_clk                     ),
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



	axi_slave_controller # ( 
		.OPT_MEM_ADDR_BITS  ( OPT_MEM_ADDR_BITS  ),
		.C_S_AXI_DATA_WIDTH ( C_AXI_LITE_SLAVE_DATA_WIDTH ),
		.C_S_AXI_ADDR_WIDTH ( C_AXI_LITE_SLAVE_ADDR_WIDTH )
	) axi_slave_controller_inst (
		.S_AXI_ACLK    ( axi_clk                ),
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
		.S_AXI_RREADY  ( axi_lite_slave_rready  ),
		
		// Interface to the register controller
		.reg_data_out ( reg_data_out ),
		.reg_wr_addr  ( reg_wr_addr  ),
		.reg_rd_addr  ( reg_rd_addr  ),
		.reg_wr_en    ( reg_wr_en    )

	);

    sampler_dma_registers #(
        .MAX_VOICES        ( MAX_VOICES        ),
        .OPT_MEM_ADDR_BITS ( OPT_MEM_ADDR_BITS )
    )
    sampler_dma_registers (
        // Clock and Reset
        .clk     ( axi_clk                ),
        .reset_n ( axi_lite_slave_aresetn ),

        // Rd/Wr Signals
        .data_in     ( axi_lite_slave_wdata ),
		.data_out    ( reg_data_out         ),
		.reg_addr_wr ( reg_wr_addr          ),
		.reg_addr_rd ( reg_rd_addr          ),
		.data_wren   ( reg_wr_en            ),

        .bram_B_we   ( bram_B_we   ),
        .bram_B_addr ( bram_B_addr ),
        .bram_B_din  ( bram_B_din  ),
        .bram_B_dout ( bram_B_dout ),

        // User Signals
        .start ( start ),  // Start the fetch mechanism
        .stop  ( stop  )   // Stop the fetch mechanism
    );

    sample_info_fetcher #(
        .NUMBER_OF_SAMPLE_REG_PER_READ ( 4   ),   // This controls the number of registers to be fetched on a single read
        .BRAM_DATA_WIDTH               ( 128 ), // This controls the data width of the BRAM data
        .BRAM_ADDR_WIDTH               ( 6   ),
        // Debug
        .ENABLE_DEBUG ( FETCHER_ENABLE_DEBUG )

    ) sample_info_fetcher (
        .clk     ( axi_clk                ),
        .reset_n ( axi_lite_slave_aresetn ),

        // Control interface //
        .start ( start ), // Start the fetch mechanism
        .stop  ( stop  ),  // Stop the fetch mechanism

        // BRAM Interface //
       .bram_data_wr   ( bram_B_we   ),
       .bram_addr      ( bram_B_addr ),
       .bram_data_in   ( bram_B_dout ),
       .bram_data_out  ( bram_B_din  ),

        // Voice FSM Interface //
        .sample_addr         ( sample_addr         ),
        .sample_id           ( sample_id           ),
        .sample_valid        ( sample_valid        ),
        .sample_overflow     ( sample_overflow     ),
        .sample_last         ( sample_last         ),
        .load_next_sample    ( load_next_sample    ),
        .all_samples_invalid ( all_samples_invalid )
    );

    sample_dma_requester #(
        .ENABLE_DEBUG ( DMA_REQUESTER_ENABLE_DEBUG )
    )
    sample_dma_requester (
        .clk     ( axi_clk                ),
        .reset_n ( axi_lite_slave_aresetn ),

        // Control interface //
        .start ( start ),  // Start the fetch mechanism
        .stop  ( stop  ),  // Stop the fetch mechanism

        // AXI Bridge interface //
		.dma_sample_req_addr  ( dma_sample_req_addr  ),
		.dma_sample_req_id    ( dma_sample_req_id    ),
		.dma_sample_req_len   ( dma_sample_req_len   ),
		.dma_sample_req_valid ( dma_sample_req_valid ),
		.dma_sample_req_done  ( dma_sample_req_done  ),

        // Data receiver interface //
        .all_samples_received ( all_samples_received ),
        .last_request_sent    ( last_request_sent    ),
        .last_request_id      ( last_request_id      ),

        // Information fetcher interface //
        .sample_addr         ( sample_addr         ),
        .sample_id           ( sample_id           ),
        .sample_valid        ( sample_valid        ),
        .sample_overflow     ( sample_overflow     ),
        .sample_last         ( sample_last         ),
        .load_next_sample    ( load_next_sample    ),
        .all_samples_invalid ( all_samples_invalid )
    );

    sample_dma_receiver # (
        .ENABLE_DEBUG             ( DMA_RECEIVER_ENABLE_DEBUG ),
        .C_AXI_STREAM_TDATA_WIDTH ( C_AXI_STREAM_TDATA_WIDTH  ),
        .C_AXI_STREAM_TUSER_WIDTH ( C_AXI_STREAM_TUSER_WIDTH  )
    )
    sample_dma_receiver (
        .clk     ( axi_clk                ),
        .reset_n ( axi_lite_slave_aresetn ),
        
        // Stop bit
        .stop    ( stop ),

        // DMA Requester interface //
        .all_samples_received ( all_samples_received ),
        .last_request_sent    ( last_request_sent    ),
        .last_request_id      ( last_request_id      ),
        .all_samples_invalid  ( all_samples_invalid  ),

        // Input AXI Stream interface from the AXI Bridge
        .axi_stream_slave_tdata  ( dma_receiver_axi_stream_slave_tdata  ),
        .axi_stream_slave_tvalid ( dma_receiver_axi_stream_slave_tvalid ),
        .axi_stream_slave_tlast  ( dma_receiver_axi_stream_slave_tlast  ),
        .axi_stream_slave_tuser  ( dma_receiver_axi_stream_slave_tuser  ),
        .axi_stream_slave_tready ( dma_receiver_axi_stream_slave_tready ),

        // Output AXI Stream interface
        .axi_stream_master_tdata  ( axi_stream_master_tdata  ),
        .axi_stream_master_tvalid ( axi_stream_master_tvalid ),
        .axi_stream_master_tlast  ( axi_stream_master_tlast  ),
        .axi_stream_master_tuser  ( axi_stream_master_tuser  ),
        .axi_stream_master_tready ( axi_stream_master_tready )
    );
endmodule