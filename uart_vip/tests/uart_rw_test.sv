// uart_rw_test.sv
// Test that executes UART transactions and verifies transmission and reception.

class uart_rw_test extends uvm_test;
  `uvm_component_utils(uart_rw_test)

  uart_cfg cfg;
  uart_env env;

  function new(string name = "uart_rw_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    virtual uart_if vif_h;
    super.build_phase(phase);

    if (!uvm_config_db #(virtual uart_if)::get(this, "", "vif", vif_h)) begin
      `uvm_fatal(get_type_name(), "virtual uart_if not found in uvm_config_db")
    end

    cfg                = uart_cfg::type_id::create("cfg");
    cfg.vif            = vif_h;
    cfg.mode           = UART_ACTIVE;
    cfg.clocks_per_bit = 16;
    cfg.baud_rate      = 115200;

    uvm_config_db #(uart_cfg)::set(this, "env", "cfg", cfg);
    env = uart_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    uart_tx_seq seq;
    phase.raise_objection(this);

    // Wait after reset
    repeat (50) @(posedge cfg.vif.clk);

    `uvm_info(get_type_name(), "Starting UART RW Test...", UVM_NONE)

    seq         = uart_tx_seq::type_id::create("seq");
    seq.n_trans = 5;
    seq.start(env.agent.seqr);

    // Wait for all bits to be transmitted and received
    repeat (cfg.clocks_per_bit * 100) @(posedge cfg.vif.clk);

    `uvm_info(get_type_name(), "UART RW Test completed successfully.", UVM_NONE)
    phase.drop_objection(this);
  endtask

endclass : uart_rw_test
