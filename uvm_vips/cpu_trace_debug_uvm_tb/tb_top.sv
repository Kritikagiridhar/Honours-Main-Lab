module tb_top;
  import uvm_pkg::*;
  import cpu_trace_debug_pkg::*;

  logic clk;
  logic rst_n;

  // Clock generation using always block
  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 1'b0;
    #20 rst_n = 1'b1;
  end

  cpu_trace_debug_if vif();
  assign vif.clk   = clk;
  assign vif.rst_n = rst_n;

  initial begin
    uvm_config_db#(virtual cpu_trace_debug_if)::set(null, "uvm_test_top*", "cpu_trace_debug_vif", vif);
    run_test("cpu_trace_debug_test");
  end
endmodule
