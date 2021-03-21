/////////////////////////////////////
// AXI4-Lite BFM Driver
/////////////////////////////////////

class axi4_lite_bfm_driver extends uvm_driver #(axi4_lite_bfm_transfer_item);

  // I2S Virtual Interface
  virtual axi4_lite_if        vif;
  int                         configured_if;

  `uvm_component_utils(axi4_lite_bfm_driver)
 
  // Constructor
  function new (string name="axi4_lite_bfm_driver", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    
    `uvm_info(get_full_name(), "Building the AXI4 Lite BFM Driver...", UVM_LOW)

    // The virtual interface must be configured
    configured_if = uvm_config_db#(virtual axi4_lite_if)::get(this, "", "vif", vif);
    if(!configured_if) begin
      `uvm_fatal("NO_VIRTUAL_INTERFACE_CONFIGURED", $sformatf("The Virtual Interface wasn't configured for %s", get_full_name()));
    end
    
    `uvm_info(get_full_name(), "Building the AXI4 Lite BFM Driver Done!", UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    reset_signals();
    forever begin
      // Get and drive
      seq_item_port.get_next_item(req);
      rsp = axi4_lite_bfm_transfer_item::type_id::create("response");
      rsp.set_id_info(req);

      if (req.access_type == UVM_READ)  drive_read_transaction();
      else                              drive_write_transaction();
      `uvm_info(get_name(), $sformatf("Driver returning %0h", rsp.data), UVM_LOW)
      seq_item_port.item_done(rsp);
    end
  endtask

  protected task drive_read_transaction();
    `uvm_info(get_full_name(), "Driving Read transaction", UVM_LOW)

    vif.awaddr  = 'h0;
    vif.awprot  = 'h0;
    vif.awvalid = 'h0;
    vif.wdata   = 'h0;
    vif.wstrb   = 'h0;
    vif.wvalid  = 'h0;
    vif.bready  = 'h0;

    // Read request
    vif.araddr  = req.address;
    vif.arvalid = 'h1;
    vif.rready  = 'h1;
    vif.arprot  = 'h0;
    // Wait for rvalid
    while(!vif.rvalid) @(posedge vif.clock);
    rsp.data    = vif.rdata;
    vif.rready  = 'h0;
    vif.arvalid = 'h0;
    vif.araddr  = 'h0;

  endtask

  protected task drive_write_transaction();
    `uvm_info(get_full_name(), "Driving Write transaction", UVM_LOW)
    @(posedge vif.clock);
    rsp.data = 32'hdead_beef;
  endtask

  task reset_signals();
    // Write
    vif.awaddr  = 'h0;
    vif.awprot  = 'h0;
    vif.awvalid = 'h0;
    vif.wdata   = 'h0;
    vif.wstrb   = 'h0;
    vif.wvalid  = 'h0;
    vif.bready  = 'h0;
    // Read
    vif.araddr  = 'h0;
    vif.arprot  = 'h0;
    vif.arvalid = 'h0;
    vif.rready  = 'h0;
  endtask

endclass : axi4_lite_bfm_driver