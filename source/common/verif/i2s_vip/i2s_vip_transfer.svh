// I2S Verification IP transfers

class i2s_vip_transfer extends uvm_sequence_item;

  `uvm_object_utils(i2s_vip_transfer)

  function new (string name = "i2s_vip_transfer");
    super.new(name);
  endfunction

endclass