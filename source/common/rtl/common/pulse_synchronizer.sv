//////////////////////////////////////
// Pulse Synchronizer Module         //
//////////////////////////////////////

module pulse_synchronizer  (
    input  wire clk_in,
    input  wire data_in,

    input  wire clk_out,
    output wire data_out
);


reg [3:0] data_sync_in;
reg [3:0] data_sync_out;

wire pulse_in_sync;
wire clear_pulse_in;

///////////////////////////////////////////////////////////
// Output assignment                                     //
// The output is 1 when the first stage of the out sync  //
// is 1 and it will clear 1 clock cycle after            //
assign data_out = data_sync_out[2] & (~data_sync_out[3]);
///////////////////////////////////////////////////////////

synchronizer #(
    .DATA_WIDTH(1)
    ) 
pulse_out_2_in_sync (
    .clk_in   (clk_out         ), 
    .clk_out  (clk_in          ), 
    .data_in  (data_sync_out[0]), 
    .data_out (pulse_in_sync   )
    );

// Clear the pulse when it has reached the fist stage of the output registers
assign clear_pulse_in = pulse_in_sync;

/////////////////////////////////
 
// Input Sync
// 3-Stage Sync
always_ff @(posedge clk_in)  data_sync_in[0]  <= data_in;
always_ff @(posedge clk_in)  data_sync_in[1]  <= data_sync_in[0];
always_ff @(posedge clk_in)  data_sync_in[2]  <= data_sync_in[1];
// The 4th stage checks with the 1st of the output
always_ff @(posedge clk_in)  begin
    if (data_sync_in[2] == 1'b1) begin
        data_sync_in[3]  <= 1'b1;
    end
    else if (data_sync_in[3] == 1'b1) begin
        data_sync_in[3]  <= 1'b1;
        if (clear_pulse_in == 1'b1) begin
            data_sync_in[3] <= 1'b0;
        end
    end
    else begin
        data_sync_in[3]  <= 1'b0;
    end
end

// Output Sync
always_ff @(posedge clk_out) data_sync_out[0] <= data_sync_in[3];
always_ff @(posedge clk_out) data_sync_out[1] <= data_sync_out[0];
always_ff @(posedge clk_out) data_sync_out[2] <= data_sync_out[1];
always_ff @(posedge clk_out) data_sync_out[3] <= data_sync_out[2];

endmodule