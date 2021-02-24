/////////////////////////////////////
// AXI-4 Interface
/////////////////////////////////////

interface axi4_lite_if #(int ADDR_WIDTH=32, int DATA_WIDTH=32) (input clock, input reset_n);
   // Write
   bit [ADDR_WIDTH-1 : 0]     awaddr;
   bit [2 : 0]                awprot;
   bit                        awvalid;
   bit                        awready;
   bit [DATA_WIDTH-1 : 0]     wdata;
   bit [(DATA_WIDTH/8)-1 : 0] wstrb;
   bit                        wvalid;
   bit                        wready;
   // Response
   bit [1 : 0]                bresp;
   bit                        bvalid;
   bit                        bready;

   // Read
   bit [ADDR_WIDTH-1 : 0]     araddr;
   bit [2 : 0]                arprot;
   bit                        arvalid;
   bit                        arready;
   bit [DATA_WIDTH-1 : 0]     rdata;
   // Response
   bit [1 : 0]                rresp;
   bit                        rvalid;
   bit                        rready;

endinterface