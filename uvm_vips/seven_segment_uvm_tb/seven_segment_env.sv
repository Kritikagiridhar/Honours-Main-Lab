class seven_segment_env extends uvm_env;
  seven_segment_agent agent;
  seven_segment_scoreboard sb;
  `uvm_component_utils(seven_segment_env)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = seven_segment_agent::type_id::create("agent", this);
    sb    = seven_segment_scoreboard::type_id::create("sb", this);
  endfunction
endclass
