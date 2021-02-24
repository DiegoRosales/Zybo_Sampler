// Test environment
class codec_unit_top_base_test_env extends uvm_env;

  // UVM Agents
  i2s_bfm_agent               i2s_agent;
  axi4_lite_bfm_agent         axi4_lite_agent;
  clock_and_reset_bfm_agent   clock_and_reset_agent;

  // UVM Adapters
  axi4_lite_bfm_reg_adapter   axi4_lite_reg_adapter;

  // Virtual Sequencer
  codec_unit_top_virtual_sequencer virtual_sequencer;

  // Register model
  codec_registers_uvm_reg_block    register_model;

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
    clock_and_reset_agent = clock_and_reset_bfm_agent        ::type_id::create("clock_and_reset_agent", this);
    i2s_agent             = i2s_bfm_agent                    ::type_id::create("i2s_agent",             this);
    axi4_lite_agent       = axi4_lite_bfm_agent              ::type_id::create("axi4_lite_agent",       this);
    axi4_lite_reg_adapter = axi4_lite_bfm_reg_adapter        ::type_id::create("axi4_lite_reg_adapter", this);
    virtual_sequencer     = codec_unit_top_virtual_sequencer ::type_id::create("virtual_sequencer",     this);

    uvm_config_db #(clock_and_reset_bfm_cfg)::set(this, "clock_and_reset_agent", "clock_and_reset_cfg", cfg.clock_and_reset_cfg);

    // Register model configuration
    register_model = codec_registers_uvm_reg_block::type_id::create("register_model", this, "");
    register_model.build();
    register_model.lock_model();
    register_model.default_map.set_auto_predict(1);
    register_model.reset();
    `uvm_info(get_name(), "Register model built", UVM_LOW)

  endfunction

  // Connect phase
  function void connect_phase(uvm_phase phase);
    // Virtual Sequencer
    virtual_sequencer.axi4_lite_sequencer = axi4_lite_agent.sequencer;
    virtual_sequencer.i2s_sequencer       = i2s_agent.sequencer;
    // Connect the register model to the AXI4 Lite interface
    register_model.default_map.set_auto_predict(1);
    register_model.default_map.set_sequencer(virtual_sequencer.axi4_lite_sequencer, axi4_lite_reg_adapter);

  endfunction
endclass