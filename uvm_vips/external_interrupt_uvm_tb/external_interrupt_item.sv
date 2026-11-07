class external_interrupt_item extends uvm_sequence_item;

  rand bit [23:0] ext_irq;
  rand bit timer_int;

  `uvm_object_utils(external_interrupt_item)

  function new(string name="external_interrupt_item"); super.new(name); endfunction
endclass
