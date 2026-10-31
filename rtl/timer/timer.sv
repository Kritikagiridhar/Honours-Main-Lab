// =============================================================================
// Module      : timer.sv
// Description : System Timer IP with AXI4-Lite Slave Interface
// Specification: Architecture Document Section 8.3
//   - Registers:
//       0x00: TIMER_CTRL   [0] EN
//       0x04: TIMER_RELOAD [31:0] RELOAD
//       0x08: TIMER_COUNT  [31:0] COUNT
//       0x0C: TIMER_STATUS [0] TICK (W1C)
//   - Outputs:
//       sample_tick: 1-cycle pulse at configured sample rate (feeds DMA)
//       irq_timer  : Interrupt asserted when TICK=1
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module timer #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // AXI4-Lite Slave Interface
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
    input  wire                  s_axi_rready,

    // Cross-IP and Interrupt Signals
    output reg                   sample_tick,
    output wire                  irq_timer
);

    // Register definitions
    reg        timer_en;
    reg [31:0] timer_reload;
    reg [31:0] timer_count;
    reg        timer_tick;

    assign irq_timer = timer_tick;

    // -------------------------------------------------------------------------
    // Timer Down-Counter Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count <= 32'd0;
            sample_tick <= 1'b0;
        end else if (timer_en) begin
            if (timer_count == 32'd0) begin
                timer_count <= timer_reload;
                sample_tick <= 1'b1;
            end else begin
                timer_count <= timer_count - 1'b1;
                sample_tick <= 1'b0;
            end
        end else begin
            timer_count <= timer_reload;
            sample_tick <= 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Handshake & Register Updates
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
            timer_en       <= 1'b0;
            timer_reload   <= 32'd0;
            timer_tick     <= 1'b0;
        end else begin
            // Clear or assert tick flag
            if (sample_tick) begin
                timer_tick <= 1'b1;
            end

            // Address Write Channel
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            // Write Data Channel
            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Perform Write when both address and data are latched
            if (aw_done && w_done && !s_axi_bvalid) begin
                case (awaddr_latched[3:0])
                    4'h0: timer_en     <= s_axi_wdata[0];
                    4'h4: timer_reload <= s_axi_wdata;
                    4'hC: begin
                        // W1C for TICK
                        if (s_axi_wdata[0]) timer_tick <= 1'b0;
                    end
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end

            // Complete Write Response Handshake
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
                    4'h0: s_axi_rdata <= {31'd0, timer_en};
                    4'h4: s_axi_rdata <= timer_reload;
                    4'h8: s_axi_rdata <= timer_count;
                    4'hC: s_axi_rdata <= {31'd0, timer_tick};
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
