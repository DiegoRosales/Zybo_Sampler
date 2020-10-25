// clock_and_reset UVM Driver
// The driver receives a transfer of type clock_and_reset_bfm_transfer

class clock_and_reset_bfm_driver extends uvm_driver;

  // clock_and_reset Virtual Interface
  virtual clock_and_reset_if     virtual_if;
  clock_and_reset_bfm_cfg        bfm_cfg;

  `uvm_component_utils(clock_and_reset_bfm_driver)
 
  // Constructor
  function new (string name="clock_and_reset_bfm_driver", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    
    `uvm_info(get_full_name(), "Building the clock_and_reset VIP Driver...", UVM_LOW)

    // The virtual interface must be configured
    if(!uvm_config_db#(virtual clock_and_reset_if)::get(this, "", "virtual_if", virtual_if)) begin
      `uvm_fatal("NO_VIRTUAL_INTERFACE_CONFIGURED", $sformatf("The Virtual Interface wasn't configured for %s", get_full_name()));
    end
    
    `uvm_info(get_full_name(), "Building the clock_and_reset VIP Driver Done!", UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      drive_clock();
      drive_reset();
    join
  endtask

  protected task drive_clock();
    `uvm_info(get_full_name(), "Driving clock", UVM_LOW)
    virtual_if.clock = 1'b0;
    forever #(bfm_cfg.clock_period) virtual_if.clock = ~virtual_if.clock;
  endtask

  protected task drive_reset();
    // Assert Reset
    `uvm_info(get_full_name(), "Asserting Reset", UVM_LOW)
    virtual_if.reset = bfm_cfg.reset_polarity;

    repeat(20) @(posedge virtual_if.clock);

    // Deassert Reset
    `uvm_info(get_full_name(), "Deasserting Reset", UVM_LOW)
    virtual_if.reset = ~bfm_cfg.reset_polarity;
  endtask

endclass : clock_and_reset_bfm_driver