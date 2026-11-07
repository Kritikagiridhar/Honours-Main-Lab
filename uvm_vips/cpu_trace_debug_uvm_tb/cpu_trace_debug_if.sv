interface cpu_trace_debug_if;
  logic clk;
  logic rst_n;
  logic [31:0] trace_rv_i_insn_ip;
  logic [31:0] trace_rv_i_address_ip;
  logic trace_rv_i_valid_ip;
  logic trace_rv_i_exception_ip;
  logic [4:0] trace_rv_i_ecause_ip;
  logic trace_rv_i_interrupt_ip;
  logic [31:0] trace_rv_i_tval_ip;
  logic o_cpu_halt_status;
  logic o_cpu_halt_ack;
  logic o_debug_mode_status;
endinterface
