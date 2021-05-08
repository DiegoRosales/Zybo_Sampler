/////////////////////////////////////
// AXI4-Lite BFM Package
/////////////////////////////////////

package axi4_lite_bfm_pkg;

    // Mandatory UVM
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Agent
    `include "uvm/axi4_lite_bfm_transfer_item.sv"
    `include "uvm/axi4_lite_bfm_driver.sv"
    `include "uvm/axi4_lite_bfm_sequencer.sv"
    `include "uvm/axi4_lite_bfm_reg_adapter.sv"
    `include "uvm/axi4_lite_bfm_agent.sv"

endpackage