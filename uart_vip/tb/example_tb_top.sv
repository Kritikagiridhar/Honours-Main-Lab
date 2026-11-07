// example_tb_top.sv
// Testbench top for UART VIP + UART DUT.
//
// Demonstrates UVM verification using virtual interface and uvm_config_db.
// Follows UVM Cookbook guidelines (virtual interface registration and connection).
// Provides complete waveform dumping (FSDB for Verdi, VCD for standard viewers).
//
// Compile order:
//   1. uart_if.sv
//   2. uart_vip_pkg.sv
//   3. uart_dut.sv
//   4. example_tb_top.sv

`timescale 1ns/1ps

module example_tb_top;

  import uvm_pkg::*;
  import uart_vip_pkg::*;
  `include "uvm_macros.svh"

  localparam int CLK_PERIOD_NS = 10; // 100 MHz clock

  logic clk = 1'b0;
  logic rst_n;

  // Clock generation using always block
  always #(CLK_PERIOD_NS / 2) clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 1'b0;
    repeat (10) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    `uvm_info("TB_TOP", "Reset deasserted successfully", UVM_NONE)
  end

  // Instantiate physical interface
  uart_if u_if (
    .clk   (clk),
    .rst_n (rst_n)
  );

  // Instantiate DUT and connect interface signals
  uart_dut #(
    .CLOCKS_PER_BIT (16)
  ) u_dut (
    .clk   (clk),
    .rst_n (rst_n),
    .rx    (u_if.uart_rx),
    .tx    (u_if.uart_tx),
    .irq   (u_if.uart_irq)
  );

  // Configure virtual interface into uvm_config_db and start UVM test
  initial begin
    uvm_config_db #(virtual uart_if)::set(null, "*", "vif", u_if);
    uvm_config_db #(virtual uart_if)::set(null, "uvm_test_top", "vif", u_if);
    run_test();
  end

  // Waveform generation for Synopsys Verdi (FSDB) and standard waveform viewers (VCD)
  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, example_tb_top, "+all");
    $fsdbDumpMDA();
    $dumpfile("dump.vcd");
    $dumpvars(0, example_tb_top);
  end

  // Simulation watchdog timeout
  initial begin
    #50_000_000;
    `uvm_fatal("TIMEOUT", "Simulation watchdog timed out!")
  end

endmodule : example_tb_top
