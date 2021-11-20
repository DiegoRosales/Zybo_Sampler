/////////////////////////////////////////////////////
// This module controls the initialization of the  //
// CODEC by performing I2C Rd/Wr operations        //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////
// Rev. 0.1 - Init                                 //
/////////////////////////////////////////////////////

module codec_init_unit (
  input wire  clk,
  input wire  reset_n,

  output wire       codec_rd_en,
  output wire       codec_wr_en,
  output wire [7:0] codec_reg_addr,
  output wire [8:0] codec_data_out,
  input  wire [8:0] codec_data_in,
  input  wire       codec_data_in_valid,
  
  output wire       init_done,
  output wire       init_error

  );

reg       codec_rd_en_reg;
reg       codec_wr_en_reg;
reg [7:0] codec_reg_addr_reg;
reg [8:0] codec_data_out_reg;

reg       init_done_reg;
reg       init_error_reg;

assign codec_rd_en    = codec_rd_en_reg;
assign codec_wr_en    = codec_wr_en_reg;
assign codec_reg_addr = codec_reg_addr_reg;
assign codec_data_out = codec_data_out_reg;

assign init_done      = init_done_reg;
assign init_error     = init_error_reg;

// Registers
localparam ADC_LEFT_INPUT_VOLUME_REG   = 8'h00;
localparam ADC_RIGHT_INPUT_VOLUME_REG  = 8'h01;
localparam DAC_LEFT_OUTPUT_VOLUME_REG  = 8'h02;
localparam DAC_RIGHT_OUTPUT_VOLUME_REG = 8'h03;
localparam ANALOG_AUDIO_PATH           = 8'h04;
localparam DIGITAL_AUDIO_PATH          = 8'h05;

// States of the SM
localparam START          = 3'h0;
localparam REG_RD         = 3'h1;
localparam WAIT_ON_REG_RD = 3'h2;
localparam REG_WR         = 3'h3;
localparam WAIT_ON_REG_WR = 3'h4;
localparam INIT_DONE      = 3'h5;
localparam INIT_ERROR     = 3'h6;

// 8'h97
localparam DEFAULT_VALUE  = 8'b010010111;
reg [2:0] init_sm_cs;
reg [2:0] init_sm_ns;

always @(posedge clk or negedge reset_n) begin
  if (!reset_n) begin
    init_sm_ns <= START;
  end // if (!reset_n)
  else begin
    init_sm_ns <= init_sm_ns;
    case(init_sm_cs)
      START: init_sm_ns <= REG_RD;
      REG_RD: init_sm_ns <= WAIT_ON_REG_RD;
      WAIT_ON_REG_RD: begin
        if (codec_data_in_valid) begin
          init_sm_ns <= (codec_data_in == DEFAULT_VALUE) ? INIT_DONE : INIT_ERROR;
        end // if (codec_data_in_valid)
      end // WAIT_ON_REG_RD: 
      INIT_DONE: init_sm_ns <= INIT_DONE;
      INIT_ERROR: init_sm_ns <= INIT_ERROR;
      default: init_sm_ns <= START;
    endcase // init_sm_cs

  end // else
end // always @(posedge clk or negedge reset_n)

always @(posedge clk or negedge reset_n) begin
  if (!reset_n) begin
    init_sm_cs         <= START;
    codec_rd_en_reg    <= 1'b0;
    codec_wr_en_reg    <= 1'b0;
    codec_reg_addr_reg <= 8'h0;
    codec_data_out_reg <= 'h0;
    init_done_reg      <= 1'b0;
    init_error_reg     <= 1'b0;
  end // if (!reset_n)
  else begin
    init_sm_cs         <= init_sm_ns;
    codec_rd_en_reg    <= codec_rd_en_reg;
    codec_wr_en_reg    <= codec_wr_en_reg;
    codec_reg_addr_reg <= codec_reg_addr_reg;
    codec_data_out_reg <= codec_data_out_reg;
    init_done_reg      <= init_done_reg;
    init_error_reg     <= init_error_reg;

    case(init_sm_cs)
      START: begin
        codec_rd_en_reg    <= 1'b0;
        codec_reg_addr_reg <= ADC_LEFT_INPUT_VOLUME_REG;
      end
      REG_RD:         codec_rd_en_reg    <= 1'b1;
      WAIT_ON_REG_RD: codec_rd_en_reg    <= 1'b0;
      INIT_DONE: begin
        codec_rd_en_reg    <= 1'b0;
        codec_wr_en_reg    <= 1'b0;
        codec_reg_addr_reg <= 8'h00;
        codec_data_out_reg <= 'h0;  
        init_done_reg      <= 1'b1;
      end    
      INIT_ERROR: begin
        codec_rd_en_reg    <= 1'b0;
        codec_wr_en_reg    <= 1'b0;
        codec_reg_addr_reg <= 8'h00;
        codec_data_out_reg <= 'h0;  
        init_error_reg      <= 1'b1;
      end         
      default: begin
        codec_rd_en_reg    <= 1'b0;
        codec_wr_en_reg    <= 1'b0;
        codec_reg_addr_reg <= 8'h00;
        codec_data_out_reg <= 'h0;
        init_done_reg      <= 1'b0;
      end
    endcase // init_sm_cs
  end // else
end // always @(posedge clk or negedge reset_n)

endmodule