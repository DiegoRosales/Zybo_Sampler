// This contains all the sequencers

class codec_unit_top_virtual_sequencer extends uvm_virtual_sequencer;

    axi4_lite_bfm_sequencer axi4_lite_sequencer;
    i2s_bfm_sequencer       i2s_sequencer;

    `uvm_component_utils(codec_unit_top_virtual_sequencer)

    function new(string name="codec_unit_top_virtual_sequencer", uvm_component parent=null);
        super.new(name, parent);
    endfunction

endclass