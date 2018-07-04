// Synchronizer for CLK domain corossing

module clk_sync
#(
	parameter BYPASS_SYNCHRONIZER = 1,
	parameter DATA_W = 1
)
(
	//CLK
	input wire clk1,
	input wire clk2,

	//Data
	input wire [DATA_W - 1 : 0] data_in,
	output wire [DATA_W - 1 : 0] data_out
);

reg [DATA_W - 1 : 0] ff1, ff2, ff3;

// Assignments
generate
	if (BYPASS_SYNCHRONIZER == 1) begin: bypass_sync
		assign data_out = data_in;
	end // end
	else begin: no_bypass_sync
		assign data_out = ff3;

		// 1 FF for the input clock
		always @(posedge clk1) begin
			ff1 <= data_in;
		end

		// 2 FFs for the output clock
		always @(posedge clk2) begin
			ff2 <= ff1;
			ff3 <= ff2;
		end
	end
endgenerate
endmodule