// Base Test

class codec_unit_top_testcase_1 extends codec_unit_top_base_test;

  `uvm_component_utils(codec_unit_top_testcase_1)

  function new(string name = "codec_unit_top_testcase_1", uvm_component parent=null);
    super.new(name, parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  task run_phase( uvm_phase phase );
    phase.raise_objection(this);
    super.run_phase(phase);
    `uvm_info(get_name(), "This is the first testcase!", UVM_LOW)
    #1000
    `uvm_info(get_name(), "Goodbye from the first testcase!", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass