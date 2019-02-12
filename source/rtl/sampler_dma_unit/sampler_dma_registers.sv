module sampler_dma_registers #(
	parameter MAX_VOICES = 4
) (

    ////////////////////////////////
    //////// AXI CONTROLLER ////////
    // Clock and Reset
    input  wire        axi_clk,
    input  wire        axi_reset,

    // Data signals
    input  wire [31:0] data_in,
    output wire [31:0] data_out,
    input  wire [5:0]  reg_addr_wr,
	input  wire [5:0]  reg_addr_rd,
    input  wire        data_wren,
    input  wire [3:0]  byte_enable,

    // Signals from the design
	output wire [ 31 : 0 ] dma_control[ MAX_VOICES - 1 : 0 ],
	output wire [ 31 : 0 ] dma_base_addr[ MAX_VOICES - 1 : 0 ]
);

assign dma_base_addr = dma_base_addr_reg;
assign dma_control     = dma_control_reg;

reg [ 31 : 0 ]  dma_base_addr_reg[ MAX_VOICES - 1 : 0 ];
reg [ 31 : 0 ]  dma_control_reg[ MAX_VOICES - 1 : 0 ];

logic [31:0] reg_data_out;

genvar i;
generate;
	for ( i = 0; i < MAX_VOICES; i = i + 2 ) begin: indv_voice_register
		always_ff @(posedge axi_clk or negedge axi_reset) begin
			if ( ~axi_reset ) begin
				dma_base_addr_reg[i] <= 'h0;
				dma_control_reg[i]   <= 'h0;
			end
			else begin
				// 0, 2, 4, ...
				if ( reg_addr_wr == i && data_wren == 1'b1 ) begin
					dma_base_addr_reg[i] <= data_in;
				end
				// 1, 3, 5, 7, ...
				if ( ( reg_addr_wr == ( i + 1 ) ) && ( data_wren == 1'b1 ) ) begin
					dma_control_reg[i] <= data_in;
				end				
			end
		end
	end
endgenerate




////////////////////////////////////////
// Data Read Logic
////////////////////////////////////////
assign reg_data_out = ( reg_addr_rd < ( MAX_VOICES * 2 ) ) ? ( (reg_addr_rd[0] == 1'b0) ? dma_base_addr_reg[ reg_addr_rd ] : dma_control_reg[ reg_addr_rd ] ) : 32'hdeadbeef;
assign data_out = reg_data_out;


endmodule