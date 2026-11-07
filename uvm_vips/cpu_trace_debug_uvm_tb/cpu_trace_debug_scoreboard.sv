class cpu_trace_debug_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cpu_trace_debug_scoreboard)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
