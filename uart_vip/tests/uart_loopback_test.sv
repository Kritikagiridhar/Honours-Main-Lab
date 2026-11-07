// uart_loopback_test.sv
// Test running deterministic loopback byte patterns and verifying with scoreboard.

class uart_loopback_test extends uvm_test;
  `uvm_component_utils(uart_loopback_test)

  uart_cfg cfg;
  uart_env env;

  function new(string name = "uart_loopback_test", uvm_component parent = null);
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
    uart_loopback_seq seq;
    phase.raise_objection(this);

    repeat (50) @(posedge cfg.vif.clk);

    `uvm_info(get_type_name(), "Starting UART Loopback Pattern Test...", UVM_NONE)

    // Preload scoreboard with expected patterns
    env.sb.add_expected(8'hA5);
    env.sb.add_expected(8'h5A);
    env.sb.add_expected(8'h33);
    env.sb.add_expected(8'hCC);
    env.sb.add_expected(8'hF0);

    seq = uart_loopback_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    repeat (cfg.clocks_per_bit * 100) @(posedge cfg.vif.clk);

    `uvm_info(get_type_name(), "UART Loopback Test completed successfully.", UVM_NONE)
    phase.drop_objection(this);
  endtask

endclass : uart_loopback_test
