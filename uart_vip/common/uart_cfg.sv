// uart_cfg.sv
// Configuration for UART VIP agent.
// Set clocks_per_bit to control baud rate.
// Virtual interface is set from tb_top.

class uart_cfg extends uvm_object;
  `uvm_object_utils(uart_cfg)

  virtual uart_if vif;

  uart_agent_mode_e mode = UART_ACTIVE;

  // Timing:
  // clocks_per_bit = system_clock_freq / baud_rate
  // For fast simulation -> 16 cycles per bit
  // For 100MHz clock and 115200 baud -> 868 cycles
  int unsigned clocks_per_bit = 16;
  int unsigned baud_rate      = 115200;

  // Frame Format: 8-N-1 (8 data bits, no parity, 1 stop bit)
  int unsigned data_bits = 8;
  int unsigned stop_bits = 1;
  bit          parity_en = 0;

  function new(string name = "uart_cfg");
    super.new(name);
  endfunction

endclass : uart_cfg
