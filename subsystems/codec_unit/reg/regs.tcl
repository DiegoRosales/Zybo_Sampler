####
## I2C Control Register
####

set codec_i2c_ctrl_reg {
  name "codec_i2c_ctrl"
  fields {
    i2c_data_rd {
      rtl_name    "i2c_data_rd"
      description "Read I2C Data"
      type        "REG_SW_WR1_HW_CLR"
      msb         0
      lsb         0
    }
    i2c_data_wr {
      rtl_name    "i2c_data_wr"
      description "Write I2C Data"
      type        "REG_SW_WR1_HW_CLR"
      msb         1
      lsb         1
    }
    controller_busy {
      rtl_name    "controller_busy"
      description "Controller Busy"
      type        "REG_HW_RW_SW_RO"
      msb         2
      lsb         2
    }
    codec_init_done {
      rtl_name    "codec_init_done"
      description "CODEC Initialization Done"
      type        "REG_HW_WR1_SW_CLR"
      msb         3
      lsb         3
    }
    data_in_valid {
      rtl_name    "data_in_valid"
      description "Data In Valid"
      type        "REG_HW_WR1_SW_CLR"
      msb         4
      lsb         4
    }
    missed_ack {
      rtl_name    "missed_ack"
      description "Missed ACK"
      type        "REG_HW_WR1_SW_CLR"
      msb         5
      lsb         5
    }
    controller_reset {
      rtl_name    "controller_reset"
      description "Controller Reset"
      type        "REG_SW_WR1_HW_CLR"
      msb         31
      lsb         31
    }
  }
}

####
## CODEC I2C Address
####
set codec_i2c_addr_reg {
  name "codec_i2c_addr"
  fields {
    codec_i2c_addr {
      rtl_name    "codec_i2c_addr"
      description "I2C Write Address"
      type        "REG_SW_RW_HW_RO"
      msb         31
      lsb         0
    }
  }
}

####
## CODEC I2C Write Data
####
set codec_i2c_wr_data_reg {
  name "codec_i2c_wr_data"
  fields {
    codec_i2c_wr_data {
      rtl_name    "codec_i2c_wr_data"
      description "I2C Write Data"
      type        "REG_SW_RW_HW_RO"
      msb         31
      lsb         0
    }
  }
}

####
## CODEC I2C Read Data
####
set codec_i2c_rd_data_reg {
  name "codec_i2c_rd_data"
  fields {
    codec_i2c_rd_data {
      rtl_name    "codec_i2c_rd_data"
      description "I2C Read Data"
      type        "REG_HW_RW_SW_RO"
      msb         31
      lsb         0
    }
  }
}

####
## misc_data_0
####
set misc_data_0_reg {
  name "misc_data_0"
  fields {
    misc_data_0 {
      rtl_name    "misc_data_0"
      description "misc_data_0"
      type        "REG_HW_RW_SW_RO"
      msb         31
      lsb         0
    }
  }
}

####
## misc_data_1
####
set misc_data_1_reg {
  name "misc_data_1"
  fields {
    misc_data_1 {
      rtl_name    "misc_data_1"
      description "misc_data_1"
      type        "REG_HW_RW_SW_RO"
      msb         31
      lsb         0
    }
  }
}

####
## misc_data_2
####
set misc_data_2_reg {
  name "misc_data_2"
  fields {
    misc_data_2 {
      rtl_name    "misc_data_2"
      description "misc_data_2"
      type        "REG_SW_RW_HW_RO"
      msb         31
      lsb         0
    }
  }
}

####
## Downstream AXIS Write Data Count
####
set downstream_axis_wr_data_count_reg {
  name "DOWNSTREAM_axis_wr_data_count"
  fields {
    DOWNSTREAM_axis_wr_data_count {
      rtl_name    "DOWNSTREAM_axis_wr_data_count_reg"
      description "DOWNSTREAM_axis_wr_data_count_reg"
      type        "REG_HW_RW_SW_RO"
      msb         31
      lsb         0
    }
  }
}
####
## Upstream AXIS Write Data Count
####
set upstream_axis_rd_data_count_reg {
  name "UPSTREAM_axis_rd_data_count_reg"
  fields {
    UPSTREAM_axis_rd_data_count_reg {
      rtl_name    "UPSTREAM_axis_rd_data_count_reg_reg"
      description "UPSTREAM_axis_rd_data_count_reg_reg"
      type        "REG_HW_RW_SW_RO"
      msb         31
      lsb         0
    }
  }
}
####
## Downstream AXIS Write Data Count
####
set downstream_axis_rd_data_count_reg {
  name "DOWNSTREAM_axis_rd_data_count_reg"
  fields {
    DOWNSTREAM_axis_rd_data_count_reg {
      rtl_name    "DOWNSTREAM_axis_rd_data_count_reg_reg"
      description "DOWNSTREAM_axis_rd_data_count_reg_reg"
      type        "REG_HW_RW_SW_RO"
      msb         31
      lsb         0
    }
  }
}
####
## Downstream AXIS Write Data Count
####
set upstream_axis_wr_data_count_reg {
  name "UPSTREAM_axis_wr_data_count_reg"
  fields {
    UPSTREAM_axis_wr_data_count_reg {
      rtl_name    "UPSTREAM_axis_wr_data_count_reg_reg"
      description "UPSTREAM_axis_wr_data_count_reg_reg"
      type        "REG_HW_RW_SW_RO"
      msb         31
      lsb         0
    }
  }
}
