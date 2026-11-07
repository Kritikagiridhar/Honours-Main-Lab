// uart_seq_item.sv
// One item = one UART transmission frame (byte transfer)
// Fields:
//   op: UART_TX, UART_RX, UART_LOOPBACK
//   data: byte to transmit or received byte
//   frame_err: indicates framing error (stop bit missing)
//   parity_err: indicates parity error

class uart_seq_item extends uvm_sequence_item;
  `uvm_object_utils(uart_seq_item)

  typedef enum logic [1:0] {
    UART_TX       = 2'd0,  // Transmit byte into DUT (via uart_rx)
    UART_RX       = 2'd1,  // Sample byte from DUT (via uart_tx)
    UART_LOOPBACK = 2'd2   // Transmit byte and expect echo back
  } uart_op_e;

  rand uart_op_e   op;
  rand logic [7:0] data;

  // Status / response fields
  logic [7:0] rdata;
  bit         frame_err;
  bit         parity_err;
  bit         match;

  function new(string name = "uart_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    case (op)
      UART_TX:
        return $sformatf("UART_TX  data=8'h%02h ('%c', 8'b%08b)",
                         data, ((data >= 32 && data <= 126) ? data : 8'h2E), data);
      UART_RX:
        return $sformatf("UART_RX  data=8'h%02h ('%c', 8'b%08b) frame_err=%0b",
                         data, ((data >= 32 && data <= 126) ? data : 8'h2E), data, frame_err);
      UART_LOOPBACK:
        return $sformatf("UART_LOOPBACK tx=8'h%02h rx=8'h%02h match=%0b frame_err=%0b",
                         data, rdata, (data == rdata), frame_err);
      default:
        return $sformatf("UART_ITEM data=8'h%02h", data);
    endcase
  endfunction

endclass : uart_seq_item
