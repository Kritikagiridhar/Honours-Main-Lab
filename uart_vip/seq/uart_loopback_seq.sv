// uart_loopback_seq.sv
// Sequence that sends deterministic byte patterns for loopback verification.

class uart_loopback_seq extends uvm_sequence #(uart_seq_item);
  `uvm_object_utils(uart_loopback_seq)

  logic [7:0] test_bytes[$] = '{8'hA5, 8'h5A, 8'h33, 8'hCC, 8'hF0};

  function new(string name = "uart_loopback_seq");
    super.new(name);
  endfunction

  task body();
    uart_seq_item item;

    `uvm_info(get_type_name(),
      $sformatf("Starting UART loopback sequence: %0d test patterns", test_bytes.size()), UVM_LOW)

    foreach (test_bytes[i]) begin
      item = uart_seq_item::type_id::create($sformatf("lb_item_%0d", i));
      start_item(item);
      item.op   = uart_seq_item::UART_TX;
      item.data = test_bytes[i];
      finish_item(item);

      `uvm_info(get_type_name(),
        $sformatf("Sent test pattern [%0d]: 8'h%02h", i + 1, item.data), UVM_LOW)
    end
  endtask

endclass : uart_loopback_seq
