class pwm_sequencer extends uvm_sequencer #(pwm_item);
`uvm_component_utils(pwm_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
