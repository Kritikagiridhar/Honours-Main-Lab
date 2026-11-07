class sample_bus_sequencer extends uvm_sequencer #(sample_bus_item);
`uvm_component_utils(sample_bus_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
