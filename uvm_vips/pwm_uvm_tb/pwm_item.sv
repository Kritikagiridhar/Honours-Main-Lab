class pwm_item extends uvm_sequence_item;

  bit [3:0] pwm_out;

  `uvm_object_utils(pwm_item)

  function new(string name="pwm_item"); super.new(name); endfunction
endclass
