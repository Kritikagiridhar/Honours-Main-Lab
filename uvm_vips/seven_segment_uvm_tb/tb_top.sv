module tb_top;
  import uvm_pkg::*;
  import seven_segment_pkg::*;

  logic clk;
  logic rst_n;

  // Clock generation using always block
  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 1'b0;
    #20 rst_n = 1'b1;
  end

  seven_segment_if vif();
  assign vif.clk   = clk;
  assign vif.rst_n = rst_n;

  initial begin
    uvm_config_db#(virtual seven_segment_if)::set(null, "uvm_test_top*", "seven_segment_vif", vif);
    run_test("seven_segment_test");
  end
endmodule
