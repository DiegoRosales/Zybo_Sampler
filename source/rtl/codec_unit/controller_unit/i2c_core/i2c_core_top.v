`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07.01.2017 13:58:45
// Design Name:
// Module Name: i2c_core_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module i2c_core_top(
    input wire clk,
    input wire reset,
    input wire [6:0] addr,
    input wire [7:0] data_out_to_core,
    output wire [7:0] data_in_from_core,
    input wire data_wr,
    input wire data_rd,
    input wire rw_select,
    inout wire i2c_sda,
    input wire i2c_scl
    );

    i2c_data_rd_fifo data_read_fifo (
      .clk(clk),      // input wire clk
      .srst(reset),    // input wire srst
      .din(),      // input wire [7 : 0] din
      .wr_en(),  // input wire wr_en
      .rd_en(data_rd),  // input wire rd_en
      .dout(data_in_from_core),    // output wire [7 : 0] dout
      .full(),    // output wire full
      .empty()  // output wire empty
    );

    i2c_command_data_fifo command_data_fifo (
      .clk(clk),      // input wire clk
      .srst(reset),    // input wire srst
      .din({data_out_to_core, rw_select}),      // input wire [8 : 0] din
      .wr_en(data_wr),  // input wire wr_en
      .rd_en(),  // input wire rd_en
      .dout(),    // output wire [8 : 0] dout
      .full(),    // output wire full
      .empty()  // output wire empty
    );
endmodule
