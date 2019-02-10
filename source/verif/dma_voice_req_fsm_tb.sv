module dma_voice_req_fsm_tb (
);


parameter VOICE_INFO_DMA_BURST_SIZE      = 16; // Burst size
parameter VOICE_STREAM_DMA_BURST_SIZE    = 64;
parameter VOICE_INFO_DATA_STRUCTURE_SIZE = 4;  // Number of 
// Width of Address Bus
parameter integer C_M_AXI_ADDR_WIDTH	= 32;
// Width of Data Bus
parameter integer C_M_AXI_DATA_WIDTH	= 32;

// Clock and Reset
reg clk = 1'b0;
reg reset_n = 1'b0;
reg                                start_dma     = 'h0;
reg [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] dma_base_addr = 'h0;

// DMA request signals
wire [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] address;
wire                                dma_req;
wire [7 : 0 ]                       dma_req_len;

// Received DMA information
reg [ C_M_AXI_DATA_WIDTH - 1 : 0 ] dma_input_data = 'h0;
reg                                dma_input_data_valid = 'h0;
reg                                dma_done = 'h0;


reg [ 31 : 0 ] data_count;
reg dma_in_progress;
reg [7 : 0 ] dma_req_len_reg;

initial forever #(5ns) clk = ~clk;


initial begin
   #(1ns)   reset_n = 1'b1;
   #(200ns) reset_n = 1'b0;
   #(200ns) reset_n = 1'b1;
   #(200ns) start_dma = 1'b1;
end

always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        data_count <= 'h0;
        dma_req_len_reg <= 'h0;
        dma_in_progress <= 1'b0;
        dma_done <= 1'b0;
        dma_input_data_valid <= 1'b0;
        dma_input_data <= 'h0;
    end
    else begin
        data_count           <= data_count;
        dma_done             <= 1'b0;
        dma_input_data_valid <= 1'b0;
        dma_req_len_reg      <= dma_req_len_reg;
        dma_in_progress      <= dma_in_progress;
        dma_input_data       <= 'h0;

        if (dma_in_progress) begin
            if ( data_count[7:0] >=  dma_req_len_reg ) begin
                dma_in_progress <= 1'b0;
                dma_done        <= 1'b1;
            end
            else begin
                dma_input_data_valid <= 1'b1;
                data_count           <= data_count + 1'b1;
                dma_input_data       <= dma_input_data + 'h10;
            end
            
        end
        else if(dma_req) begin
            dma_in_progress <= 1'b1;
            dma_req_len_reg <= dma_req_len;
            data_count      <= 'h0;
        end

    end
end

dma_voice_req_fsm #(
    .VOICE_INFO_DMA_BURST_SIZE( VOICE_INFO_DMA_BURST_SIZE ),
    .VOICE_INFO_DATA_STRUCTURE_SIZE( VOICE_INFO_DATA_STRUCTURE_SIZE ),
    .C_M_AXI_ADDR_WIDTH( C_M_AXI_ADDR_WIDTH ),
    .C_M_AXI_DATA_WIDTH( C_M_AXI_DATA_WIDTH )
) dma_voice_req_fsm_inst (
    // Clock and Reset
    .clk,
    .reset_n,

    .start_dma,
    .dma_base_addr,

    // DMA request signals
    .address,
    .dma_req,
    .dma_req_len,

    // Received DMA information
    .dma_input_data,
    .dma_input_data_valid,
    .dma_done

);

endmodule