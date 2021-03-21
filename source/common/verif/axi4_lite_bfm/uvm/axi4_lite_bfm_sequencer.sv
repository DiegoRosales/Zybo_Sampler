/////////////////////////////////////
// AXI4-Lite BFM Sequencer
/////////////////////////////////////

class axi4_lite_bfm_sequencer extends uvm_sequencer #(axi4_lite_bfm_transfer_item);
 
  `uvm_sequencer_utils(axi4_lite_bfm_sequencer)
      
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new
 
endclass : axi4_lite_bfm_sequencer