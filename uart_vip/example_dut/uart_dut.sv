// uart_dut.sv
// Simple UART Loopback / Echo DUT with Interrupt generation.
//
// Receives serial byte on 'rx', asserts 'irq', and echoes the byte back out on 'tx'.
// Supports parameterized CLOCKS_PER_BIT for baud rate matching.

`timescale 1ns/1ps

module uart_dut #(
  parameter int CLOCKS_PER_BIT = 16
)(
  input  logic clk,
  input  logic rst_n,
  input  logic rx,
  output logic tx,
  output logic irq
);

  // ----------------------------------------------------------
  // RX Engine
  // ----------------------------------------------------------
  typedef enum logic [1:0] {
    RX_IDLE  = 2'd0,
    RX_START = 2'd1,
    RX_DATA  = 2'd2,
    RX_STOP  = 2'd3
  } rx_state_e;

  rx_state_e rx_state;
  logic [15:0] rx_clk_cnt;
  logic [2:0]  rx_bit_idx;
  logic [7:0]  rx_byte;
  logic        rx_done;

  // Double flop for CDC / metastability
  logic rx_sync_0, rx_sync_1;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_sync_0 <= 1'b1;
      rx_sync_1 <= 1'b1;
    end else begin
      rx_sync_0 <= rx;
      rx_sync_1 <= rx_sync_0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state   <= RX_IDLE;
      rx_clk_cnt <= '0;
      rx_bit_idx <= '0;
      rx_byte    <= '0;
      rx_done    <= 1'b0;
    end else begin
      rx_done <= 1'b0;
      case (rx_state)
        RX_IDLE: begin
          if (rx_sync_1 == 1'b0) begin
            rx_clk_cnt <= '0;
            rx_state   <= RX_START;
          end
        end

        RX_START: begin
          if (rx_clk_cnt == (CLOCKS_PER_BIT / 2) - 1) begin
            if (rx_sync_1 == 1'b0) begin
              rx_clk_cnt <= '0;
              rx_bit_idx <= '0;
              rx_state   <= RX_DATA;
            end else begin
              rx_state   <= RX_IDLE;
            end
          end else begin
            rx_clk_cnt <= rx_clk_cnt + 1;
          end
        end

        RX_DATA: begin
          if (rx_clk_cnt == CLOCKS_PER_BIT - 1) begin
            rx_clk_cnt            <= '0;
            rx_byte[rx_bit_idx]   <= rx_sync_1;
            if (rx_bit_idx == 3'd7) begin
              rx_state <= RX_STOP;
            end else begin
              rx_bit_idx <= rx_bit_idx + 1;
            end
          end else begin
            rx_clk_cnt <= rx_clk_cnt + 1;
          end
        end

        RX_STOP: begin
          if (rx_clk_cnt == CLOCKS_PER_BIT - 1) begin
            rx_state <= RX_IDLE;
            if (rx_sync_1 == 1'b1) begin
              rx_done <= 1'b1;
            end
          end else begin
            rx_clk_cnt <= rx_clk_cnt + 1;
          end
        end
      endcase
    end
  end

  // ----------------------------------------------------------
  // FIFO / Buffer
  // ----------------------------------------------------------
  logic [7:0] fifo_mem [16];
  logic [3:0] fifo_wr_ptr;
  logic [3:0] fifo_rd_ptr;
  logic [4:0] fifo_count;

  wire fifo_empty = (fifo_count == 0);
  wire fifo_full  = (fifo_count == 16);

  // ----------------------------------------------------------
  // TX Engine
  // ----------------------------------------------------------
  typedef enum logic [1:0] {
    TX_IDLE  = 2'd0,
    TX_START = 2'd1,
    TX_DATA  = 2'd2,
    TX_STOP  = 2'd3
  } tx_state_e;

  tx_state_e tx_state;
  logic [15:0] tx_clk_cnt;
  logic [2:0]  tx_bit_idx;
  logic [7:0]  tx_byte;

  wire tx_busy = (tx_state != TX_IDLE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_wr_ptr <= '0;
      fifo_rd_ptr <= '0;
      fifo_count  <= '0;
      irq         <= 1'b0;
    end else begin
      irq <= 1'b0;
      // Push received byte
      if (rx_done && !fifo_full) begin
        fifo_mem[fifo_wr_ptr] <= rx_byte;
        fifo_wr_ptr           <= fifo_wr_ptr + 1;
        fifo_count            <= fifo_count + 1;
        irq                   <= 1'b1;
      end

      // Pop when TX starts
      if (tx_state == TX_IDLE && !fifo_empty) begin
        fifo_rd_ptr <= fifo_rd_ptr + 1;
        fifo_count  <= fifo_count - 1;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state   <= TX_IDLE;
      tx_clk_cnt <= '0;
      tx_bit_idx <= '0;
      tx_byte    <= '0;
      tx         <= 1'b1;
    end else begin
      case (tx_state)
        TX_IDLE: begin
          tx <= 1'b1;
          if (!fifo_empty) begin
            tx_byte    <= fifo_mem[fifo_rd_ptr];
            tx_clk_cnt <= '0;
            tx_state   <= TX_START;
          end
        end

        TX_START: begin
          tx <= 1'b0; // Start bit
          if (tx_clk_cnt == CLOCKS_PER_BIT - 1) begin
            tx_clk_cnt <= '0;
            tx_bit_idx <= '0;
            tx_state   <= TX_DATA;
          end else begin
            tx_clk_cnt <= tx_clk_cnt + 1;
          end
        end

        TX_DATA: begin
          tx <= tx_byte[tx_bit_idx];
          if (tx_clk_cnt == CLOCKS_PER_BIT - 1) begin
            tx_clk_cnt <= '0;
            if (tx_bit_idx == 3'd7) begin
              tx_state <= TX_STOP;
            end else begin
              tx_bit_idx <= tx_bit_idx + 1;
            end
          end else begin
            tx_clk_cnt <= tx_clk_cnt + 1;
          end
        end

        TX_STOP: begin
          tx <= 1'b1; // Stop bit
          if (tx_clk_cnt == CLOCKS_PER_BIT - 1) begin
            tx_clk_cnt <= '0;
            tx_state   <= TX_IDLE;
          end else begin
            tx_clk_cnt <= tx_clk_cnt + 1;
          end
        end
      endcase
    end
  end

endmodule : uart_dut
