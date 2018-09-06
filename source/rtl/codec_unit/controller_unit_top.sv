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
  input wire clk,
  input wire reset,

  // CODEC Register RD/WR Signals
  input  wire       codec_rd_en,
  input  wire       codec_wr_en,
  input  wire [7:0] codec_reg_addr,
  input  wire [7:0] codec_data_wr,
  output wire [7:0] codec_data_rd,
  output wire       codec_data_rd_valid,
  output wire       controller_busy,

  // CODEC Status bit
  output wire codec_is_alive,

  // I2C Interface
  input  wire        i2c_scl_i,
  output wire        i2c_scl_o,
  output wire        i2c_scl_t,
  input  wire        i2c_sda_i,
  output wire        i2c_sda_o,
  output wire        i2c_sda_t

  );

// WB Interface
 wire [2:0] wbs_adr_o;   // ADR_I() address
 wire [7:0] wbs_dat_o;   // DAT_I() data out
 wire [7:0] wbs_dat_i;   // DAT_O() data in
 wire       wbs_we_o;    // WE_I write enable output
 wire       wbs_stb_o;   // STB_I strobe output
 wire       wbs_ack_i;   // ACK_O acknowledge input
 wire       wbs_cyc_o;   // CYC_I cycle output

// Control signals between the WB interface and the I2C SM
wire       wb_read;
wire       wb_write;
wire [7:0] wb_data_out;
wire [3:0] wb_address;
wire [7:0] wb_data_in;
wire       wb_done;
wire       wb_data_in_valid;

wb_master_controller wb_master_controller_inst (
  .clk,
  .reset,

  // WB Interface
  .wbs_adr_o,   // ADR_I() address
  .wbs_dat_o,   // DAT_I() data out
  .wbs_dat_i,   // DAT_O() data in
  .wbs_we_o,    // WE_I write enable output
  .wbs_stb_o,   // STB_I strobe output
  .wbs_ack_i,   // ACK_O acknowledge input
  .wbs_cyc_o,    // CYC_I cycle output

  // Control Signals
  .read(wb_read),
  .write(wb_write),

  // Data Signals
  .data_in(wb_data_out),
  .address(wb_addr),
  .data_out(wb_data_in),

  // Status Signals
  .data_out_valid(wb_data_in_valid),
  .done(wb_done)
);

i2c_seq_sm i2c_seq_sm_inst (
  // Control signals from the top
  .codec_rd_en,
  .codec_wr_en,
  .codec_reg_addr,
  .codec_data_wr,
  .codec_data_rd,
  .codec_data_rd_valid,
  .controller_busy,

  // Control signals to the WB Controller
  .wb_read,
  .wb_write,
  .wb_data_out,
  .wb_address,
  .wb_data_in,
  .wb_data_in_valid,
  .wb_done

);

i2c_master_wbs_8 i2c_master_inst(
  .clk(clk_125mhz),
  .rst(reset),
  // Wishbone
  .wbs_adr_i(wbs_adr_o),
  .wbs_dat_i(wbs_dat_o),
  .wbs_dat_o(wbs_dat_i),
  .wbs_we_i(wbs_we_o),
  .wbs_stb_i(wbs_stb_o),
  .wbs_ack_o(wbs_ack_i),
  .wbs_cyc_i(wbs_cyc_o),

  .i2c_scl_i(i2c_scl_i),
  .i2c_scl_o(i2c_scl_o),
  .i2c_scl_t(i2c_scl_t),

  .i2c_sda_i(i2c_sda_i),
  .i2c_sda_o(i2c_sda_o),
  .i2c_sda_t(i2c_sda_t)
  );


endmodule