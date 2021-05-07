// Testbench package

package codec_unit_top_pkg;
  // Mandatory UVM
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import clock_and_reset_bfm_pkg::*;
  import i2s_bfm_pkg::*;
  import axi4_lite_bfm_pkg::*;
  import codec_unit_top_reg_model_pkg::*;

  `include "codec_unit_top_cfg.svh"
  `include "codec_unit_top_virtual_sequencer.svh"
  `include "codec_unit_top_base_test_env.svh"
  //`include "codec_registers_uvm_reg_model.sv"

endpackage