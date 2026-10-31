// =============================================================================
// Module      : gpio.sv
// Description : General Purpose Input/Output (GPIO) IP with AXI4-Lite Slave Interface
// Specification: Architecture Document Section 8.4
//   - Registers:
//       0x00: GPIO_IN     [7:0] IN (Synchronized input values)
//       0x04: GPIO_OUT    [7:0] OUT (Status LEDs)
//       0x08: GPIO_IRQ_EN [7:0] CHANGE_EN (Per-bit change interrupt enable)
//       0x0C: GPIO_STATUS [0]   CHANGED (W1C)
//   - Outputs:
//       gpio_out [7:0]: Status LEDs
//       irq_gpio      : Interrupt asserted on button change
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module gpio #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // External Boundary Pins
    input  wire [7:0]            gpio_in,
    output wire [7:0]            gpio_out,

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

    // Interrupt Line
    output wire                  irq_gpio
);

    // Registers
    reg [7:0] reg_gpio_out;
    reg [7:0] reg_gpio_irq_en;
    reg       reg_gpio_changed;

    assign gpio_out = reg_gpio_out;
    assign irq_gpio = reg_gpio_changed;

    // -------------------------------------------------------------------------
    // Input Synchronization & Edge Detection
    // -------------------------------------------------------------------------
    reg [7:0] gpio_sync_0;
    reg [7:0] gpio_sync_1;
    reg [7:0] gpio_sync_2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_sync_0 <= 8'd0;
            gpio_sync_1 <= 8'd0;
            gpio_sync_2 <= 8'd0;
        end else begin
            gpio_sync_0 <= gpio_in;
            gpio_sync_1 <= gpio_sync_0;
            gpio_sync_2 <= gpio_sync_1;
        end
    end

    wire [7:0] gpio_edge = (gpio_sync_1 ^ gpio_sync_2) & reg_gpio_irq_en;

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Channel
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
            reg_gpio_out     <= 8'd0;
            reg_gpio_irq_en  <= 8'd0;
            reg_gpio_changed <= 1'b0;
        end else begin
            // Edge event assertion
            if (|gpio_edge) begin
                reg_gpio_changed <= 1'b1;
            end

            // Address Write Channel
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            // Data Write Channel
            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Write Handshake
            if (aw_done && w_done && !s_axi_bvalid) begin
                case (awaddr_latched[3:0])
                    4'h4: reg_gpio_out    <= s_axi_wdata[7:0];
                    4'h8: reg_gpio_irq_en <= s_axi_wdata[7:0];
                    4'hC: begin
                        if (s_axi_wdata[0]) reg_gpio_changed <= 1'b0;
                    end
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
                    4'h0: s_axi_rdata <= {24'd0, gpio_sync_1};
                    4'h4: s_axi_rdata <= {24'd0, reg_gpio_out};
                    4'h8: s_axi_rdata <= {24'd0, reg_gpio_irq_en};
                    4'hC: s_axi_rdata <= {31'd0, reg_gpio_changed};
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
