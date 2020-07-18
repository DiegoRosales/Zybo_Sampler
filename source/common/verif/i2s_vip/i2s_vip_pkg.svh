// I2S Verification IP Package

package i2s_vip_pkg;
    // Mandatory UVM
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef virtual i2s_if i2s_vif;

    `include "i2s_vip_transfer.svh"  // Items for the transfer
    `include "i2s_vip_driver.svh"    // Toggles signals
    `include "i2s_vip_sequencer.svh" // Ties the driver with the sequence
    `include "i2s_vip_agent.svh"     // Collection of all of the above

endpackage