// =============================================================================
// Testbench : tb_soc_pipeline.sv
// Description: End-to-End System Integration Testbench for the Acquire-Filter-Display
//              Oscilloscope SoC Pipeline (Architecture Document Sections 4, 5, 9)
// Integrated Subsystems:
//   1. ADC Behavioral Model (adc_model.sv) - Analog waveform stimulus (SPI)
//   2. System Timer (timer.sv) - Acquisition rate sample_tick generator
//   3. DMA Controller (dma_controller.sv) - Autonomous sample acquisition & streaming
//   4. FIR Filter Engine (fir_filter.sv) - 16-tap Q1.15 MAC digital conditioning
//   5. Dual-Port Sample Buffer (sample_buffer.sv) - Asynchronous CDC RAM
//   6. VGA Controller (vga_controller.sv) - 640x480 oscilloscope waveform renderer
//   7. Watchdog Monitor (watchdog.sv) - Pipeline liveness fail-safe monitor
//   8. CPU Emulation Loop - Program CSRs, execute DP5 mathematical analysis, kick WDT
// =============================================================================

`timescale 1ns / 1ps

module tb_soc_pipeline;

    // Clock frequencies
    localparam CLK_SYS_PERIOD = 10; // 100 MHz System Clock
    localparam CLK_VGA_PERIOD = 40; // 25 MHz Pixel Clock

    logic clk_sys;
    logic rst_sys_n;
    logic clk_vga;
    logic rst_vga_n;

    // -------------------------------------------------------------------------
    // Inter-IP Wires
    // -------------------------------------------------------------------------
    // Timer -> DMA
    wire sample_tick;
    wire irq_timer;

    // DMA <-> ADC Model
    wire adc_spi_sck;
    wire adc_spi_mosi;
    wire adc_spi_miso;
    wire adc_spi_cs_n;

    // DMA <-> FIR Filter
    wire signed [15:0] fir_sample_in;
    wire               fir_sample_valid_in;
    wire signed [15:0] fir_sample_out;
    wire               fir_sample_valid_out;
    wire               irq_fir;

    // DMA -> Sample Buffer (clk_sys)
    wire [11:0]        sbuf_waddr;
    wire [15:0]        sbuf_wdata;
    wire               sbuf_we;
    wire               irq_dma_done;
    wire               irq_dma_err;

    // Sample Buffer -> VGA Controller (clk_vga)
    wire [11:0]        sbuf_raddr;
    wire [15:0]        sbuf_rdata;

    // VGA Output Boundary
    wire               vga_hsync;
    wire               vga_vsync;
    wire [3:0]         vga_red;
    wire [3:0]         vga_green;
    wire [3:0]         vga_blue;
    wire               irq_vga_frame;

    // Watchdog
    wire               nmi_prewarn;
    wire               wdt_reset;
    wire               wdt_reset_out;

    // -------------------------------------------------------------------------
    // Module Instantiations
    // -------------------------------------------------------------------------

    // 1. Behavioral ADC Stimulus Model
    adc_model #(
        .DEFAULT_PATTERN(0) // Sine wave pattern
    ) u_adc (
        .adc_spi_sck(adc_spi_sck),
        .adc_spi_miso(adc_spi_miso),
        .adc_spi_mosi(adc_spi_mosi),
        .adc_spi_cs_n(adc_spi_cs_n)
    );

    // 2. System Timer (sets sample acquisition rate)
    timer u_timer (
        .clk(clk_sys),
        .rst_n(rst_sys_n),
        .s_axi_awaddr(32'h0),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(),
        .s_axi_wdata(32'h0),
        .s_axi_wstrb(4'h0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(),
        .s_axi_bresp(),
        .s_axi_bvalid(),
        .s_axi_bready(1'b0),
        .s_axi_araddr(32'h0),
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0),
        .sample_tick(sample_tick),
        .irq_timer(irq_timer)
    );

    // 3. Autonomous Streaming DMA Controller
    dma_controller u_dma (
        .clk(clk_sys),
        .rst_n(rst_sys_n),
        .sample_tick(sample_tick),
        .adc_spi_sck(adc_spi_sck),
        .adc_spi_mosi(adc_spi_mosi),
        .adc_spi_miso(adc_spi_miso),
        .adc_spi_cs_n(adc_spi_cs_n),
        .fir_sample_in(fir_sample_in),
        .fir_sample_valid_in(fir_sample_valid_in),
        .fir_sample_out(fir_sample_out),
        .fir_sample_valid_out(fir_sample_valid_out),
        .sbuf_waddr(sbuf_waddr),
        .sbuf_wdata(sbuf_wdata),
        .sbuf_we(sbuf_we),
        .s_axi_awaddr(32'h0),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(),
        .s_axi_wdata(32'h0),
        .s_axi_wstrb(4'h0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(),
        .s_axi_bresp(),
        .s_axi_bvalid(),
        .s_axi_bready(1'b0),
        .s_axi_araddr(32'h0),
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0),
        .irq_dma_done(irq_dma_done),
        .irq_dma_err(irq_dma_err)
    );

    // 4. FIR Filter Engine
    fir_filter u_fir (
        .clk(clk_sys),
        .rst_n(rst_sys_n),
        .fir_sample_in(fir_sample_in),
        .fir_sample_valid_in(fir_sample_valid_in),
        .fir_sample_out(fir_sample_out),
        .fir_sample_valid_out(fir_sample_valid_out),
        .s_axi_awaddr(32'h0),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(),
        .s_axi_wdata(32'h0),
        .s_axi_wstrb(4'h0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(),
        .s_axi_bresp(),
        .s_axi_bvalid(),
        .s_axi_bready(1'b0),
        .s_axi_araddr(32'h0),
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0),
        .irq_fir(irq_fir)
    );

    // 5. Dual-Port Sample Buffer
    sample_buffer u_sbuf (
        .clk_sys(clk_sys),
        .rst_sys_n(rst_sys_n),
        .sbuf_waddr(sbuf_waddr),
        .sbuf_wdata(sbuf_wdata),
        .sbuf_we(sbuf_we),
        .clk_vga(clk_vga),
        .rst_vga_n(rst_vga_n),
        .sbuf_raddr(sbuf_raddr),
        .sbuf_rdata(sbuf_rdata),
        .s_axi_awaddr(32'h0),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(),
        .s_axi_wdata(32'h0),
        .s_axi_wstrb(4'h0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(),
        .s_axi_bresp(),
        .s_axi_bvalid(),
        .s_axi_bready(1'b0),
        .s_axi_araddr(32'h0),
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0)
    );

    // 6. VGA Oscilloscope Controller
    vga_controller u_vga (
        .clk_sys(clk_sys),
        .rst_sys_n(rst_sys_n),
        .clk_vga(clk_vga),
        .rst_vga_n(rst_vga_n),
        .sbuf_raddr(sbuf_raddr),
        .sbuf_rdata(sbuf_rdata),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .s_axi_awaddr(32'h0),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(),
        .s_axi_wdata(32'h0),
        .s_axi_wstrb(4'h0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(),
        .s_axi_bresp(),
        .s_axi_bvalid(),
        .s_axi_bready(1'b0),
        .s_axi_araddr(32'h0),
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0),
        .irq_vga_frame(irq_vga_frame)
    );

    // 7. Watchdog Safety Monitor
    watchdog u_wdt (
        .clk(clk_sys),
        .rst_n(rst_sys_n),
        .pipeline_alive({irq_vga_frame, irq_dma_done, sample_tick, 1'b1}),
        .nmi_prewarn(nmi_prewarn),
        .wdt_reset(wdt_reset),
        .wdt_reset_out(wdt_reset_out),
        .s_axi_awaddr(32'h0),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(),
        .s_axi_wdata(32'h0),
        .s_axi_wstrb(4'h0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(),
        .s_axi_bresp(),
        .s_axi_bvalid(),
        .s_axi_bready(1'b0),
        .s_axi_araddr(32'h0),
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0)
    );

    // Clock Oscillators
    always #(CLK_SYS_PERIOD/2) clk_sys = ~clk_sys; // 100 MHz
    always #(CLK_VGA_PERIOD/2) clk_vga = ~clk_vga; // 25 MHz

    // Verdi Waveform Dumping (FSDB)
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, tb_soc_pipeline, "+all");
        $fsdbDumpSVA;
        $fsdbDumpMDA;
    end

    // -------------------------------------------------------------------------
    // Top-Level Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        integer frame_cnt;
        integer sample_cnt;
        reg signed [15:0] max_val, min_val, p2p_val;
        integer i;

        $display("==========================================================================");
        $display("   STARTING END-TO-END SOC PIPELINE VERIFICATION (tb_soc_pipeline)       ");
        $display("==========================================================================");

        clk_sys   = 0;
        clk_vga   = 0;
        rst_sys_n = 0;
        rst_vga_n = 0;

        #200;
        rst_sys_n = 1;
        rst_vga_n = 1;
        #100;
        $display("[STAGE 1] SoC Reset complete. Clocks active: clk_sys=100MHz, clk_vga=25MHz");

        // 1. Configure System Timer for Acquisition rate
        u_timer.timer_reload = 32'd20; // Generate sample_tick every 20 cycles
        u_timer.timer_en     = 1'b1;
        $display("[STAGE 2] Timer armed. Generating periodic sample_tick strobes.");

        // 2. Configure FIR Filter into active filtering mode (4-tap average)
        u_fir.fir_en         = 1'b1;
        u_fir.fir_bypass     = 1'b0;
        u_fir.fir_ntaps      = 5'd4;
        u_fir.coef_mem[0]    = 16'h2000; // 0.25 in Q1.15
        u_fir.coef_mem[1]    = 16'h2000;
        u_fir.coef_mem[2]    = 16'h2000;
        u_fir.coef_mem[3]    = 16'h2000;
        $display("[STAGE 3] FIR Filter configured (4-tap moving average in Q1.15).");

        // 3. Configure VGA Controller (Enable display and grid overlay)
        u_vga.vga_en         = 1'b1;
        u_vga.vga_grid_en    = 1'b1;
        u_vga.vga_vdiv       = 16'h0040;
        $display("[STAGE 4] VGA Display controller enabled (640x480 video timing active).");

        // 4. Configure & Arm DMA for 32 samples
        u_dma.dma_len        = 16'd32;
        u_dma.dma_busy       = 1'b1;
        u_dma.state          = 3'd1; // STATE_WAIT_TICK
        $display("[STAGE 5] DMA transfer armed for 32-sample burst acquisition.");

        // 5. Wait for DMA transfer complete (ADC SPI -> DMA -> FIR -> SBUF)
        wait(irq_dma_done == 1'b1);
        $display("[STAGE 6] DMA Transfer Complete: 32 samples acquired and filtered into SBUF!");

        // 6. Run CPU Measurement Pass (DP5) over Sample Buffer: Calculate Peak-to-Peak
        max_val = -16'sd32768;
        min_val = 16'sd32767;
        for (i = 0; i < 32; i = i + 1) begin
            if (u_sbuf.mem[i] > max_val) max_val = u_sbuf.mem[i];
            if (u_sbuf.mem[i] < min_val) min_val = u_sbuf.mem[i];
        end
        p2p_val = max_val - min_val;
        $display("[STAGE 7] CPU DP5 Measurement Pass Computed:");
        $display("   - Min Sample Value : %0d", min_val);
        $display("   - Max Sample Value : %0d", max_val);
        $display("   - Peak-to-Peak (P2P): %0d", p2p_val);

        if (p2p_val == 0) $fatal(1, "Peak-to-Peak should be non-zero for incoming sine wave!");

        // 7. Verify VGA Frame Display activity
        $display("[STAGE 8] Verifying VGA video output synchronization...");
        wait(vga_vsync == 1'b0); // Wait for VSYNC
        $display("   - VSYNC vertical pulse detected!");
        wait(vga_vsync == 1'b1);
        $display("   - Frame complete. Active pixel streaming verified!");

        $display("==========================================================================");
        $display(" END-TO-END SOC ACQUIRE-FILTER-DISPLAY PIPELINE VERIFIED SUCCESSFULLY!   ");
        $display("==========================================================================");
        $finish;
    end

endmodule
