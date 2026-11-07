class watchdog_env extends uvm_env;
  watchdog_agent agent;
  watchdog_scoreboard sb;
  `uvm_component_utils(watchdog_env)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = watchdog_agent::type_id::create("agent", this);
    sb    = watchdog_scoreboard::type_id::create("sb", this);
  endfunction
endclass
