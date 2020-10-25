// I2S UVM Driver
// The driver receives a transfer of type i2s_bfm_transfer

class i2s_bfm_driver extends uvm_driver #(i2s_bfm_transfer);

  // I2S Virtual Interface
  i2s_vif          virtual_if;
  int              configured_if;
  i2s_bfm_transfer transfer;

  `uvm_component_utils(i2s_bfm_driver)
 
  // Constructor
  function new (string name="i2s_bfm_driver", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    
    `uvm_info(get_full_name(), "Building the I2S VIP Driver...", UVM_LOW)

    // The virtual interface must be configured
    configured_if = uvm_config_db#(virtual i2s_if)::get(this, "", "i2s_vif", virtual_if);
    if(!configured_if) begin
      `uvm_fatal("NO_VIRTUAL_INTERFACE_CONFIGURED", $sformatf("The Virtual Interface wasn't configured for %s", get_full_name()));
    end
    
    `uvm_info(get_full_name(), "Building the I2S VIP Driver Done!", UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      drive_clock();
    join
  endtask

  protected task drive_clock();
    `uvm_info(get_full_name(), "Driving ac_bclk", UVM_LOW)
    virtual_if.ac_bclk = 1'b0;
    forever #20.8 virtual_if.ac_bclk = ~virtual_if.ac_bclk;
  endtask

endclass : i2s_bfm_driver