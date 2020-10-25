// clock_and_reset Verification IP UVM Agent

class clock_and_reset_bfm_agent extends uvm_agent;

  // Configuration
  clock_and_reset_bfm_cfg clock_and_reset_cfg;

  // Components
  clock_and_reset_bfm_driver driver;

  // Virtual interface
  virtual clock_and_reset_if virtual_if;

  `uvm_component_utils_begin(clock_and_reset_bfm_agent)
    `uvm_field_object(clock_and_reset_cfg, UVM_DEFAULT)
  `uvm_component_utils_end

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Building phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    `uvm_info(get_full_name(), "Building clock_and_reset Verification IP UVM Agent...", UVM_LOW)

    if (get_is_active() == UVM_ACTIVE) begin
      `uvm_info(get_full_name(), "clock_and_reset Verification IP Agent is active!", UVM_LOW)

      // The virtual interface must be configured
      if(!uvm_config_db#(clock_and_reset_bfm_cfg)::get(this, "", "clock_and_reset_cfg", clock_and_reset_cfg)) begin
        `uvm_warning("NO_VIRTUAL_CFG_CONFIGURED", $sformatf("The Configuration wasn't set for %s", get_full_name()));
        clock_and_reset_cfg = clock_and_reset_bfm_cfg::type_id::create("clock_and_reset_cfg", this);
      end

      // The virtual interface must be configured
      if(!uvm_config_db#(virtual clock_and_reset_if)::get(this, "", "virtual_if", virtual_if)) begin
        `uvm_fatal("NO_VIRTUAL_INTERFACE_CONFIGURED", $sformatf("The Virtual Interface wasn't configured for %s", get_full_name()));
      end

      // Build the driver
      driver    = clock_and_reset_bfm_driver::type_id::create("driver", this);

      // Configure
      driver.bfm_cfg = clock_and_reset_cfg;

      // Configure the virtual interface
      uvm_config_db#(virtual clock_and_reset_if)::set(this, "driver*", "virtual_if", virtual_if);
    end
    `uvm_info(get_full_name(), "Building clock_and_reset Verification IP UVM Agent Done!", UVM_LOW)
  endfunction

  // Connection phase
  function void connect_phase(uvm_phase phase);
    // Check if the agent is active
    if (get_is_active() == UVM_ACTIVE) begin
      // Connect the driver with the sequencer
    end
  endfunction

endclass