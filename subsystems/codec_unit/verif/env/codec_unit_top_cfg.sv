

class codec_unit_top_cfg extends uvm_object;

  clock_and_reset_bfm_cfg   clock_and_reset_cfg;

  `uvm_object_utils_begin(codec_unit_top_cfg)
    `uvm_field_object(clock_and_reset_cfg, UVM_DEFAULT)
  `uvm_object_utils_end


  function new (string name = "codec_unit_top_cfg");
    super.new(name);

    clock_and_reset_cfg = clock_and_reset_bfm_cfg::type_id::create("clock_and_reset_cfg");

    clock_and_reset_cfg.clock_period   = 8ns;
    clock_and_reset_cfg.reset_polarity = 0;

  endfunction: new

endclass