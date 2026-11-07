class cpu_trace_debug_sequencer extends uvm_sequencer #(cpu_trace_debug_item);
`uvm_component_utils(cpu_trace_debug_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
