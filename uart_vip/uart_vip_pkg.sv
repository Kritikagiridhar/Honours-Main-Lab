// uart_vip_pkg.sv
// UART VIP Package
// Package includes all VIP classes in correct order.
// uart_if.sv must be compiled before this package.

package uart_vip_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum logic {
    UART_PASSIVE = 1'b0,
    UART_ACTIVE  = 1'b1
  } uart_agent_mode_e;

  // -- Common -------------------------------------------------
  `include "../common/uart_seq_item.sv"
  `include "../common/uart_cfg.sv"

  // -- Agent --------------------------------------------------
  `include "../agent/uart_sequencer.sv"
  `include "../agent/uart_driver.sv"
  `include "../agent/uart_monitor.sv"
  `include "../agent/uart_agent.sv"

  // -- Sequences ----------------------------------------------
  `include "../seq/uart_tx_seq.sv"
  `include "../seq/uart_loopback_seq.sv"

  // -- Environment --------------------------------------------
  `include "../env/uart_scoreboard.sv"
  `include "../env/uart_env.sv"

  // -- Tests --------------------------------------------------
  `include "../tests/uart_rw_test.sv"
  `include "../tests/uart_loopback_test.sv"

endpackage : uart_vip_pkg
