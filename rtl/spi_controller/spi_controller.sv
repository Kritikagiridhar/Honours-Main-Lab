// =============================================================================
// Module      : spi_controller.sv
// Description : Autonomous AXI4-Lite SPI Master Controller for ADC Acquisition
// Specification: 
//   - Memory-Mapped at 0x4000_C000 (Aperture 4 KB)
//   - Registers:
//       0x00: SPI_CTRL    [0] EN, [1] AUTO_TRIGGER (sample_tick), [7:4] PRESCALER
//       0x04: SPI_STATUS  [0] BUSY, [1] RX_VALID (W1C), [2] TX_EMPTY
//       0x08: SPI_TXDATA  [15:0] Command / Configuration Word to SPI Slave
//       0x0C: SPI_RXDATA  [15:0] 16-bit Sample Received from ADC (RO)
//       0x10: SPI_CS      [0] Manual CS control (0 = Asserted, 1 = Deasserted)
//   - Physical Interface:
//       adc_spi_sck, adc_spi_mosi, adc_spi_miso, adc_spi_cs_n
//   - Autonomous Mode:
//       When AUTO_TRIGGER=1, automatically sequences an SPI 16-bit transfer
//       on each sample_tick pulse from the Timer without CPU intervention.
// =============================================================================

`resetall
`timescale 1ns / 1ps
`default_nettype none

module spi_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Hardware Autonomous Trigger from Timer
    input  wire                  sample_tick,

    // Physical SPI External Pins to ADC
    output reg                   adc_spi_sck,
    output reg                   adc_spi_mosi,
    input  wire                  adc_spi_miso,
    output reg                   adc_spi_cs_n,

    // Direct Sample Valid Strobe to DMA
    output reg                   sample_ready,
    output wire [15:0]           sample_data,

    // AXI4-Lite Slave CSR Interface
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // Interrupt Line
    output wire                  irq_spi
);

    // -------------------------------------------------------------------------
    // Control / Status Registers & Internal 32-Entry RX FIFO
    // -------------------------------------------------------------------------
    reg        reg_spi_en;
    reg        reg_auto_trigger;
    reg [3:0]  reg_prescaler;
    reg [15:0] reg_txdata;
    reg [15:0] reg_rxdata;
    reg        reg_manual_cs;
    reg        reg_rx_valid;
    reg        reg_busy;

    // Synchronous 32-entry RX FIFO
    localparam FIFO_DEPTH = 32;
    localparam FIFO_ADDR_W = 5;
    reg [15:0] rx_fifo_mem [0:FIFO_DEPTH-1];
    reg [FIFO_ADDR_W:0] fifo_wr_ptr;
    reg [FIFO_ADDR_W:0] fifo_rd_ptr;
    wire [FIFO_ADDR_W:0] fifo_count = fifo_wr_ptr - fifo_rd_ptr;
    wire fifo_empty = (fifo_wr_ptr == fifo_rd_ptr);
    wire fifo_full  = (fifo_count == FIFO_DEPTH);

    assign sample_data = reg_rxdata;
    assign irq_spi     = reg_rx_valid || !fifo_empty;

    // -------------------------------------------------------------------------
    // SPI Master State Machine (Mode 0: CPOL=0, CPHA=0)
    // -------------------------------------------------------------------------
    localparam STATE_IDLE      = 2'd0;
    localparam STATE_LEAD      = 2'd1;
    localparam STATE_TRANSFER  = 2'd2;
    localparam STATE_TRAIL     = 2'd3;

    reg [ADDR_WIDTH-1:0] araddr_latched;
    reg                  fifo_flush_req;

    reg [1:0]  spi_state;
    reg [7:0]  clk_div_cnt;
    reg [4:0]  bit_cnt;
    reg [15:0] tx_shift_reg;
    reg [15:0] rx_shift_reg;
    reg        sck_phase;

    wire [7:0] baud_div = {4'd0, reg_prescaler == 4'd0 ? 4'd2 : reg_prescaler};

    // Trigger condition
    wire start_transfer = reg_spi_en && ((sample_tick && reg_auto_trigger) || (!reg_auto_trigger && reg_busy && spi_state == STATE_IDLE));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_state       <= STATE_IDLE;
            adc_spi_sck     <= 1'b0;
            adc_spi_mosi    <= 1'b0;
            adc_spi_cs_n    <= 1'b1;
            clk_div_cnt     <= 8'd0;
            bit_cnt         <= 5'd0;
            tx_shift_reg    <= 16'd0;
            rx_shift_reg    <= 16'd0;
            sck_phase       <= 1'b0;
            reg_busy        <= 1'b0;
            reg_rxdata      <= 16'd0;
            reg_rx_valid     <= 1'b0;
            sample_ready    <= 1'b0;
        end else begin
            sample_ready <= 1'b0;

            case (spi_state)
                STATE_IDLE: begin
                    adc_spi_sck  <= 1'b0;
                    adc_spi_cs_n <= reg_manual_cs;
                    clk_div_cnt  <= 8'd0;
                    sck_phase    <= 1'b0;

                    if (reg_spi_en && (sample_tick && reg_auto_trigger)) begin
                        reg_busy     <= 1'b1;
                        adc_spi_cs_n <= 1'b0;
                        tx_shift_reg <= reg_txdata;
                        bit_cnt      <= 5'd16;
                        spi_state    <= STATE_LEAD;
                    end
                end

                STATE_LEAD: begin
                    // Setup time before first SCK rising edge
                    if (clk_div_cnt >= baud_div) begin
                        clk_div_cnt  <= 8'd0;
                        adc_spi_mosi <= tx_shift_reg[15];
                        spi_state    <= STATE_TRANSFER;
                    end else begin
                        clk_div_cnt <= clk_div_cnt + 1'b1;
                    end
                end

                STATE_TRANSFER: begin
                    if (clk_div_cnt >= baud_div) begin
                        clk_div_cnt <= 8'd0;
                        sck_phase   <= ~sck_phase;

                        if (!sck_phase) begin
                            // Rising edge: sample MISO
                            adc_spi_sck  <= 1'b1;
                            rx_shift_reg <= {rx_shift_reg[14:0], adc_spi_miso};
                        end else begin
                            // Falling edge: shift next MOSI
                            adc_spi_sck  <= 1'b0;
                            tx_shift_reg <= {tx_shift_reg[14:0], 1'b0};
                            bit_cnt      <= bit_cnt - 1'b1;

                            if (bit_cnt == 5'd1) begin
                                spi_state <= STATE_TRAIL;
                            end else begin
                                adc_spi_mosi <= tx_shift_reg[14];
                            end
                        end
                    end else begin
                        clk_div_cnt <= clk_div_cnt + 1'b1;
                    end
                end

                STATE_TRAIL: begin
                    if (clk_div_cnt >= baud_div) begin
                        clk_div_cnt  <= 8'd0;
                        adc_spi_cs_n <= 1'b1;
                        reg_rxdata   <= rx_shift_reg;
                        reg_rx_valid <= 1'b1;
                        sample_ready <= 1'b1;
                        reg_busy     <= 1'b0;
                        spi_state    <= STATE_IDLE;

                        // Push incoming ADC sample to internal FIFO
                        if (!fifo_full) begin
                            rx_fifo_mem[fifo_wr_ptr[FIFO_ADDR_W-1:0]] <= rx_shift_reg;
                            fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                        end
                    end else begin
                        clk_div_cnt <= clk_div_cnt + 1'b1;
                    end
                end
            endcase

            // Clear rx_valid on register read or write-1-to-clear
            if (s_axi_arvalid && s_axi_arready && (s_axi_araddr[7:0] == 8'h0C)) begin
                reg_rx_valid <= 1'b0;
            end

            // Pop FIFO on successful AXI read handshake from 0x0C
            if (s_axi_rvalid && s_axi_rready && (araddr_latched[7:0] == 8'h0C) && !fifo_empty) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
            end

            // Handle FIFO flush command
            if (fifo_flush_req) begin
                fifo_wr_ptr <= { (FIFO_ADDR_W+1){1'b0} };
                fifo_rd_ptr <= { (FIFO_ADDR_W+1){1'b0} };
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite CSR Read / Write Engine
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready    <= 1'b0;
            s_axi_wready     <= 1'b0;
            s_axi_bvalid     <= 1'b0;
            s_axi_bresp      <= 2'b00;
            aw_done          <= 1'b0;
            w_done           <= 1'b0;
            awaddr_latched   <= {ADDR_WIDTH{1'b0}};
            reg_spi_en       <= 1'b1; // Default enabled
            reg_auto_trigger <= 1'b1; // Default auto-sample on sample_tick
            reg_prescaler    <= 4'd2; // 100MHz / 4 = 25MHz SCK
            reg_txdata       <= 16'd0;
            reg_manual_cs    <= 1'b1;
            fifo_flush_req   <= 1'b0;
        end else begin
            fifo_flush_req <= 1'b0;

            // Address handshake
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            // Data handshake
            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Register write execution
            if (aw_done && w_done && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;

                case (awaddr_latched[7:0])
                    8'h00: begin // SPI_CTRL
                        reg_spi_en       <= s_axi_wdata[0];
                        reg_auto_trigger <= s_axi_wdata[1];
                        if (|s_axi_wdata[7:4]) reg_prescaler <= s_axi_wdata[7:4];
                    end
                    8'h08: begin // SPI_TXDATA
                        reg_txdata <= s_axi_wdata[15:0];
                    end
                    8'h10: begin // SPI_CS
                        reg_manual_cs <= s_axi_wdata[0];
                    end
                    8'h18: begin // SPI_FIFO_CTRL
                        if (s_axi_wdata[0]) fifo_flush_req <= 1'b1;
                    end
                    default: ;
                endcase
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_done      <= 1'b0;
                w_done       <= 1'b0;
            end
        end
    end

    // Read Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rdata    <= {DATA_WIDTH{1'b0}};
            s_axi_rresp    <= 2'b00;
            araddr_latched <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready  <= 1'b1;
                s_axi_rvalid   <= 1'b1;
                s_axi_rresp    <= 2'b00;
                araddr_latched <= s_axi_araddr;

                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= {24'd0, reg_prescaler, 2'd0, reg_auto_trigger, reg_spi_en};
                    8'h04: s_axi_rdata <= {27'd0, fifo_full, !fifo_empty, 1'b1, reg_rx_valid, reg_busy};
                    8'h08: s_axi_rdata <= {16'd0, reg_txdata};
                    8'h0C: s_axi_rdata <= {16'd0, fifo_empty ? reg_rxdata : rx_fifo_mem[fifo_rd_ptr[FIFO_ADDR_W-1:0]]};
                    8'h10: s_axi_rdata <= {31'd0, reg_manual_cs};
                    8'h14: s_axi_rdata <= {24'd0, 2'b00, fifo_count};
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule

`resetall
