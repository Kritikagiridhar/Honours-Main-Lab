class external_interrupt_env extends uvm_env;
  external_interrupt_agent agent;
  external_interrupt_scoreboard sb;
  `uvm_component_utils(external_interrupt_env)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = external_interrupt_agent::type_id::create("agent", this);
    sb    = external_interrupt_scoreboard::type_id::create("sb", this);
  endfunction
endclass
