/////////////////////////////////////
// AXI4-Lite BFM Agent
/////////////////////////////////////

class axi4_lite_bfm_agent extends uvm_agent;

  `uvm_component_utils(axi4_lite_bfm_agent)

  axi4_lite_bfm_driver    driver;
  axi4_lite_bfm_sequencer sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Building phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    `uvm_info(get_full_name(), "Building AXI4-lite Verification IP UVM Agent...", UVM_LOW)

    if (get_is_active() == UVM_ACTIVE) begin
      `uvm_info(get_full_name(), "AXI4-lite Verification IP Agent is active!", UVM_LOW)

      // Build the driver
      driver    = axi4_lite_bfm_driver::type_id::create("driver", this);
      sequencer = axi4_lite_bfm_sequencer::type_id::create("sequencer", this);
    end
    `uvm_info(get_full_name(), "Building AXI4-lite Verification IP UVM Agent Done!", UVM_LOW)
  endfunction

  // Connection phase
  function void connect_phase(uvm_phase phase);
    // Check if the agent is active
    if (get_is_active() == UVM_ACTIVE) begin
      // Connect the driver with the sequencer
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass