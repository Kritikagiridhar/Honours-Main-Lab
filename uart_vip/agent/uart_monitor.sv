// uart_monitor.sv
// UART Monitor component.
// Watches vif.uart_tx, detects start bit, samples serial bitstream at bit center,
// reconstructs bytes, checks framing, and broadcasts via analysis port.

class uart_monitor extends uvm_component;
  `uvm_component_utils(uart_monitor)

  uart_cfg        cfg;
  virtual uart_if vif;
  uvm_analysis_port #(uart_seq_item) ap;

  function new(string name = "uart_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(uart_cfg)::get(this, "", "cfg", cfg)) begin
      if (!uvm_config_db #(virtual uart_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "Neither uart_cfg nor virtual uart_if found in uvm_config_db")
      end
      cfg = uart_cfg::type_id::create("cfg");
      cfg.vif = vif;
    end else begin
      vif = cfg.vif;
    end

    if (vif == null)
      `uvm_fatal(get_type_name(), "virtual interface handle vif is null")
  endfunction

  // -- Timing helpers -----------------------------------------
  task automatic wait_half_bit();
    repeat (cfg.clocks_per_bit / 2) @(posedge vif.clk);
  endtask

  task automatic wait_full_bit();
    repeat (cfg.clocks_per_bit) @(posedge vif.clk);
  endtask

  // -- Capture Byte Frame -------------------------------------
  task receive_byte(output logic [7:0] byte_val, output bit frame_err);
    frame_err = 0;
    byte_val  = 8'h00;

    // 1. Wait for falling edge of start bit
    while (vif.uart_tx !== 1'b0) @(posedge vif.clk);

    // 2. Wait to center of start bit
    wait_half_bit();
    if (vif.uart_tx !== 1'b0) begin
      // False start / glitch
      return;
    end

    // 3. Sample 8 data bits (LSB first) at bit center
    for (int i = 0; i < 8; i++) begin
      wait_full_bit();
      byte_val[i] = vif.uart_tx;
    end

    // 4. Parity bit if enabled
    if (cfg.parity_en) begin
      wait_full_bit();
      // Parity check could be performed here
    end

    // 5. Sample Stop bit (must be HIGH)
    wait_full_bit();
    if (vif.uart_tx !== 1'b1) begin
      frame_err = 1'b1;
    end

    // 6. Complete stop bit
    wait_half_bit();
  endtask

  // -- Run Phase ----------------------------------------------
  task run_phase(uvm_phase phase);
    uart_seq_item item;
    logic [7:0]   captured_byte;
    bit           err;

    vif.dbg_mon_data      <= 8'h00;
    vif.dbg_mon_valid     <= 1'b0;
    vif.dbg_mon_frame_err <= 1'b0;

    wait (vif.rst_n === 1'b1);
    repeat (cfg.clocks_per_bit) @(posedge vif.clk);

    forever begin
      receive_byte(captured_byte, err);

      // Create item and publish
      item           = uart_seq_item::type_id::create("mon_item");
      item.op        = uart_seq_item::UART_RX;
      item.data      = captured_byte;
      item.frame_err = err;

      // Update debug probes
      vif.dbg_mon_data      <= captured_byte;
      vif.dbg_mon_valid     <= 1'b1;
      vif.dbg_mon_frame_err <= err;
      @(posedge vif.clk);
      vif.dbg_mon_valid     <= 1'b0;

      `uvm_info(get_type_name(),
        $sformatf("Monitor sampled byte: %s", item.convert2string()), UVM_MEDIUM)

      ap.write(item);
    end
  endtask

endclass : uart_monitor
