/////////////////////////////////////
// AXI4-Lite BFM Transfer Item
/////////////////////////////////////

class axi4_lite_bfm_transfer_item extends uvm_sequence_item;

  bit [31:0]   address;
  bit [31:0]   data;
  uvm_access_e access_type;

  `uvm_object_utils(axi4_lite_bfm_transfer_item)

  function new (string name = "axi4_lite_bfm_transfer_item");
    super.new(name);
  endfunction

endclass