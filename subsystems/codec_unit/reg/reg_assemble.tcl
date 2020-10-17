set script_dir [file normalize [file dirname [info script]]]
source "$script_dir/regs.tcl"

set CLK                  "clk"
set RST                  "reset_n"
set WE_SIGNAL            "write_enable"
set WRITE_DATA_SIGNAL    "write_data"
set READ_DATA_SIGNAL     "read_data"
set ADDRESS_READ_SIGNAL  "read_addr"
set ADDRESS_WRITE_SIGNAL "write_addr"

## Assemble all the registers
set codec_register_block [list \
  $codec_i2c_ctrl_reg                0 \
  $codec_i2c_addr_reg                1 \
  $codec_i2c_wr_data_reg             2 \
  $codec_i2c_rd_data_reg             3 \
  $misc_data_0_reg                   4 \
  $misc_data_1_reg                   5 \
  $misc_data_2_reg                   6 \
  $downstream_axis_wr_data_count_reg 7 \
  $upstream_axis_rd_data_count_reg   8 \
  $downstream_axis_rd_data_count_reg 9 \
  $upstream_axis_wr_data_count_reg   10 \
]

set reg_blocks [list \
  "codec_registers" $codec_register_block
]
