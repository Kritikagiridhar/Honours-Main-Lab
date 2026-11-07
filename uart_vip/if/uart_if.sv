`timescale 1ns/1ps
// uart_if.sv
// UART Physical Interface
//
// Signals:
//   clk, rst_n
//   uart_rx (driven by VIP driver in master TX mode, sampled by DUT)
//   uart_tx (driven by DUT, sampled by VIP monitor)
//   uart_irq (interrupt line from DUT)
//
// Debug signals let you inspect serial frame content in waveforms without
// manually decoding serial bits.

interface uart_if (
  input logic clk,
  input logic rst_n
);

  logic uart_rx;   // Serial data driven into DUT
  logic uart_tx;   // Serial data received from DUT
  logic uart_irq;  // Interrupt from DUT

  // Driver debug signals
  logic [7:0] dbg_drv_data;
  logic       dbg_drv_busy;
  logic       dbg_drv_done;

  // Monitor debug signals
  logic [7:0] dbg_mon_data;
  logic       dbg_mon_valid;
  logic       dbg_mon_frame_err;

endinterface : uart_if
