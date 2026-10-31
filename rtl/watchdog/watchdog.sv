// =============================================================================
// Module      : watchdog.sv
// Description : Watchdog Safety Monitor with Heartbeat Taps & NMI Pre-Warning
// Specification: Architecture Document Section 8.8
//   - Registers:
//       0x00: WDT_CTRL   [0] EN
//       0x04: WDT_RELOAD [31:0] RELOAD
//       0x08: WDT_KICK   (Any write reloads counter)
//       0x0C: WDT_STATUS [0] PREWARN, [1] TRIPPED
//   - Inputs:
//       pipeline_alive [3:0]: Heartbeat taps from Timer, DMA, FIR, VGA
//   - Outputs:
//       nmi_prewarn   : Non-Maskable Interrupt 1 tick prior to hard reset
//       wdt_reset     : Fatal hard reset pulse to system reset generator
//       wdt_reset_out : External SoC pin indicator
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module watchdog #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Pipeline Liveness Heartbeat Taps
    input  wire [3:0]            pipeline_alive,

    // Reset & NMI Signals
    output reg                   nmi_prewarn,
    output reg                   wdt_reset,
    output wire                  wdt_reset_out,

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
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready
);

    reg        wdt_en;
    reg [31:0] wdt_reload;
    reg [31:0] wdt_counter;
    reg        wdt_tripped;
    reg        kick_pulse;

    assign wdt_reset_out = wdt_reset;

    // -------------------------------------------------------------------------
    // Watchdog Countdown & Trip Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_counter <= 32'hFFFF_FFFF;
            nmi_prewarn <= 1'b0;
            wdt_reset   <= 1'b0;
            wdt_tripped <= 1'b0;
        end else if (wdt_en) begin
            if (kick_pulse) begin
                wdt_counter <= wdt_reload;
                nmi_prewarn <= 1'b0;
                wdt_reset   <= 1'b0;
            end else if (wdt_counter == 32'd1) begin
                // Pre-warning NMI: 1 tick before fatal timeout
                nmi_prewarn <= 1'b1;
                wdt_counter <= 32'd0;
            end else if (wdt_counter == 32'd0) begin
                // Fatal timeout reached
                wdt_reset   <= 1'b1;
                wdt_tripped <= 1'b1;
                nmi_prewarn <= 1'b0;
                wdt_counter <= wdt_reload;
            end else begin
                wdt_counter <= wdt_counter - 1'b1;
                wdt_reset   <= 1'b0;
            end
        end else begin
            wdt_counter <= wdt_reload;
            nmi_prewarn <= 1'b0;
            wdt_reset   <= 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Channel
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            aw_done        <= 1'b0;
            w_done         <= 1'b0;
            awaddr_latched <= {ADDR_WIDTH{1'b0}};

            wdt_en         <= 1'b0;
            wdt_reload     <= 32'hFFFF_FFFF;
            kick_pulse     <= 1'b0;
        end else begin
            kick_pulse <= 1'b0;

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
                case (awaddr_latched[3:0])
                    4'h0: wdt_en     <= s_axi_wdata[0];
                    4'h4: wdt_reload <= s_axi_wdata;
                    4'h8: kick_pulse <= 1'b1; // Any write kicks watchdog
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_done      <= 1'b0;
                w_done       <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Read Channel
    // -------------------------------------------------------------------------
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
                case (s_axi_araddr[3:0])
                    4'h0: s_axi_rdata <= {31'd0, wdt_en};
                    4'h4: s_axi_rdata <= wdt_reload;
                    4'h8: s_axi_rdata <= wdt_counter;
                    4'hC: s_axi_rdata <= {30'd0, wdt_tripped, nmi_prewarn};
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
