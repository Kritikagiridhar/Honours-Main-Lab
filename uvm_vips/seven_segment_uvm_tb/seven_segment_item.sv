class seven_segment_item extends uvm_sequence_item;

  bit [7:0] ssd_seg;
  bit [3:0] ssd_digit_sel;

  `uvm_object_utils(seven_segment_item)

  function new(string name="seven_segment_item"); super.new(name); endfunction
endclass
