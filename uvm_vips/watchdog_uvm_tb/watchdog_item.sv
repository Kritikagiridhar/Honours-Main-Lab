class watchdog_item extends uvm_sequence_item;

  bit wdt_reset_out;

  `uvm_object_utils(watchdog_item)

  function new(string name="watchdog_item"); super.new(name); endfunction
endclass
