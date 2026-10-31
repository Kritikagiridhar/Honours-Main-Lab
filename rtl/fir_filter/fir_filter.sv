// =============================================================================
// Module      : fir_filter.sv
// Description : 16-Tap Programmable FIR Filter with Q1.15 MAC Pipeline & AXI4-Lite CSRs
// Specification: Architecture Document Section 8.5
//   - Registers:
//       0x00      : FIR_CTRL   [0] EN, [1] BYPASS (Reset: 0x2)
//       0x04      : FIR_NTAPS  [5:0] NTAPS (Reset: 0x8, max 16)
//       0x08..0x44: FIR_COEF0..15 [15:0] Signed Q1.15 coefficients
//       0x48      : FIR_STATUS [0] COEF_LOAD_DONE, [1] PIPE_OVF (W1C)
//   - Streaming Interface:
//       Input : fir_sample_in[15:0], fir_sample_valid_in
//       Output: fir_sample_out[15:0], fir_sample_valid_out
//   - Outputs:
//       irq_fir: Asserted on COEF_LOAD_DONE or PIPE_OVF
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module fir_filter #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MAX_TAPS   = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Streaming Sample Interface (from/to DMA)
    input  wire signed [15:0]    fir_sample_in,
    input  wire                  fir_sample_valid_in,
    output reg  signed [15:0]    fir_sample_out,
    output reg                   fir_sample_valid_out,

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
    input  wire                  s_axi_rready,

    // Interrupt
    output wire                  irq_fir
);

    // -------------------------------------------------------------------------
    // Control & Coefficient Registers
    // -------------------------------------------------------------------------
    reg        fir_en;
    reg        fir_bypass;
    reg [4:0]  fir_ntaps; // 1 to 16
    reg signed [15:0] coef_mem [0:MAX_TAPS-1];
    reg        coef_load_done;
    reg        pipe_ovf;

    assign irq_fir = coef_load_done || pipe_ovf;

    // -------------------------------------------------------------------------
    // MAC Datapath & Delay Line (Driven by Streaming or AXI Memory-Mapped Port)
    // -------------------------------------------------------------------------
    reg signed [15:0] delay_line [0:MAX_TAPS-1];
    integer i;

    // AXI Memory-Mapped Sample Data Registers
    reg signed [15:0] axi_sample_in;
    reg               axi_sample_in_valid;
    reg signed [15:0] axi_sample_out;
    reg               axi_sample_out_valid;
    reg               axi_data_in_strobe;
    reg signed [15:0] axi_data_in_val;
    reg               axi_data_out_read_strobe;

    // Unified sample input mux
    wire signed [15:0] eff_sample_in = axi_sample_in_valid ? axi_sample_in : fir_sample_in;
    wire               eff_valid_in  = axi_sample_in_valid || fir_sample_valid_in;

    // MAC accumulation
    reg signed [31:0] mac_acc;
    reg               mac_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fir_sample_out       <= 16'sd0;
            fir_sample_valid_out <= 1'b0;
            axi_sample_out       <= 16'sd0;
            axi_sample_out_valid <= 1'b0;
            axi_sample_in_valid  <= 1'b0;
            axi_sample_in        <= 16'sd0;
            mac_acc              <= 32'sd0;
            mac_valid            <= 1'b0;
            pipe_ovf             <= 1'b0;
            for (i = 0; i < MAX_TAPS; i = i + 1) begin
                delay_line[i] <= 16'sd0;
            end
        end else begin
            if (eff_valid_in) begin
                axi_sample_in_valid <= 1'b0; // Consumed

                if (fir_bypass || !fir_en) begin
                    // Hardware bypass: pass through with 1 cycle registration
                    fir_sample_out       <= eff_sample_in;
                    fir_sample_valid_out <= 1'b1;
                    axi_sample_out       <= eff_sample_in;
                    axi_sample_out_valid <= 1'b1;
                end else begin
                    // Shift delay line
                    delay_line[0] <= eff_sample_in;
                    for (i = 1; i < MAX_TAPS; i = i + 1) begin
                        delay_line[i] <= delay_line[i-1];
                    end

                    // Multiply-accumulate across active taps
                    // Note: Q1.15 * Q1.15 = Q2.30
                    begin : mac_loop
                        reg signed [39:0] acc;
                        reg signed [31:0] mult;
                        reg signed [15:0] sat_out;
                        integer k;
                        acc = 40'sd0;
                        for (k = 0; k < MAX_TAPS; k = k + 1) begin
                            if (k < fir_ntaps) begin
                                mult = (k == 0) ? (eff_sample_in * coef_mem[0])
                                                : (delay_line[k-1] * coef_mem[k]);
                                acc = acc + {{8{mult[31]}}, mult};
                            end
                        end

                        // Check overflow beyond 32-bit Q2.30 range
                        if (acc > 40'sh00_7FFF_FFFF || acc < -40'sh00_8000_0000) begin
                            pipe_ovf <= 1'b1;
                        end

                        // Scale Q2.30 down to Q1.15 by shifting right by 15 with saturation
                        if (acc[39:30] == 10'd0 || acc[39:30] == 10'h3FF) begin
                            sat_out = acc[30:15];
                        end else if (acc[39]) begin
                            sat_out = -16'sd32768; // Negative saturation
                        end else begin
                            sat_out = 16'sd32767;  // Positive saturation
                        end

                        fir_sample_out       <= sat_out;
                        fir_sample_valid_out <= 1'b1;
                        axi_sample_out       <= sat_out;
                        axi_sample_out_valid <= 1'b1;
                    end
                end
            end else begin
                fir_sample_valid_out <= 1'b0;
            end

            // Latch AXI write data into axi_sample_in
            if (axi_data_in_strobe) begin
                axi_sample_in       <= axi_data_in_val;
                axi_sample_in_valid <= 1'b1;
            end

            // Clear axi_sample_out_valid on AXI read
            if (axi_data_out_read_strobe) begin
                axi_sample_out_valid <= 1'b0;
            end
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
            s_axi_awready      <= 1'b0;
            s_axi_wready       <= 1'b0;
            s_axi_bvalid       <= 1'b0;
            s_axi_bresp        <= 2'b00;
            aw_done            <= 1'b0;
            w_done             <= 1'b0;
            awaddr_latched     <= {ADDR_WIDTH{1'b0}};
            axi_data_in_strobe <= 1'b0;
            axi_data_in_val    <= 16'sd0;

            fir_en         <= 1'b0;
            fir_bypass     <= 1'b1; // Default: bypass mode active
            fir_ntaps      <= 5'd8; // Default: 8 taps
            coef_load_done <= 1'b0;
            for (i = 0; i < MAX_TAPS; i = i + 1) begin
                coef_mem[i] <= 16'sd0;
            end
        end else begin
            axi_data_in_strobe <= 1'b0;

            // Address Write
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            // Data Write
            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Register write execution
            if (aw_done && w_done && !s_axi_bvalid) begin
                if (awaddr_latched[7:0] == 8'h00) begin
                    fir_en     <= s_axi_wdata[0];
                    fir_bypass <= s_axi_wdata[1];
                end else if (awaddr_latched[7:0] == 8'h04) begin
                    fir_ntaps <= s_axi_wdata[4:0];
                end else if (awaddr_latched[7:0] >= 8'h08 && awaddr_latched[7:0] <= 8'h44) begin
                    coef_mem[(awaddr_latched[7:0] - 8'h08) >> 2] <= s_axi_wdata[15:0];
                    if (((awaddr_latched[7:0] - 8'h08) >> 2) == (fir_ntaps - 1)) begin
                        coef_load_done <= 1'b1;
                    end
                end else if (awaddr_latched[7:0] == 8'h48) begin
                    if (s_axi_wdata[0]) coef_load_done <= 1'b0;
                    if (s_axi_wdata[1]) pipe_ovf       <= 1'b0;
                end else if (awaddr_latched[7:0] == 8'h50) begin
                    axi_data_in_val    <= s_axi_wdata[15:0];
                    axi_data_in_strobe <= 1'b1;
                end
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
            s_axi_arready            <= 1'b0;
            s_axi_rvalid             <= 1'b0;
            s_axi_rdata              <= {DATA_WIDTH{1'b0}};
            s_axi_rresp              <= 2'b00;
            axi_data_out_read_strobe <= 1'b0;
        end else begin
            axi_data_out_read_strobe <= 1'b0;

            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                if (s_axi_araddr[7:0] == 8'h00) begin
                    s_axi_rdata <= {30'd0, fir_bypass, fir_en};
                end else if (s_axi_araddr[7:0] == 8'h04) begin
                    s_axi_rdata <= {27'd0, fir_ntaps};
                end else if (s_axi_araddr[7:0] >= 8'h08 && s_axi_araddr[7:0] <= 8'h44) begin
                    s_axi_rdata <= {{16{coef_mem[(s_axi_araddr[7:0] - 8'h08) >> 2][15]}},
                                    coef_mem[(s_axi_araddr[7:0] - 8'h08) >> 2]};
                end else if (s_axi_araddr[7:0] == 8'h48) begin
                    s_axi_rdata <= {30'd0, pipe_ovf, coef_load_done};
                end else if (s_axi_araddr[7:0] == 8'h54) begin
                    s_axi_rdata <= {{16{axi_sample_out[15]}}, axi_sample_out};
                    axi_data_out_read_strobe <= 1'b1;
                end else if (s_axi_araddr[7:0] == 8'h58) begin
                    s_axi_rdata <= {30'd0, axi_sample_out_valid, !axi_sample_in_valid};
                end else begin
                    s_axi_rdata <= 32'd0;
                end
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
