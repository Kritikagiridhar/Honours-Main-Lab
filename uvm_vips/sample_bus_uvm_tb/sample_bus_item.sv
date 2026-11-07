class sample_bus_item extends uvm_sequence_item;

  rand bit [31:0] addr;
  rand bit [31:0] wdata;
  rand bit write;
  bit [31:0] rdata;
  bit ready;

  `uvm_object_utils(sample_bus_item)

  function new(string name="sample_bus_item"); super.new(name); endfunction
endclass
