class core_control_item extends uvm_sequence_item;

  rand bit [30:0] rst_vec;
  rand bit nmi_int;
  rand bit [30:0] nmi_vec;
  rand bit [30:0] jtag_id;

  `uvm_object_utils(core_control_item)

  function new(string name="core_control_item"); super.new(name); endfunction
endclass
