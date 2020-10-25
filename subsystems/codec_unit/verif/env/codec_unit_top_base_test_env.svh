// Test environment
class codec_unit_top_base_test_env extends uvm_env;

  // UVM Agents
  i2s_bfm_agent               i2s_agent;
  clock_and_reset_bfm_agent   clock_and_reset_agent;

  // Agent configuration
  codec_unit_top_cfg        cfg;

  `uvm_component_utils(codec_unit_top_base_test_env)

  function new(string name = "codec_unit_top_base_test_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create the configuration
    if (cfg == null) begin
      cfg = codec_unit_top_cfg::type_id::create("cfg", this);
    end
  
    // Build the agents
    i2s_agent             = i2s_bfm_agent::type_id::create            ("i2s_agent",             this);
    clock_and_reset_agent = clock_and_reset_bfm_agent::type_id::create("clock_and_reset_agent", this);

    uvm_config_db #(clock_and_reset_bfm_cfg)::set(this, "clock_and_reset_agent", "clock_and_reset_cfg", cfg.clock_and_reset_cfg);
  endfunction
endclass