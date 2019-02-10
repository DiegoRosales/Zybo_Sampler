


module sampler_dma_v1_0_AXI_DMA_MASTER_tb ( );


parameter MAX_VOICES = 4;
parameter VOICE_INFO_DMA_BURST_SIZE      = 4; // Burst size of the information table of the voice
parameter VOICE_STREAM_DMA_BURST_SIZE    = 64; // Burst size of the information table of the voice
parameter VOICE_INFO_DATA_STRUCTURE_SIZE = 4;  // Number of registers of the voice data structure

// User parameters ends
// Do not modify the parameters beyond this line

// Base address of targeted slave
parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h40000000;
// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
parameter integer C_M_AXI_BURST_LEN	= 16;
// Thread ID Width
parameter integer C_M_AXI_ID_WIDTH	= 1;
// Width of Address Bus
parameter integer C_M_AXI_ADDR_WIDTH	= 32;
// Width of Data Bus
parameter integer C_M_AXI_DATA_WIDTH	= 32;
// Width of User Write Address Bus
parameter integer C_M_AXI_AWUSER_WIDTH	= 0;
// Width of User Read Address Bus
parameter integer C_M_AXI_ARUSER_WIDTH	= 0;
// Width of User Write Data Bus
parameter integer C_M_AXI_WUSER_WIDTH	= 0;
// Width of User Read Data Bus
parameter integer C_M_AXI_RUSER_WIDTH	= 0;
// Width of User Response Bus
parameter integer C_M_AXI_BUSER_WIDTH	= 0;

///////////////////////////////////////////////////////////////

reg  [ MAX_VOICES - 1 : 0 ] start_dma = 'h0;;
reg  [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] start_dma_base_addr[ MAX_VOICES - 1 : 0 ]; // This holds the note number information


// Users to add ports here
reg  [ MAX_VOICES - 1 : 0 ] start_dma_number[ 7 : 0 ]; // This holds the note number information
wire [ MAX_VOICES - 1 : 0 ] output_data[ 31 : 0 ]     ;
wire [ MAX_VOICES - 1 : 0 ] output_data_valid;

// User ports ends
// Do not modify the ports beyond this line

// Initiate AXI transactions
reg  INIT_AXI_TXN;
// Asserts when transaction is complete
wire  TXN_DONE;
// Asserts when ERROR is detected
reg  ERROR;
// Global Clock Signal.
reg  M_AXI_ACLK = 1'b0;
// Global Reset Singal. This Signal is Active Low
reg  M_AXI_ARESETN = 1'b0;

//////////////////////////////////////////////////////
// Write Signals
//////////////////////////////////////////////////////
// Master Interface Write Address ID
wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID;
// Master Interface Write Address
wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR;
// Burst length. The burst length gives the exact number of transfers in a burst
wire [7 : 0] M_AXI_AWLEN;
// Burst size. This signal indicates the size of each transfer in the burst
wire [2 : 0] M_AXI_AWSIZE;
// Burst type. The burst type and the size information; 
// determine how the address for each transfer within the burst is calculated.
wire [1 : 0] M_AXI_AWBURST;
// Lock type. Provides additional information about the
// atomic characteristics of the transfer.
wire  M_AXI_AWLOCK;
// Memory type. This signal indicates how transactions
// are required to progress through a system.
wire [3 : 0] M_AXI_AWCACHE;
// Protection type. This signal indicates the privilege
// and security level of the transaction; and whether
// the transaction is a data access or an instruction access.
wire [2 : 0] M_AXI_AWPROT;
// Quality of Service; QoS identifier sent for each write transaction.
wire [3 : 0] M_AXI_AWQOS;
// Optional User-defined signal in the write address channel.
wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER;
// Write address valid. This signal indicates that
// the channel is signaling valid write address and control information.
wire  M_AXI_AWVALID;
// Write address ready. This signal indicates that
// the slave is ready to accept an address and associated control signals
reg  M_AXI_AWREADY;
// Master Interface Write Data.
wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA;
// Write strobes. This signal indicates which byte
// lanes hold valid data. There is one write strobe
// bit for each eight bits of the write data bus.
wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB;
// Write last. This signal indicates the last transfer in a write burst.
wire  M_AXI_WLAST;
// Optional User-defined signal in the write data channel.
wire [C_M_AXI_WUSER_WIDTH-1 : 0] M_AXI_WUSER;
// Write valid. This signal indicates that valid write
// data and strobes are available
wire  M_AXI_WVALID;
// Write ready. This signal indicates that the slave
// can accept the write data.
reg  M_AXI_WREADY;

//////////////////////////////////////////////
// Master Interface Write Response.
///////////////////////////////////////////////
reg [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID;
// Write response. This signal indicates the status of the write transaction.
reg [1 : 0] M_AXI_BRESP;
// Optional User-defined signal in the write response channel
reg [C_M_AXI_BUSER_WIDTH-1 : 0] M_AXI_BUSER;
// Write response valid. This signal indicates that the
// channel is signaling a valid write response.
reg  M_AXI_BVALID;
// Response ready. This signal indicates that the master
// can accept a write response.
wire  M_AXI_BREADY;

//////////////////////////////////////////////
// Read Signals
///////////////////////////////////////////////

// Master Interface Read Address.
wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID;
// Read address. This signal indicates the initial
// address of a read burst transaction.
wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR;
// Burst length. The burst length gives the exact number of transfers in a burst
wire [7 : 0] M_AXI_ARLEN;
// Burst size. This signal indicates the size of each transfer in the burst
wire [2 : 0] M_AXI_ARSIZE;
// Burst type. The burst type and the size information; 
// determine how the address for each transfer within the burst is calculated.
wire [1 : 0] M_AXI_ARBURST;
// Lock type. Provides additional information about the
// atomic characteristics of the transfer.
wire  M_AXI_ARLOCK;
// Memory type. This signal indicates how transactions
// are required to progress through a system.
wire [3 : 0] M_AXI_ARCACHE;
// Protection type. This signal indicates the privilege
// and security level of the transaction, and whether
// the transaction is a data access or an instruction access.
wire [2 : 0] M_AXI_ARPROT;
// Quality of Service, QoS identifier sent for each read transaction
wire [3 : 0] M_AXI_ARQOS;
// Optional User-defined signal in the read address channel.
wire [C_M_AXI_ARUSER_WIDTH-1 : 0] M_AXI_ARUSER;
// Write address valid. This signal indicates that
// the channel is signaling valid read address and control information
wire  M_AXI_ARVALID;
// Read address ready. This signal indicates that
// the slave is ready to accept an address and associated control signals
reg  M_AXI_ARREADY_reg;
wire  M_AXI_ARREADY;

//////////////////////////////////////////////
// Read Response Signals
///////////////////////////////////////////////

// Read ID tag. This signal is the identification tag
// for the read data group of signals generated by the slave.
reg [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID;
// Master Read Data
reg [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA;
// Read response. This signal indicates the status of the read transfer
reg [1 : 0] M_AXI_RRESP;
// Read last. This signal indicates the last transfer in a read burst
reg  M_AXI_RLAST;
// Optional User-defined signal in the read address channel.
reg [C_M_AXI_RUSER_WIDTH-1 : 0] M_AXI_RUSER;
// Read valid. This signal indicates that the channel
// is signaling the required read data.
reg  M_AXI_RVALID;
// Read ready. This signal indicates that the master can
// accept the read data and response information.
wire  M_AXI_RREADY;


initial forever #(5ns) M_AXI_ACLK = ~M_AXI_ACLK;



initial begin
   #(1ns)   M_AXI_ARESETN = 1'b1;
   #(200ns) M_AXI_ARESETN = 1'b0;
   #(200ns) M_AXI_ARESETN = 1'b1;
end

initial begin
    #500
    start_dma[1]           = 1'b1;
    start_dma_base_addr[1] = 32'h0000_1000;
    start_dma[3]           = 1'b1;
    start_dma_base_addr[3] = 32'h0000_1000;    
end

always_ff @(posedge M_AXI_ACLK, negedge M_AXI_ARESETN) begin
    M_AXI_ARREADY_reg <= M_AXI_ARVALID;
end

assign M_AXI_ARREADY = M_AXI_ARREADY_reg & M_AXI_ARVALID;

// Instantiation of Axi Bus Interface AXI_DMA_MASTER
sampler_dma_v1_0_AXI_DMA_MASTER # ( 
    .MAX_VOICES(MAX_VOICES),
    .VOICE_INFO_DMA_BURST_SIZE(VOICE_INFO_DMA_BURST_SIZE),
    .VOICE_STREAM_DMA_BURST_SIZE(VOICE_STREAM_DMA_BURST_SIZE),
    .VOICE_INFO_DATA_STRUCTURE_SIZE(VOICE_INFO_DATA_STRUCTURE_SIZE),
    .C_M_TARGET_SLAVE_BASE_ADDR(C_M_TARGET_SLAVE_BASE_ADDR),
    .C_M_AXI_BURST_LEN(C_M_AXI_BURST_LEN),
    .C_M_AXI_ID_WIDTH(C_M_AXI_ID_WIDTH),
    .C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
    .C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
    .C_M_AXI_AWUSER_WIDTH(C_M_AXI_AWUSER_WIDTH),
    .C_M_AXI_ARUSER_WIDTH(C_M_AXI_ARUSER_WIDTH),
    .C_M_AXI_WUSER_WIDTH(C_M_AXI_WUSER_WIDTH),
    .C_M_AXI_RUSER_WIDTH(C_M_AXI_RUSER_WIDTH),
    .C_M_AXI_BUSER_WIDTH(C_M_AXI_BUSER_WIDTH)
) sampler_dma_v1_0_AXI_DMA_MASTER_inst (
    .start_dma           ( start_dma           ),
    .start_dma_base_addr ( start_dma_base_addr ),
    ////////////////////////////////////////
    .INIT_AXI_TXN( INIT_AXI_TXN ),
    .TXN_DONE( TXN_DONE ),
    .ERROR( ERROR ),
    .M_AXI_ACLK( M_AXI_ACLK ),
    .M_AXI_ARESETN( M_AXI_ARESETN ),
    .M_AXI_AWID( M_AXI_AWID ),
    .M_AXI_AWADDR( M_AXI_AWADDR ),
    .M_AXI_AWLEN( M_AXI_AWLEN ),
    .M_AXI_AWSIZE( M_AXI_AWSIZE ),
    .M_AXI_AWBURST( M_AXI_AWBURST ),
    .M_AXI_AWLOCK( M_AXI_AWLOCK ),
    .M_AXI_AWCACHE( M_AXI_AWCACHE ),
    .M_AXI_AWPROT( M_AXI_AWPROT ),
    .M_AXI_AWQOS( M_AXI_AWQOS ),
    .M_AXI_AWUSER( M_AXI_AWUSER ),
    .M_AXI_AWVALID( M_AXI_AWVALID ),
    .M_AXI_AWREADY( M_AXI_AWREADY ),
    .M_AXI_WDATA( M_AXI_WDATA ),
    .M_AXI_WSTRB( M_AXI_WSTRB ),
    .M_AXI_WLAST( M_AXI_WLAST ),
    .M_AXI_WUSER( M_AXI_WUSER ),
    .M_AXI_WVALID( M_AXI_WVALID ),
    .M_AXI_WREADY( M_AXI_WREADY ),
    .M_AXI_BID( M_AXI_BID ),
    .M_AXI_BRESP( M_AXI_BRESP ),
    .M_AXI_BUSER( M_AXI_BUSER ),
    .M_AXI_BVALID( M_AXI_BVALID ),
    .M_AXI_BREADY( M_AXI_BREADY ),
    .M_AXI_ARID( M_AXI_ARID ),
    .M_AXI_ARADDR( M_AXI_ARADDR ),
    .M_AXI_ARLEN( M_AXI_ARLEN ),
    .M_AXI_ARSIZE( M_AXI_ARSIZE ),
    .M_AXI_ARBURST( M_AXI_ARBURST ),
    .M_AXI_ARLOCK( M_AXI_ARLOCK ),
    .M_AXI_ARCACHE( M_AXI_ARCACHE ),
    .M_AXI_ARPROT( M_AXI_ARPROT ),
    .M_AXI_ARQOS( M_AXI_ARQOS ),
    .M_AXI_ARUSER( M_AXI_ARUSER ),
    .M_AXI_ARVALID( M_AXI_ARVALID ),
    .M_AXI_ARREADY( M_AXI_ARREADY ),
    .M_AXI_RID( M_AXI_RID ),
    .M_AXI_RDATA( M_AXI_RDATA ),
    .M_AXI_RRESP( M_AXI_RRESP ),
    .M_AXI_RLAST( M_AXI_RLAST ),
    .M_AXI_RUSER( M_AXI_RUSER ),
    .M_AXI_RVALID( M_AXI_RVALID ),
    .M_AXI_RREADY( M_AXI_RREADY )
);


endmodule