// Base Test

class codec_unit_top_base_test extends uvm_test;

  `uvm_component_utils(codec_unit_top_base_test)

  function new(string name = "codec_unit_top_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  task run_phase( uvm_phase phase );
    #100
    `uvm_info(get_name(), "Hello from the Base Test!", UVM_LOW)
  endtask

endclass