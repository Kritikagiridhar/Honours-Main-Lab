// =============================================================================
// Module      : pwm.sv
// Description : 4-Channel Pulse Width Modulation (PWM) Controller with
//               AXI4-Lite Slave Interface
// Project     : RISC-V Based Smart Control SoC with PWM, SPI and Seven-Segment Display
//
// Memory Map  : Base 0x4000_2000 (4 KB aperture)
// Registers   :
//     0x00: PWM_CTRL    [3:0] CH_EN   (per-channel enable)
//                        [7:4] reserved
//     0x04: PWM_PERIOD  [15:0] PERIOD  (common period, in clk cycles, all channels)
//     0x08: PWM_DUTY0   [15:0] Channel-0 duty count (high time within period)
//     0x0C: PWM_DUTY1   [15:0] Channel-1 duty count
//     0x10: PWM_DUTY2   [15:0] Channel-2 duty count
//     0x14: PWM_DUTY3   [15:0] Channel-3 duty count
//     0x18: PWM_STATUS  [3:0] RUNNING (RO, per-channel active indicator)
//     0x1C: PWM_IRQ_CTRL [0]   IRQ_EN   (enable period-rollover interrupt)
//
// Outputs     :
//     pwm_out[3:0]  : 4 independent PWM output channels
//     irq_pwm       : Interrupt pulse on period rollover (when IRQ_EN=1)
// =============================================================================

`resetall
`timescale 1ns / 1ps
`default_nettype none

module pwm #(
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

    // PWM Physical Outputs & Interrupt
    output wire [3:0]            pwm_out,
    output wire                  irq_pwm
);

    // -------------------------------------------------------------------------
    // Control / Status Registers
    // -------------------------------------------------------------------------
    reg [3:0]  reg_ch_en;       // per-channel enable
    reg [15:0] reg_period;      // common period
    reg [15:0] reg_duty [0:3];  // per-channel duty
    reg        reg_irq_en;      // interrupt enable
    reg        irq_pulse;       // 1-cycle rollover interrupt pulse

    // 16-bit free-running counter shared by all channels
    reg [15:0] pwm_counter;

    // Per-channel running status (counter active and channel enabled)
    wire [3:0] ch_running = reg_ch_en & {4{|reg_period}};

    // -------------------------------------------------------------------------
    // PWM Counter & Output Generation
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_counter <= 16'd0;
            irq_pulse    <= 1'b0;
        end else begin
            if (|reg_ch_en && reg_period != 16'd0) begin
                if (pwm_counter >= reg_period - 16'd1) begin
                    pwm_counter <= 16'd0;
                    irq_pulse    <= 1'b1;       // rollover pulse
                end else begin
                    pwm_counter <= pwm_counter + 16'd1;
                    irq_pulse    <= 1'b0;
                end
            end else begin
                pwm_counter <= 16'd0;
                irq_pulse    <= 1'b0;
            end
        end
    end

    // Channel output: high while counter < duty (when enabled)
    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : gen_ch
            assign pwm_out[gi] = reg_ch_en[gi] && (pwm_counter < reg_duty[gi]);
        end
    endgenerate

    assign irq_pwm = irq_pulse & reg_irq_en;

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Channel
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    integer ci;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            aw_done        <= 1'b0;
            w_done         <= 1'b0;
            awaddr_latched <= {ADDR_WIDTH{1'b0}};
            reg_ch_en      <= 4'd0;
            reg_period     <= 16'd0;
            reg_irq_en     <= 1'b0;
            for (ci = 0; ci < 4; ci = ci + 1) reg_duty[ci] <= 16'd0;
        end else begin
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

            // Register write execution
            if (aw_done && w_done && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
                case (awaddr_latched[4:0])
                    5'h00: reg_ch_en  <= s_axi_wdata[3:0];
                    5'h04: reg_period <= s_axi_wdata[15:0];
                    5'h08: reg_duty[0] <= s_axi_wdata[15:0];
                    5'h0C: reg_duty[1] <= s_axi_wdata[15:0];
                    5'h10: reg_duty[2] <= s_axi_wdata[15:0];
                    5'h14: reg_duty[3] <= s_axi_wdata[15:0];
                    5'h1C: reg_irq_en <= s_axi_wdata[0];
                    default: ;
                endcase
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
                case (s_axi_araddr[4:0])
                    5'h00: s_axi_rdata <= {28'd0, reg_ch_en};
                    5'h04: s_axi_rdata <= {16'd0, reg_period};
                    5'h08: s_axi_rdata <= {16'd0, reg_duty[0]};
                    5'h0C: s_axi_rdata <= {16'd0, reg_duty[1]};
                    5'h10: s_axi_rdata <= {16'd0, reg_duty[2]};
                    5'h14: s_axi_rdata <= {16'd0, reg_duty[3]};
                    5'h18: s_axi_rdata <= {28'd0, ch_running};
                    5'h1C: s_axi_rdata <= {31'd0, reg_irq_en};
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
