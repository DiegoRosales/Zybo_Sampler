// clock_and_reset UVM Driver
// The driver receives a transfer of type clock_and_reset_bfm_transfer

class clock_bfm_driver extends uvm_driver;

  // clock_and_reset Virtual Interface
  virtual clock_and_reset_if     virtual_if;
  clock_and_reset_bfm_cfg        bfm_cfg;

  `uvm_component_utils(clock_bfm_driver)
 
  // Constructor
  function new (string name="clock_bfm_driver", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // Build Phase
  function void build_phase(uvm_phase phase);
    
    `uvm_info(get_full_name(), "Building the clock driver...", UVM_LOW)

    // The virtual interface must be configured
    if(!uvm_config_db#(virtual clock_and_reset_if)::get(this, "", "virtual_if", virtual_if)) begin
      `uvm_fatal("NO_VIRTUAL_INTERFACE_CONFIGURED", $sformatf("The Virtual Interface wasn't configured for %s", get_full_name()));
    end
    
    `uvm_info(get_full_name(), "Building the clock driver Done!", UVM_LOW)
  endfunction

  // Run Phase
  virtual task run_phase(uvm_phase phase);
    drive_clock();
  endtask

  ////////////////////////////////////////////

  protected task drive_clock();
    `uvm_info(get_full_name(), "Driving clock", UVM_LOW)
    virtual_if.clock = 1'b0;
    forever #(bfm_cfg.clock_period) virtual_if.clock = ~virtual_if.clock;
  endtask

endclass : clock_bfm_driver