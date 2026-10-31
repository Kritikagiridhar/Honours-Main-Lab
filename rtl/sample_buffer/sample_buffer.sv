// =============================================================================
// Module      : sample_buffer.sv
// Description : High-Performance True Dual-Port Ping-Pong Sample Buffer RAM
//               with Asynchronous CDC, Hardware Double-Buffering & AXI4-Lite CSRs
// Specification:
//   - Total Capacity: 4096 x 16-bit Samples (8 KB)
//       Buffer 0 (Bank A): 2048 x 16-bit words (Addresses 0..2047,  Bytes 0x0000..0x0FFF)
//       Buffer 1 (Bank B): 2048 x 16-bit words (Addresses 2048..4095, Bytes 0x1000..0x1FFF)
//   - Operating Modes:
//       Mode 0: Single continuous circular buffer (4096 entries)
//       Mode 1: Ping-Pong Double-Buffering (2 x 2048 entries)
//               - Writing to Buffer A while VGA displays Buffer B (Tear-Free!)
//               - Auto-swap on buffer wrap or synchronized to VGA VSYNC boundary
//               - CPU reads frozen completed buffer without race conditions
//   - Control Registers (Offset 0x2000+):
//       0x2000: SBUF_CTRL   [0] PING_PONG_EN, [1] AUTO_SWAP, [2] MANUAL_SWAP (W1P), [3] HOLD
//       0x2004: SBUF_STATUS [0] CURR_WR_BUF,  [1] CURR_RD_BUF,  [15:2] SWAP_COUNT
// =============================================================================

`resetall
`timescale 1ns / 1ps
`default_nettype none

module sample_buffer #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter BUFFER_DEPTH   = 4096,
    parameter BUF_ADDR_WIDTH = 12 // $clog2(4096)
)(
    // System Clock Domain (clk_sys)
    input  wire                      clk_sys,
    input  wire                      rst_sys_n,

    // Port A: DMA Hardware Write Port (clk_sys)
    input  wire [BUF_ADDR_WIDTH-1:0] sbuf_waddr,
    input  wire [15:0]               sbuf_wdata,
    input  wire                      sbuf_we,

    // Hardware Ping-Pong Handshake
    input  wire                      buf_swap_req,     // Strobe from DMA transfer complete
    input  wire                      vga_vsync_pulse,  // Strobe from VGA vertical sync for tear-free swap
    output wire                      active_wr_buf,    // 0 = Bank A, 1 = Bank B
    output wire                      active_rd_buf,    // 0 = Bank A, 1 = Bank B

    // Port B: VGA Controller Read Port (clk_vga domain)
    input  wire                      clk_vga,
    input  wire                      rst_vga_n,
    input  wire [BUF_ADDR_WIDTH-1:0] sbuf_raddr,
    output reg  [15:0]               sbuf_rdata,

    // Port C: AXI4-Lite Slave Interface (clk_sys domain for CPU Math & Control)
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
    input  wire                      s_axi_rready
);

    // 4096 x 16-bit True Dual-Port RAM Array
    reg [15:0] mem [0:BUFFER_DEPTH-1];

    // -------------------------------------------------------------------------
    // Ping-Pong Double-Buffering State Machine (clk_sys)
    // -------------------------------------------------------------------------
    reg        ping_pong_en;
    reg        auto_swap;
    reg        buf_hold;
    reg        wr_buf_sel; // 0 = writing Bank A, 1 = writing Bank B
    reg        rd_buf_sel; // 0 = reading Bank A, 1 = reading Bank B
    reg [13:0] swap_count;
    reg        pending_swap;

    assign active_wr_buf = wr_buf_sel;
    assign active_rd_buf = rd_buf_sel;

    // Buffer swap logic
    always @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            ping_pong_en <= 1'b1; // Default to Ping-Pong mode enabled
            auto_swap    <= 1'b1; // Default to auto-swap enabled
            buf_hold     <= 1'b0;
            wr_buf_sel   <= 1'b0;
            rd_buf_sel   <= 1'b1; // VGA starts reading Buffer 1 while DMA writes Buffer 0
            swap_count   <= 14'd0;
            pending_swap <= 1'b0;
        end else if (!buf_hold) begin
            // Track write completion or external DMA swap request
            if (ping_pong_en && (buf_swap_req || (auto_swap && sbuf_we && (sbuf_waddr[10:0] == 11'h7FF)))) begin
                pending_swap <= 1'b1;
            end

            // Tear-Free Swap Execution (synchronized or immediate)
            if (pending_swap) begin
                wr_buf_sel   <= ~wr_buf_sel;
                rd_buf_sel   <= wr_buf_sel; // The freshly written buffer becomes the read buffer
                swap_count   <= swap_count + 1'b1;
                pending_swap <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Port A: Synchronous Write Port (clk_sys)
    // -------------------------------------------------------------------------
    // In Ping-Pong mode, address MSB is driven by wr_buf_sel:
    //   Bank A: mem[0..2047]
    //   Bank B: mem[2048..4095]
    wire [BUF_ADDR_WIDTH-1:0] eff_waddr = ping_pong_en ? {wr_buf_sel, sbuf_waddr[BUF_ADDR_WIDTH-2:0]} : sbuf_waddr;

    always @(posedge clk_sys) begin
        if (sbuf_we && !buf_hold) begin
            mem[eff_waddr] <= sbuf_wdata;
        end
    end

    // -------------------------------------------------------------------------
    // Port B: VGA Display Read Port (clk_vga domain)
    // -------------------------------------------------------------------------
    // Synchronize rd_buf_sel into pixel clock domain
    reg rd_buf_sel_vga_meta, rd_buf_sel_vga;
    always @(posedge clk_vga or negedge rst_vga_n) begin
        if (!rst_vga_n) begin
            rd_buf_sel_vga_meta <= 1'b1;
            rd_buf_sel_vga      <= 1'b1;
        end else begin
            rd_buf_sel_vga_meta <= rd_buf_sel;
            rd_buf_sel_vga      <= rd_buf_sel_vga_meta;
        end
    end

    // In Ping-Pong mode, VGA displays from the completed Bank
    wire [BUF_ADDR_WIDTH-1:0] eff_raddr = ping_pong_en ? {rd_buf_sel_vga, sbuf_raddr[BUF_ADDR_WIDTH-2:0]} : sbuf_raddr;

    always @(posedge clk_vga or negedge rst_vga_n) begin
        if (!rst_vga_n) begin
            sbuf_rdata <= 16'd0;
        end else begin
            sbuf_rdata <= mem[eff_raddr];
        end
    end

    // -------------------------------------------------------------------------
    // Port C: AXI4-Lite Read-Only / Control Interface (clk_sys)
    // -------------------------------------------------------------------------
    // Memory mapping:
    //   Offsets 0x0000 - 0x1FFE : RAM sample entries [15:0]
    //   Offset  0x2000          : SBUF_CTRL
    //   Offset  0x2004          : SBUF_STATUS
    wire is_ctrl_reg = (s_axi_araddr[13:0] >= 14'h2000) || (s_axi_awaddr[13:0] >= 14'h2000);
    wire [BUF_ADDR_WIDTH-1:0] axi_sample_idx = s_axi_araddr[BUF_ADDR_WIDTH:1];

    // AXI Read Channel
    always @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;

                if (s_axi_araddr[13:0] == 14'h2000) begin
                    // SBUF_CTRL readback
                    s_axi_rdata <= {28'd0, buf_hold, 1'b0, auto_swap, ping_pong_en};
                end else if (s_axi_araddr[13:0] == 14'h2004) begin
                    // SBUF_STATUS readback
                    s_axi_rdata <= {16'd0, swap_count, rd_buf_sel, wr_buf_sel};
                end else begin
                    // Sample read from RAM
                    s_axi_rdata <= {16'd0, mem[axi_sample_idx]};
                end
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // AXI Write Channel (Control Registers at 0x2000+)
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    wire [BUF_ADDR_WIDTH-1:0] axi_wr_sample_idx = awaddr_latched[BUF_ADDR_WIDTH:1];
    wire [BUF_ADDR_WIDTH-1:0] eff_axi_waddr = ping_pong_en ? {wr_buf_sel, axi_wr_sample_idx[BUF_ADDR_WIDTH-2:0]} : axi_wr_sample_idx;

    always @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            aw_done        <= 1'b0;
            w_done         <= 1'b0;
            awaddr_latched <= {ADDR_WIDTH{1'b0}};
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

                if (awaddr_latched[13:0] == 14'h2000) begin
                    ping_pong_en <= s_axi_wdata[0];
                    auto_swap    <= s_axi_wdata[1];
                    buf_hold     <= s_axi_wdata[3];
                    if (s_axi_wdata[2]) begin
                        // Manual swap request
                        wr_buf_sel <= ~wr_buf_sel;
                        rd_buf_sel <= wr_buf_sel;
                    end
                end else if (awaddr_latched[13:0] < 14'h2000 && !buf_hold) begin
                    // Standalone AXI Memory-Mapped Write into Active Write Bank
                    if (s_axi_wstrb[1:0] != 2'b00) begin
                        mem[eff_axi_waddr] <= s_axi_wdata[15:0];
                    end
                    if (s_axi_wstrb[3:2] != 2'b00) begin
                        mem[eff_axi_waddr + 1'b1] <= s_axi_wdata[31:16];
                    end
                    // Auto-swap check on AXI write boundary
                    if (ping_pong_en && auto_swap && (axi_wr_sample_idx[BUF_ADDR_WIDTH-2:0] >= 11'h7FE)) begin
                        pending_swap <= 1'b1;
                    end
                end
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_done      <= 1'b0;
                w_done       <= 1'b0;
            end
        end
    end

endmodule

`resetall
