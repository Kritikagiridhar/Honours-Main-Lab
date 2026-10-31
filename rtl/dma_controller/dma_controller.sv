// =============================================================================
// Module      : dma_controller.sv
// Description : Autonomous Signal Acquisition & Universal AXI4 Bus Master DMA Controller
// Specification: Architecture Document Section 8.6 & Decoupled Modular Streaming Spec
//   - AXI4 Master Interface (connected to Crossbar S03) for generic memory-to-memory,
//     peripheral-to-memory, and memory-to-peripheral autonomous data movement
//     (e.g., SPI FIFO -> RAM, RAM -> FIR, FIR -> SBUF, or SPI -> SBUF directly).
//   - AXI4-Lite Slave CSR Interface (0x4001_0000):
//       0x00: DMA_CTRL   [0] START, [1] ABORT, [2] AUTO_RELOAD, [3] SRC_INC,
//                        [4] DST_INC, [5] TRIGGER_EN, [6] DMA_MODE (0=AXI Master, 1=Legacy Streaming)
//       0x04: DMA_SRC_ADDR [31:0] Source base address
//       0x08: DMA_DST_ADDR [31:0] Destination base address
//       0x0C: DMA_LEN      [15:0] Number of transfers / words
//       0x10: DMA_TIMEOUT  [31:0] Watchdog timeout cycles
//       0x14: DMA_STATUS   [0] BUSY, [1] DONE (W1C), [2] OVF, [3] UNDERRUN, [4] TIMEOUT, [5] ERR
//       0x18: DMA_COUNT    [15:0] Current transferred word count
//   - Legacy streaming ports preserved for backwards compatibility with testbenches.
// =============================================================================

`resetall
`timescale 1ns / 1ps
`default_nettype none

module dma_controller #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter ID_WIDTH       = 8,
    parameter BUF_ADDR_WIDTH = 12
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // Timer Acquisition Strobe
    input  wire                      sample_tick,

    // Hardware Interface to SPI Controller
    input  wire                      spi_sample_ready,
    input  wire [15:0]               spi_sample_data,

    // Legacy / Direct SPI Pins (pass-through / fallback)
    output reg                       adc_spi_sck,
    output reg                       adc_spi_mosi,
    input  wire                      adc_spi_miso,
    output reg                       adc_spi_cs_n,

    // FIR Filter Streaming Interface
    output reg  signed [15:0]        fir_sample_in,
    output reg                       fir_sample_valid_in,
    input  wire signed [15:0]        fir_sample_out,
    input  wire                      fir_sample_valid_out,

    // Ping-Pong Sample Buffer Interface
    output reg  [BUF_ADDR_WIDTH-1:0] sbuf_waddr,
    output reg  [15:0]               sbuf_wdata,
    output reg                       sbuf_we,
    output reg                       buf_swap_req,

    // =========================================================================
    // AXI4 Master Interface (Initiates Read / Write Bus Transfers)
    // =========================================================================
    // Write Address Channel
    output reg  [ID_WIDTH-1:0]       m_axi_awid,
    output reg  [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output reg  [7:0]                m_axi_awlen,
    output reg  [2:0]                m_axi_awsize,
    output reg  [1:0]                m_axi_awburst,
    output reg                       m_axi_awlock,
    output reg  [3:0]                m_axi_awcache,
    output reg  [2:0]                m_axi_awprot,
    output reg  [3:0]                m_axi_awqos,
    output reg                       m_axi_awvalid,
    input  wire                      m_axi_awready,

    // Write Data Channel
    output reg  [DATA_WIDTH-1:0]     m_axi_wdata,
    output reg  [3:0]                m_axi_wstrb,
    output reg                       m_axi_wlast,
    output reg                       m_axi_wvalid,
    input  wire                      m_axi_wready,

    // Write Response Channel
    input  wire [ID_WIDTH-1:0]       m_axi_bid,
    input  wire [1:0]                m_axi_bresp,
    input  wire                      m_axi_bvalid,
    output reg                       m_axi_bready,

    // Read Address Channel
    output reg  [ID_WIDTH-1:0]       m_axi_arid,
    output reg  [ADDR_WIDTH-1:0]     m_axi_araddr,
    output reg  [7:0]                m_axi_arlen,
    output reg  [2:0]                m_axi_arsize,
    output reg  [1:0]                m_axi_arburst,
    output reg                       m_axi_arlock,
    output reg  [3:0]                m_axi_arcache,
    output reg  [2:0]                m_axi_arprot,
    output reg  [3:0]                m_axi_arqos,
    output reg                       m_axi_arvalid,
    input  wire                      m_axi_arready,

    // Read Data Channel
    input  wire [ID_WIDTH-1:0]       m_axi_rid,
    input  wire [DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                m_axi_rresp,
    input  wire                      m_axi_rlast,
    input  wire                      m_axi_rvalid,
    output reg                       m_axi_rready,

    // =========================================================================
    // AXI4-Lite Slave CSR Interface
    // =========================================================================
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [3:0]                s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    output reg  [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready,

    // Interrupt Outputs
    output wire                      irq_dma_done,
    output wire                      irq_dma_err
);

    // -------------------------------------------------------------------------
    // CSR Registers
    // -------------------------------------------------------------------------
    reg [31:0] dma_src_addr;
    reg [31:0] dma_dst_addr;
    reg [15:0] dma_len;
    reg [31:0] dma_timeout;

    reg        reg_auto_reload;
    reg        reg_src_inc;
    reg        reg_dst_inc;
    reg        reg_trigger_en;
    reg        reg_axi_master_en; // 0 = Legacy hardware streaming, 1 = AXI Master mode

    reg        dma_busy;
    reg        dma_done;
    reg        dma_ovf;
    reg        dma_underrun;
    reg        dma_timeout_flag;
    reg        dma_err;

    assign irq_dma_done = dma_done;
    assign irq_dma_err  = dma_ovf || dma_underrun || dma_timeout_flag || dma_err;

    // -------------------------------------------------------------------------
    // DMA FSM States
    // -------------------------------------------------------------------------
    localparam STATE_IDLE          = 4'd0;
    localparam STATE_WAIT_SAMP     = 4'd1;
    localparam STATE_TO_FIR        = 4'd2;
    localparam STATE_FROM_FIR      = 4'd3;
    localparam STATE_WRITE_BUF     = 4'd4;
    localparam STATE_COMPLETE      = 4'd5;
    localparam STATE_AXI_AR        = 4'd6;
    localparam STATE_AXI_R         = 4'd7;
    localparam STATE_AXI_AW_W      = 4'd8;
    localparam STATE_AXI_B         = 4'd9;
    localparam STATE_AXI_WAIT_TRIG = 4'd10;

    reg [3:0]  state;
    reg [15:0] samples_transferred;
    reg [31:0] timeout_counter;
    reg [15:0] captured_sample;

    reg [ADDR_WIDTH-1:0] curr_src_addr;
    reg [ADDR_WIDTH-1:0] curr_dst_addr;
    reg [DATA_WIDTH-1:0] data_buffer;
    reg                  aw_done_fsm;
    reg                  w_done_fsm;

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Handshake & Command Decode
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    wire write_req         = (aw_done && w_done && !s_axi_bvalid);
    wire start_req         = write_req && (awaddr_latched[7:0] == 8'h00) && s_axi_wdata[0];
    wire abort_req         = write_req && (awaddr_latched[7:0] == 8'h00) && s_axi_wdata[1];
    wire w1c_done_req      = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[1];
    wire w1c_ovf_req       = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[2];
    wire w1c_underrun_req  = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[3];
    wire w1c_timeout_req   = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[4];
    wire w1c_err_req       = write_req && (awaddr_latched[7:0] == 8'h14) && s_axi_wdata[5];

    wire effective_axi_master_en = (start_req) ? s_axi_wdata[7] : reg_axi_master_en;
    wire effective_trigger_en    = (start_req) ? s_axi_wdata[5] : reg_trigger_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state               <= STATE_IDLE;
            dma_busy            <= 1'b0;
            dma_done            <= 1'b0;
            dma_ovf             <= 1'b0;
            dma_underrun        <= 1'b0;
            dma_timeout_flag    <= 1'b0;
            dma_err             <= 1'b0;
            samples_transferred <= 16'd0;
            timeout_counter     <= 32'd0;
            captured_sample     <= 16'd0;

            adc_spi_sck         <= 1'b0;
            adc_spi_mosi        <= 1'b0;
            adc_spi_cs_n        <= 1'b1;

            fir_sample_in       <= 16'sd0;
            fir_sample_valid_in <= 1'b0;
            sbuf_waddr          <= {BUF_ADDR_WIDTH{1'b0}};
            sbuf_wdata          <= 16'd0;
            sbuf_we             <= 1'b0;
            buf_swap_req        <= 1'b0;

            // AXI Master Outputs Reset
            m_axi_awid          <= '0;
            m_axi_awaddr        <= '0;
            m_axi_awlen         <= 8'd0;
            m_axi_awsize        <= 3'b010; // 4 bytes = 32-bit
            m_axi_awburst       <= 2'b01;  // INCR
            m_axi_awlock        <= 1'b0;
            m_axi_awcache       <= 4'b0011;
            m_axi_awprot        <= 3'b000;
            m_axi_awqos         <= 4'd0;
            m_axi_awvalid       <= 1'b0;

            m_axi_wdata         <= '0;
            m_axi_wstrb         <= 4'b1111;
            m_axi_wlast         <= 1'b0;
            m_axi_wvalid        <= 1'b0;
            m_axi_bready        <= 1'b0;

            m_axi_arid          <= '0;
            m_axi_araddr        <= '0;
            m_axi_arlen         <= 8'd0;
            m_axi_arsize        <= 3'b010; // 32-bit
            m_axi_arburst       <= 2'b01;
            m_axi_arlock        <= 1'b0;
            m_axi_arcache       <= 4'b0011;
            m_axi_arprot        <= 3'b000;
            m_axi_arqos         <= 4'd0;
            m_axi_arvalid       <= 1'b0;
            m_axi_rready        <= 1'b0;

            curr_src_addr       <= '0;
            curr_dst_addr       <= '0;
            data_buffer         <= '0;
            aw_done_fsm         <= 1'b0;
            w_done_fsm          <= 1'b0;
        end else begin
            sbuf_we             <= 1'b0;
            fir_sample_valid_in <= 1'b0;
            buf_swap_req        <= 1'b0;

            // Handle W1C status clears from AXI
            if (w1c_done_req)     dma_done         <= 1'b0;
            if (w1c_ovf_req)      dma_ovf          <= 1'b0;
            if (w1c_underrun_req) dma_underrun     <= 1'b0;
            if (w1c_timeout_req)  dma_timeout_flag <= 1'b0;
            if (w1c_err_req)      dma_err          <= 1'b0;

            // Handle Start/Abort commands
            if (abort_req) begin
                dma_busy      <= 1'b0;
                m_axi_arvalid <= 1'b0;
                m_axi_rready  <= 1'b0;
                m_axi_awvalid <= 1'b0;
                m_axi_wvalid  <= 1'b0;
                m_axi_bready  <= 1'b0;
                state         <= STATE_IDLE;
            end else if (start_req) begin
                dma_busy            <= 1'b1;
                dma_done            <= 1'b0;
                samples_transferred <= 16'd0;
                curr_src_addr       <= dma_src_addr;
                curr_dst_addr       <= dma_dst_addr;
                sbuf_waddr          <= dma_dst_addr[BUF_ADDR_WIDTH-1:0];
                timeout_counter     <= 32'd0;

                if (!effective_axi_master_en) begin
                    // Hardware streaming mode (legacy pipeline)
                    state <= STATE_WAIT_SAMP;
                end else begin
                    // Universal AXI Master mode
                    if (effective_trigger_en) begin
                        state <= STATE_AXI_WAIT_TRIG;
                    end else begin
                        m_axi_araddr  <= dma_src_addr;
                        m_axi_arvalid <= 1'b1;
                        state         <= STATE_AXI_AR;
                    end
                end
            end else if (dma_busy) begin
                // Check transfer timeout
                if (timeout_counter >= dma_timeout) begin
                    dma_timeout_flag <= 1'b1;
                    dma_busy         <= 1'b0;
                    m_axi_arvalid    <= 1'b0;
                    m_axi_awvalid    <= 1'b0;
                    state            <= STATE_IDLE;
                end else begin
                    timeout_counter <= timeout_counter + 1'b1;
                end

                case (state)
                    // =========================================================
                    // Mode 0: Universal AXI Bus Master Transfer Engine
                    // =========================================================
                    STATE_AXI_WAIT_TRIG: begin
                        if (spi_sample_ready || sample_tick) begin
                            m_axi_araddr  <= curr_src_addr;
                            m_axi_arvalid <= 1'b1;
                            state         <= STATE_AXI_AR;
                        end
                    end

                    STATE_AXI_AR: begin
                        if (m_axi_arvalid && m_axi_arready) begin
                            m_axi_arvalid <= 1'b0;
                            m_axi_rready  <= 1'b1;
                            state         <= STATE_AXI_R;
                        end
                    end

                    STATE_AXI_R: begin
                        if (m_axi_rvalid && m_axi_rready) begin
                            m_axi_rready <= 1'b0;
                            data_buffer  <= m_axi_rdata;

                            if (reg_src_inc) curr_src_addr <= curr_src_addr + 4;

                            // Launch AXI Write transaction to destination
                            m_axi_awaddr  <= curr_dst_addr;
                            m_axi_awvalid <= 1'b1;
                            m_axi_wdata   <= m_axi_rdata;
                            m_axi_wstrb   <= 4'b1111;
                            m_axi_wlast   <= 1'b1;
                            m_axi_wvalid  <= 1'b1;
                            aw_done_fsm   <= 1'b0;
                            w_done_fsm    <= 1'b0;
                            state         <= STATE_AXI_AW_W;
                        end
                    end

                    STATE_AXI_AW_W: begin
                        if (m_axi_awvalid && m_axi_awready) begin
                            m_axi_awvalid <= 1'b0;
                            aw_done_fsm   <= 1'b1;
                        end
                        if (m_axi_wvalid && m_axi_wready) begin
                            m_axi_wvalid <= 1'b0;
                            w_done_fsm   <= 1'b1;
                        end

                        if ((aw_done_fsm || (m_axi_awvalid && m_axi_awready)) &&
                            (w_done_fsm  || (m_axi_wvalid && m_axi_wready))) begin
                            m_axi_bready <= 1'b1;
                            state        <= STATE_AXI_B;
                        end
                    end

                    STATE_AXI_B: begin
                        if (m_axi_bvalid && m_axi_bready) begin
                            m_axi_bready <= 1'b0;
                            if (m_axi_bresp != 2'b00) dma_err <= 1'b1;

                            if (reg_dst_inc) curr_dst_addr <= curr_dst_addr + 4;
                            samples_transferred <= samples_transferred + 1'b1;

                            if ((samples_transferred + 1'b1) >= dma_len) begin
                                dma_done     <= 1'b1;
                                buf_swap_req <= 1'b1; // Trigger buffer swap if dst was SBUF
                                if (reg_auto_reload) begin
                                    curr_src_addr       <= dma_src_addr;
                                    curr_dst_addr       <= dma_dst_addr;
                                    samples_transferred <= 16'd0;
                                    state               <= reg_trigger_en ? STATE_AXI_WAIT_TRIG : STATE_AXI_AR;
                                    if (!reg_trigger_en) begin
                                        m_axi_araddr  <= dma_src_addr;
                                        m_axi_arvalid <= 1'b1;
                                    end
                                end else begin
                                    dma_busy <= 1'b0;
                                    state    <= STATE_IDLE;
                                end
                            end else begin
                                if (reg_trigger_en) begin
                                    state <= STATE_AXI_WAIT_TRIG;
                                end else begin
                                    m_axi_araddr  <= curr_src_addr;
                                    m_axi_arvalid <= 1'b1;
                                    state         <= STATE_AXI_AR;
                                end
                            end
                        end
                    end

                    // =========================================================
                    // Mode 1: Legacy Streaming Pipeline Mode
                    // =========================================================
                    STATE_WAIT_SAMP: begin
                        if (spi_sample_ready || sample_tick) begin
                            captured_sample <= spi_sample_data;
                            state           <= STATE_TO_FIR;
                        end
                    end

                    STATE_TO_FIR: begin
                        fir_sample_in       <= $signed(captured_sample);
                        fir_sample_valid_in <= 1'b1;
                        state               <= STATE_FROM_FIR;
                    end

                    STATE_FROM_FIR: begin
                        if (fir_sample_valid_out) begin
                            sbuf_wdata <= fir_sample_out;
                            sbuf_we    <= 1'b1;
                            state      <= STATE_WRITE_BUF;
                        end
                    end

                    STATE_WRITE_BUF: begin
                        sbuf_waddr          <= sbuf_waddr + 1'b1;
                        samples_transferred <= samples_transferred + 1'b1;

                        if ((samples_transferred + 1'b1) >= dma_len) begin
                            state <= STATE_COMPLETE;
                        end else begin
                            state <= STATE_WAIT_SAMP;
                        end
                    end

                    STATE_COMPLETE: begin
                        dma_done     <= 1'b1;
                        dma_busy     <= 1'b0;
                        buf_swap_req <= 1'b1;
                        state        <= STATE_IDLE;
                    end

                    default: state <= STATE_IDLE;
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Handshake Registers (CSR Write & Read)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready   <= 1'b0;
            s_axi_wready    <= 1'b0;
            s_axi_bvalid    <= 1'b0;
            s_axi_bresp     <= 2'b00;
            aw_done         <= 1'b0;
            w_done          <= 1'b0;
            awaddr_latched  <= {ADDR_WIDTH{1'b0}};

            dma_src_addr    <= 32'h4000_C00C; // Default: SPI_RXDATA register
            dma_dst_addr    <= 32'h4001_6000; // Default: Sample Buffer base
            dma_len         <= 16'd2048;      // Default: Ping-Pong block length
            dma_timeout     <= 32'h000F_FFFF;
            reg_auto_reload <= 1'b0;
            reg_src_inc     <= 1'b0;          // Default fixed (FIFO)
            reg_dst_inc     <= 1'b1;          // Default incrementing (RAM/SBUF)
            reg_trigger_en    <= 1'b1;          // Default sample-rate triggered
            reg_axi_master_en <= 1'b0;          // Default hardware streaming mode
        end else begin
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            if (aw_done && w_done && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;

                case (awaddr_latched[7:0])
                    8'h00: begin // DMA_CTRL
                        reg_auto_reload   <= s_axi_wdata[2];
                        reg_src_inc       <= s_axi_wdata[3];
                        reg_dst_inc       <= s_axi_wdata[4];
                        reg_trigger_en    <= s_axi_wdata[5];
                        reg_axi_master_en <= s_axi_wdata[7];
                    end
                    8'h04: dma_src_addr <= s_axi_wdata;
                    8'h08: dma_dst_addr <= s_axi_wdata;
                    8'h0C: dma_len      <= s_axi_wdata[15:0];
                    8'h10: dma_timeout  <= s_axi_wdata;
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
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;

                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= {24'd0, reg_axi_master_en, 1'b0, reg_trigger_en, reg_dst_inc, reg_src_inc, reg_auto_reload, 1'b0, dma_busy};
                    8'h04: s_axi_rdata <= dma_src_addr;
                    8'h08: s_axi_rdata <= dma_dst_addr;
                    8'h0C: s_axi_rdata <= {16'd0, dma_len};
                    8'h10: s_axi_rdata <= dma_timeout;
                    8'h14: s_axi_rdata <= {26'd0, dma_err, dma_timeout_flag, dma_underrun, dma_ovf, dma_done, dma_busy};
                    8'h18: s_axi_rdata <= {16'd0, samples_transferred};
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
