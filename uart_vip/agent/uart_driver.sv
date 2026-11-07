// uart_driver.sv
// UART Driver component.
// Drives serial bitstream on vif.uart_rx synchronized to vif.clk.
// Implements standard 8-N-1 UART transmission.

class uart_driver extends uvm_driver #(uart_seq_item);
  `uvm_component_utils(uart_driver)

  uart_cfg        cfg;
  virtual uart_if vif;

  function new(string name = "uart_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve configuration object or virtual interface from uvm_config_db
    if (!uvm_config_db #(uart_cfg)::get(this, "", "cfg", cfg)) begin
      if (!uvm_config_db #(virtual uart_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "Neither uart_cfg nor virtual uart_if found in uvm_config_db")
      end
      // Default configuration if cfg object was not explicitly passed
      cfg = uart_cfg::type_id::create("cfg");
      cfg.vif = vif;
    end else begin
      vif = cfg.vif;
    end

    if (vif == null)
      `uvm_fatal(get_type_name(), "virtual interface handle vif is null")
  endfunction

  // -- Timing helper ------------------------------------------
  task automatic wait_bit_period();
    repeat (cfg.clocks_per_bit) @(posedge vif.clk);
  endtask

  // -- UART Byte Transmission (8-N-1) -------------------------
  task automatic send_byte(input logic [7:0] byte_val);
    // 1. Start bit (LOW)
    vif.uart_rx <= 1'b0;
    wait_bit_period();

    // 2. 8 Data bits (LSB first)
    for (int i = 0; i < 8; i++) begin
      vif.uart_rx <= byte_val[i];
      wait_bit_period();
    end

    // 3. Optional Parity bit
    if (cfg.parity_en) begin
      vif.uart_rx <= ^byte_val;
      wait_bit_period();
    end

    // 4. Stop bit (HIGH)
    for (int s = 0; s < cfg.stop_bits; s++) begin
      vif.uart_rx <= 1'b1;
      wait_bit_period();
    end
  endtask

  // -- Drive Transaction --------------------------------------
  task drive_item(uart_seq_item tr);
    vif.dbg_drv_data <= tr.data;
    vif.dbg_drv_busy <= 1'b1;
    vif.dbg_drv_done <= 1'b0;

    send_byte(tr.data);

    vif.dbg_drv_busy <= 1'b0;
    vif.dbg_drv_done <= 1'b1;
    @(posedge vif.clk);
    vif.dbg_drv_done <= 1'b0;

    `uvm_info(get_type_name(),
      $sformatf("Drive complete: %s", tr.convert2string()), UVM_MEDIUM)
  endtask

  // -- Run Phase ----------------------------------------------
  task run_phase(uvm_phase phase);
    uart_seq_item tr;

    // Reset default line states
    vif.uart_rx      <= 1'b1;  // UART idle is HIGH
    vif.dbg_drv_data <= 8'h00;
    vif.dbg_drv_busy <= 1'b0;
    vif.dbg_drv_done <= 1'b0;

    // Wait for reset release
    wait (vif.rst_n === 1'b1);
    repeat (cfg.clocks_per_bit * 2) @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(tr);
      drive_item(tr);
      seq_item_port.item_done();
    end
  endtask

endclass : uart_driver
