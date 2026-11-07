// uart_env.sv
// Standard UVM Environment for UART VIP.
// Instantiates uart_agent and uart_scoreboard.
// Connects monitor analysis port to scoreboard export.

class uart_env extends uvm_env;
  `uvm_component_utils(uart_env)

  uart_cfg        cfg;
  uart_agent      agent;
  uart_scoreboard sb;

  function new(string name = "uart_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(uart_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "uart_cfg not found in config_db")
    end

    uvm_config_db #(uart_cfg)::set(this, "agent*", "cfg", cfg);

    agent = uart_agent     ::type_id::create("agent", this);
    sb    = uart_scoreboard::type_id::create("sb",    this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.actual_export);
  endfunction

endclass : uart_env
