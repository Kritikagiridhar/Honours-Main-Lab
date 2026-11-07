// uart_tx_seq.sv
// Sequence that generates and transmits N bytes through the UART VIP driver.

class uart_tx_seq extends uvm_sequence #(uart_seq_item);
  `uvm_object_utils(uart_tx_seq)

  int unsigned n_trans = 5;

  function new(string name = "uart_tx_seq");
    super.new(name);
  endfunction

  task body();
    uart_seq_item item;

    `uvm_info(get_type_name(),
      $sformatf("Starting UART TX sequence: sending %0d transactions", n_trans), UVM_LOW)

    for (int i = 0; i < n_trans; i++) begin
      item = uart_seq_item::type_id::create($sformatf("tx_item_%0d", i));
      start_item(item);
      if (!item.randomize()) begin
        item.data = 8'h41 + (i % 26);
      end
      item.op = uart_seq_item::UART_TX;
      finish_item(item);

      `uvm_info(get_type_name(),
        $sformatf("Sent byte [%0d/%0d]: 8'h%02h ('%c')",
                  i + 1, n_trans, item.data,
                  ((item.data >= 32 && item.data <= 126) ? item.data : 8'h2E)), UVM_LOW)
    end
  endtask

endclass : uart_tx_seq
