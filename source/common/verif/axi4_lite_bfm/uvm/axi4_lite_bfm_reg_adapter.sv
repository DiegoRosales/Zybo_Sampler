// Reg adapter for the AXI4 Lite interface

class axi4_lite_bfm_reg_adapter extends uvm_reg_adapter;

    `uvm_object_utils(axi4_lite_bfm_reg_adapter)

    function new(string name="axi4_lite_bfm_reg_adapter");
        super.new(name);
        provides_responses = 1;
    endfunction


    // Adapt register read/write to AXI transfer items
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        axi4_lite_bfm_transfer_item transfer = axi4_lite_bfm_transfer_item::type_id::create("transfer");

        `uvm_info(get_name(), "Calling AXI4 reg2bus", UVM_LOW)

        // TODO
        transfer.data        = rw.data;
        transfer.address     = rw.addr;
        transfer.access_type = rw.kind;

        return transfer;
    endfunction

    // Adapt AXI transfer items to uvm register operations
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        axi4_lite_bfm_transfer_item transfer;// = axi4_lite_bfm_transfer_item::type_id::create("transfer");
        `uvm_info(get_name(), "Calling AXI4 bus2reg", UVM_LOW)
        
        if (!$cast(transfer, bus_item)) begin
            `uvm_fatal("CAST_ERROR", "ERROR. Failed to cast the bus_item to an AXI4 transfer item")
        end

        rw.data   = transfer.data;
        rw.status = UVM_IS_OK;
        rw.kind   = transfer.access_type;
        
        `uvm_info(get_name(), $sformatf("bus2reg returning %0h", rw.data), UVM_LOW)
    endfunction


endclass