class watchdog_sequencer extends uvm_sequencer #(watchdog_item);
`uvm_component_utils(watchdog_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
