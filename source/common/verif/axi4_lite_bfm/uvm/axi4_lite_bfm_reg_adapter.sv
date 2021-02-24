// Reg adapter for the AXI4 Lite interface

class axi4_lite_bfm_reg_adapter extends uvm_reg_adapter;

    `uvm_object_utils(axi4_lite_bfm_reg_adapter)

    function new(string name="axi4_lite_bfm_reg_adapter");
        super.new(name);
    endfunction


    // Adapt register read/write to AXI transfer items
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        axi4_lite_bfm_transfer transfer = axi4_lite_bfm_transfer::type_id::create("transfer");

        `uvm_info(get_name(), "Calling AXI4 reg2bus", UVM_LOW)

        // TODO
        transfer.address = 32'h0;
        transfer.data    = {32'h0};

        return transfer;
    endfunction

    // Adapt AXI transfer items to uvm register operations
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        axi4_lite_bfm_transfer transfer = axi4_lite_bfm_transfer::type_id::create("transfer");
        `uvm_info(get_name(), "Calling AXI4 bus2reg", UVM_LOW)

        
        if (!$cast(transfer, bus_item)) begin
            `uvm_fatal("CAST_ERROR", "ERROR. Failed to cast the bus_item to an AXI4 transfer item")
        end

    endfunction


endclass