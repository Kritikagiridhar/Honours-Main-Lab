class sample_bus_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sample_bus_scoreboard)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
