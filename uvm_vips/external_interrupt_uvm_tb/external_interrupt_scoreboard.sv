class external_interrupt_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(external_interrupt_scoreboard)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
