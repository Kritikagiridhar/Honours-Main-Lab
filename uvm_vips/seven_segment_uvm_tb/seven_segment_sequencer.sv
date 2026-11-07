class seven_segment_sequencer extends uvm_sequencer #(seven_segment_item);
`uvm_component_utils(seven_segment_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
