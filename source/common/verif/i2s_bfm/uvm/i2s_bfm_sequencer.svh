// I2S Verification IP Sequencer
// It passes transfer information of uvm_sequence_item type i2s_bfm_transfer

class i2s_bfm_sequencer extends uvm_sequencer #(i2s_bfm_transfer);
 
   `uvm_sequencer_utils(i2s_bfm_sequencer)
      
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new
 
endclass : i2s_bfm_sequencer