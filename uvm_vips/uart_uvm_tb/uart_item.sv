class uart_item extends uvm_sequence_item;

  rand bit uart_rx;
  bit uart_tx;
  bit uart_irq;

  `uvm_object_utils(uart_item)

  function new(string name="uart_item"); super.new(name); endfunction
endclass
