class sample_bus_env extends uvm_env;
  sample_bus_agent agent;
  sample_bus_scoreboard sb;
  `uvm_component_utils(sample_bus_env)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = sample_bus_agent::type_id::create("agent", this);
    sb    = sample_bus_scoreboard::type_id::create("sb", this);
  endfunction
endclass
