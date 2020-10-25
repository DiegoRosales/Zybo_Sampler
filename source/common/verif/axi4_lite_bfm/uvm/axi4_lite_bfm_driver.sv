/////////////////////////////////////
// AXI4-Lite BFM Driver
/////////////////////////////////////

class axi4_lite_bfm_driver extends uvm_driver #(axi4_lite_bfm_transfer);

  // I2S Virtual Interface
  virtual axi4_lite_if virtual_if;
  int                      configured_if;
  axi4_lite_bfm_transfer   transfer;

  `uvm_component_utils(axi4_lite_bfm_driver)
 
  // Constructor
  function new (string name="axi4_lite_bfm_driver", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    
    `uvm_info(get_full_name(), "Building the AXI4 Lite BFM Driver...", UVM_LOW)

    // The virtual interface must be configured
    configured_if = uvm_config_db#(virtual axi4_lite_if)::get(this, "", "axi4_lite_vif", virtual_if);
    if(!configured_if) begin
      `uvm_fatal("NO_VIRTUAL_INTERFACE_CONFIGURED", $sformatf("The Virtual Interface wasn't configured for %s", get_full_name()));
    end
    
    `uvm_info(get_full_name(), "Building the AXI4 Lite BFM Driver Done!", UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      drive_clock();
    join
  endtask

  protected task drive_clock();
    `uvm_info(get_full_name(), "Driving ac_bclk", UVM_LOW)
  endtask

endclass : axi4_lite_bfm_driver