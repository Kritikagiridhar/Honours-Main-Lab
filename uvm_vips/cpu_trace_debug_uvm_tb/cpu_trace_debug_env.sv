class cpu_trace_debug_env extends uvm_env;
  cpu_trace_debug_agent agent;
  cpu_trace_debug_scoreboard sb;
  `uvm_component_utils(cpu_trace_debug_env)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = cpu_trace_debug_agent::type_id::create("agent", this);
    sb    = cpu_trace_debug_scoreboard::type_id::create("sb", this);
  endfunction
endclass
