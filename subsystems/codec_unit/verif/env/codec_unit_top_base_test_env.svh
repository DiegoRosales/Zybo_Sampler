// Test environment
class codec_unit_top_base_test_env extends uvm_env;

  `uvm_component_utils(codec_unit_top_base_test_env)

  i2s_bfm_agent i2s_agent;

  function new(string name = "codec_unit_top_base_test_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Build the agents
    i2s_agent = i2s_bfm_agent::type_id::create("i2s_agent", this);

  endfunction
endclass