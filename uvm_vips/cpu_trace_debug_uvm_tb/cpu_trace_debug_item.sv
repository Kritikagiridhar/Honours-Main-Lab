class cpu_trace_debug_item extends uvm_sequence_item;

  bit [31:0] trace_rv_i_insn_ip;
  bit [31:0] trace_rv_i_address_ip;
  bit trace_rv_i_valid_ip;
  bit trace_rv_i_exception_ip;
  bit [4:0] trace_rv_i_ecause_ip;
  bit trace_rv_i_interrupt_ip;
  bit [31:0] trace_rv_i_tval_ip;
  bit o_cpu_halt_status;
  bit o_cpu_halt_ack;
  bit o_debug_mode_status;

  `uvm_object_utils(cpu_trace_debug_item)

  function new(string name="cpu_trace_debug_item"); super.new(name); endfunction
endclass
