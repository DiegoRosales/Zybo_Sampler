

class clock_and_reset_bfm_cfg extends uvm_object;

    real clock_period   = 8ns;
    bit  reset_polarity = 0;

    `uvm_object_utils(clock_and_reset_bfm_cfg)

    function new (string name = "clock_and_reset_bfm_cfg");
      super.new(name);
    endfunction: new

endclass