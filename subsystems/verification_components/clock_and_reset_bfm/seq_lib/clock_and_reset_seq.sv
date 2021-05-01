//////////////////////////////////////
// Clock and reset sequences
//////////////////////////////////////

class reset_seq extends uvm_sequence #(reset_item);

  `uvm_object_utils(reset_seq)

  //Constructor
  function new(string name = "reset_seq");
    super.new(name);
  endfunction


  // Body
  virtual task body();
    `uvm_do(req)
  endtask
endclass