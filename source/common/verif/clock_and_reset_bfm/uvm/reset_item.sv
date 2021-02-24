//////////////////////////////////////////
// Reset Item
//////////////////////////////////////////

class reset_item extends uvm_sequence_item;

  rand int rst_delay;

  `uvm_object_utils_begin(reset_item)
    `uvm_field_int(rst_delay, UVM_DEFAULT)
  `uvm_object_utils_end

  //Constructor
  function new(string name = "reset_item");
    super.new(name);
  endfunction

  constraint rst_delay_range {
    rst_delay inside {[2:20]};
  }

endclass