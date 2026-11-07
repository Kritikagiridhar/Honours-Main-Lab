class core_control_env extends uvm_env;
  core_control_agent agent;
  core_control_scoreboard sb;
  `uvm_component_utils(core_control_env)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = core_control_agent::type_id::create("agent", this);
    sb    = core_control_scoreboard::type_id::create("sb", this);
  endfunction
endclass
