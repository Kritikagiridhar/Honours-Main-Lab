class external_interrupt_sequencer extends uvm_sequencer #(external_interrupt_item);
`uvm_component_utils(external_interrupt_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
