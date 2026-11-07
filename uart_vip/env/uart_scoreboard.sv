// uart_scoreboard.sv
// UART Scoreboard component following subscriber pattern.
// Connects to monitor analysis port via actual_export.
// Validates framing, data integrity, and reports verification summary.

class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

  uvm_analysis_imp #(uart_seq_item, uart_scoreboard) actual_export;

  // Expected bytes queue (optional ground truth)
  logic [7:0] exp_queue[$];

  int pass_cnt;
  int fail_cnt;
  int frame_err_cnt;
  int total_rx_cnt;

  function new(string name = "uart_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    actual_export = new("actual_export", this);
    pass_cnt      = 0;
    fail_cnt      = 0;
    frame_err_cnt = 0;
    total_rx_cnt  = 0;
  endfunction

  // Method to push expected byte from sequence/test
  function void add_expected(logic [7:0] exp_data);
    exp_queue.push_back(exp_data);
  endfunction

  // Analysis implementation write callback
  function void write(uart_seq_item tr);
    total_rx_cnt++;

    // Check framing error
    if (tr.frame_err) begin
      frame_err_cnt++;
      fail_cnt++;
      `uvm_error(get_type_name(),
        $sformatf("Framing error detected on transaction #%0d: %s",
                  total_rx_cnt, tr.convert2string()))
      return;
    end

    // If expected queue is populated, check match
    if (exp_queue.size() > 0) begin
      logic [7:0] exp = exp_queue.pop_front();
      if (tr.data === exp) begin
        pass_cnt++;
        `uvm_info(get_type_name(),
          $sformatf("MATCH [%0d] expected=8'h%02h got=8'h%02h",
                    pass_cnt, exp, tr.data), UVM_LOW)
      end else begin
        fail_cnt++;
        `uvm_error(get_type_name(),
          $sformatf("MISMATCH [%0d] expected=8'h%02h got=8'h%02h",
                    total_rx_cnt, exp, tr.data))
      end
    end else begin
      // Autonomous reception verification
      pass_cnt++;
      `uvm_info(get_type_name(),
        $sformatf("PASS [%0d] valid byte received: 8'h%02h ('%c')",
                  pass_cnt, tr.data,
                  ((tr.data >= 32 && tr.data <= 126) ? tr.data : 8'h2E)), UVM_LOW)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
      $sformatf({
        "\n=========================================\n",
        "         UART SCOREBOARD SUMMARY         \n",
        "=========================================\n",
        "  Total Received  : %0d\n",
        "  Matches / Passes: %0d\n",
        "  Fails           : %0d\n",
        "  Framing Errors  : %0d\n",
        "========================================="
      }, total_rx_cnt, pass_cnt, fail_cnt, frame_err_cnt), UVM_NONE)

    if (fail_cnt == 0 && total_rx_cnt > 0) begin
      `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_NONE)
    end else if (fail_cnt > 0) begin
      `uvm_error(get_type_name(), "*** TEST FAILED ***")
    end
  endfunction

endclass : uart_scoreboard
