/////////////////////////////////////////////////////
// This module acts as a bridge for high-level     //
// RD/WR Operations for internal CODEC registers.  //
// This module talks to the I2C Controller through //
// the Wishbone Interface.                         //
// This module also has signals that allow the     //
// user to read registers of the I2C Controller    //
// itself (for debug)                              //
/////////////////////////////////////////////////////
// Rev. 0.1 - Init                                 //
/////////////////////////////////////////////////////

module controller_unit_top (
  // 125MHz from the board
  input wire clk,
  input wire reset_n,

  // CODEC Register RD/WR Signals
  input  wire       codec_rd_en,
  input  wire       codec_wr_en,
  input  wire [7:0] codec_reg_addr,
  input  wire [8:0] codec_data_in,
  output wire [8:0] codec_data_out,
  output wire       codec_data_out_valid,
  output wire       controller_busy,
  output wire       missed_ack,

  // CODEC Status bit
  output wire init_done,
  output wire init_error,

  // I2C Interface
  input  wire        i2c_scl_i,
  output wire        i2c_scl_o,
  output wire        i2c_scl_t,
  input  wire        i2c_sda_i,
  output wire        i2c_sda_o,
  output wire        i2c_sda_t

);

// WB Interface
wire [2:0] wbs_adr_o; // ADR_I() address
wire [7:0] wbs_dat_o; // DAT_I() data out
wire [7:0] wbs_dat_i; // DAT_O() data in
wire       wbs_we_o;  // WE_I write enable output
wire       wbs_stb_o; // STB_I strobe output
wire       wbs_ack_i; // ACK_O acknowledge input
wire       wbs_cyc_o; // CYC_I cycle output

// Control signals between the WB interface and the I2C SM
wire       wb_read;
wire       wb_write;
wire [7:0] wb_data_out;
wire [3:0] wb_address;
wire [7:0] wb_data_in;
wire       wb_done;
wire       wb_data_in_valid;

// Initialization Controller
wire       INIT_codec_rd_en;
wire       INIT_codec_wr_en;
wire [8:0] INIT_codec_data_out;
wire [7:0] INIT_codec_reg_addr;
wire [8:0] INIT_codec_data_in;
wire       INIT_codec_data_in_valid;

// I2C State Machine
wire       CONTROLLER_codec_rd_en;
wire       CONTROLLER_codec_wr_en;
wire [8:0] CONTROLLER_codec_data_in;
wire [7:0] CONTROLLER_codec_reg_addr;
wire [8:0] CONTROLLER_codec_data_out;
wire       CONTROLLER_codec_data_out_valid;
wire       CONTROLLER_controller_busy;

// Don't allow external Rd/Wr until the initialization is done
// Inputs
assign CONTROLLER_codec_rd_en    = ((init_done | init_error) == 1'b0) ? INIT_codec_rd_en    : codec_rd_en;
assign CONTROLLER_codec_wr_en    = ((init_done | init_error) == 1'b0) ? INIT_codec_wr_en    : codec_wr_en;
assign CONTROLLER_codec_reg_addr = ((init_done | init_error) == 1'b0) ? INIT_codec_reg_addr : codec_reg_addr;
assign CONTROLLER_codec_data_in  = ((init_done | init_error) == 1'b0) ? INIT_codec_data_out : codec_data_in;
// Outputs
assign codec_data_out            = ((init_done | init_error) == 1'b0) ? 8'h00               : CONTROLLER_codec_data_out;
assign codec_data_out_valid      = CONTROLLER_codec_data_out_valid;//((init_done | init_error) == 1'b0) ? 1'b0                : CONTROLLER_codec_data_out_valid;
assign controller_busy           = ((init_done | init_error) == 1'b0) ? 1'b1                : CONTROLLER_controller_busy;
// Internal
assign INIT_codec_data_in        = ((init_done | init_error) == 1'b1) ? 8'h00               : CONTROLLER_codec_data_out;
assign INIT_codec_data_in_valid  = ((init_done | init_error) == 1'b1) ? 1'b0                : CONTROLLER_codec_data_out_valid;

wb_master_controller wb_master_controller_inst (
  .clk       ( clk       ),
  .reset_n   ( reset_n   ),

  // WB Interface
  .wbs_adr_o ( wbs_adr_o ), // ADR_I() address
  .wbs_dat_o ( wbs_dat_o ), // DAT_I() data out
  .wbs_dat_i ( wbs_dat_i ), // DAT_O() data in
  .wbs_we_o  ( wbs_we_o  ), // WE_I write enable output
  .wbs_stb_o ( wbs_stb_o ), // STB_I strobe output
  .wbs_ack_i ( wbs_ack_i ), // ACK_O acknowledge input
  .wbs_cyc_o ( wbs_cyc_o ), // CYC_I cycle output

  // Control Signals
  .read  ( wb_read  ),
  .write ( wb_write ),

  // Data Signals
  .data_in  ( wb_data_out ),
  .address  ( wb_address  ),
  .data_out ( wb_data_in  ),

  // Status Signals
  .data_out_valid ( wb_data_in_valid ),
  .done           ( wb_done          )
);

codec_init_unit codec_init_unit_inst (
  .clk        ( clk     ),
  .reset_n    ( reset_n ),

  // Signals to the i2c_seq_sm
  .codec_rd_en         ( INIT_codec_rd_en          ),
  .codec_wr_en         ( INIT_codec_wr_en          ),
  .codec_reg_addr      ( INIT_codec_reg_addr       ),
  .codec_data_out      ( INIT_codec_data_out       ),
  .codec_data_in       ( INIT_codec_data_in        ),
  .codec_data_in_valid ( INIT_codec_data_in_valid  ),

  // Signals to the top registers
  .init_done  ( init_done  ),
  .init_error ( init_error )

);
i2c_seq_sm i2c_seq_sm_inst (
  .clk                  ( clk                           ),
  .reset_n              ( reset_n                       ),

  // Control signals from the top
  .codec_rd_en          ( CONTROLLER_codec_rd_en          ),
  .codec_wr_en          ( CONTROLLER_codec_wr_en          ),
  .codec_reg_addr       ( CONTROLLER_codec_reg_addr       ),
  .codec_data_in        ( CONTROLLER_codec_data_in        ),
  .codec_data_out       ( CONTROLLER_codec_data_out       ),
  .codec_data_out_valid ( CONTROLLER_codec_data_out_valid ),
  .controller_busy      ( CONTROLLER_controller_busy      ),

  // Control signals to the WB Controller
  .wb_read              ( wb_read                       ),
  .wb_write             ( wb_write                      ),
  .wb_data_out          ( wb_data_out                   ),
  .wb_address           ( wb_address                    ),
  .wb_data_in           ( wb_data_in                    ),
  .wb_data_in_valid     ( wb_data_in_valid              ),
  .wb_done              ( wb_done                       ),

  // Misc
  .missed_ack           ( missed_ack                    )

);

i2c_master_wbs_8 #(
  .DEFAULT_PRESCALE(160)
) i2c_master_inst(
  .clk   ( clk     ),
  .rst_n ( reset_n ),

  // Wishbone
  .wbs_adr_i (wbs_adr_o),
  .wbs_dat_i (wbs_dat_o),
  .wbs_dat_o (wbs_dat_i),
  .wbs_we_i  (wbs_we_o ),
  .wbs_stb_i (wbs_stb_o),
  .wbs_ack_o (wbs_ack_i),
  .wbs_cyc_i (wbs_cyc_o),

  // I2C
  .i2c_scl_i ( i2c_scl_i ),
  .i2c_scl_o ( i2c_scl_o ),
  .i2c_scl_t ( i2c_scl_t ),
  .i2c_sda_i ( i2c_sda_i ),
  .i2c_sda_o ( i2c_sda_o ),
  .i2c_sda_t ( i2c_sda_t )
);


endmodule