//////////////////////////////////////
// Data Synchronizer Module         //
//////////////////////////////////////

module synchronizer #(
    parameter DATA_WIDTH  = 1
) (
    input  wire                      clk_in,
    input  wire [DATA_WIDTH - 1 : 0] data_in,

    input  wire                      clk_out,
    output wire [DATA_WIDTH - 1 : 0] data_out
);


reg [DATA_WIDTH - 1 : 0] data_sync_in [1:0];
reg [DATA_WIDTH - 1 : 0] data_sync_out[1:0];

assign data_out = data_sync_out[1];

// Input Sync
always_ff @(posedge clk_in)  data_sync_in[0]  <= data_in;
always_ff @(posedge clk_in)  data_sync_in[1]  <= data_sync_in[0];
// Output Sync
always_ff @(posedge clk_out) data_sync_out[0] <= data_sync_in[1];
always_ff @(posedge clk_out) data_sync_out[1] <= data_sync_out[0];

endmodule