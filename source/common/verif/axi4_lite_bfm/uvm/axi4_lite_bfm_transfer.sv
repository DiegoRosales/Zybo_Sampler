/////////////////////////////////////
// AXI4-Lite BFM Transfer Item
/////////////////////////////////////

class axi4_lite_bfm_transfer extends uvm_sequence_item;

  bit [31:0] address;
  bit [31:0] data[$];

  `uvm_object_utils(axi4_lite_bfm_transfer)

  function new (string name = "axi4_lite_bfm_transfer");
    super.new(name);
  endfunction

endclass