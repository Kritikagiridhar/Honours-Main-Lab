module tb_top;
  import uvm_pkg::*;
  import pwm_pkg::*;

  logic clk;
  logic rst_n;

  // Clock generation using always block
  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 1'b0;
    #20 rst_n = 1'b1;
  end

  pwm_if vif();
  assign vif.clk   = clk;
  assign vif.rst_n = rst_n;

  initial begin
    uvm_config_db#(virtual pwm_if)::set(null, "uvm_test_top*", "pwm_vif", vif);
    run_test("pwm_test");
  end
endmodule
