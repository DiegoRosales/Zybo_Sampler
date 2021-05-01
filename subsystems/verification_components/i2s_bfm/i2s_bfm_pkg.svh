// I2S Verification IP Package

package i2s_bfm_pkg;
    // Mandatory UVM
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef virtual i2s_if i2s_vif;

    `include "uvm/i2s_bfm_transfer.svh"  // Items for the transfer
    `include "uvm/i2s_bfm_driver.svh"    // Toggles signals
    `include "uvm/i2s_bfm_sequencer.svh" // Ties the driver with the sequence
    `include "uvm/i2s_bfm_agent.svh"     // Collection of all of the above

endpackage