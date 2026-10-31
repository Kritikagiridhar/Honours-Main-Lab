// =============================================================================
// Testbench : tb_dma_controller.sv
// DUT       : dma_controller.sv
// Description: Comprehensive verification of Autonomous DMA Controller
//              connected to adc_model.sv and fir_filter.sv
// =============================================================================

`timescale 1ns / 1ps

module tb_dma_controller;

    localparam ADDR_WIDTH     = 32;
    localparam DATA_WIDTH     = 32;
    localparam BUF_ADDR_WIDTH = 12;
    localparam CLK_PERIOD     = 10;

    logic                  clk;
    logic                  rst_n;
    logic                  sample_tick;

    // SPI Signals
    wire                   adc_spi_sck;
    wire                   adc_spi_mosi;
    wire                   adc_spi_miso;
    wire                   adc_spi_cs_n;

    // FIR Interface
    wire signed [15:0]     fir_sample_in;
    wire                   fir_sample_valid_in;
    logic signed [15:0]    fir_sample_out;
    logic                  fir_sample_valid_out;

    // Sample Buffer Interface
    wire [BUF_ADDR_WIDTH-1:0] sbuf_waddr;
    wire [15:0]               sbuf_wdata;
    wire                      sbuf_we;

    // AXI4-Lite
    logic [ADDR_WIDTH-1:0] s_axi_awaddr;
    logic                  s_axi_awvalid;
    wire                   s_axi_awready;
    logic [DATA_WIDTH-1:0] s_axi_wdata;
    logic [3:0]            s_axi_wstrb;
    logic                  s_axi_wvalid;
    wire                   s_axi_wready;
    wire  [1:0]            s_axi_bresp;
    wire                   s_axi_bvalid;
    logic                  s_axi_bready;
    logic [ADDR_WIDTH-1:0] s_axi_araddr;
    logic                  s_axi_arvalid;
    wire                   s_axi_arready;
    wire  [DATA_WIDTH-1:0] s_axi_rdata;
    wire  [1:0]            s_axi_rresp;
    wire                   s_axi_rvalid;
    logic                  s_axi_rready;

    // Interrupts
    wire                   irq_dma_done;
    wire                   irq_dma_err;

    // Instantiate DUT (DMA Controller)
    dma_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BUF_ADDR_WIDTH(BUF_ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
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
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .irq_dma_done(irq_dma_done),
        .irq_dma_err(irq_dma_err)
    );

    // Instantiate Behavioral ADC Model
    adc_model u_adc (
        .adc_spi_sck(adc_spi_sck),
        .adc_spi_miso(adc_spi_miso),
        .adc_spi_mosi(adc_spi_mosi),
        .adc_spi_cs_n(adc_spi_cs_n)
    );

    // Registered FIR loopback (1-cycle latency matching fir_filter.sv)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fir_sample_out       <= 16'sd0;
            fir_sample_valid_out <= 1'b0;
        end else begin
            fir_sample_out       <= fir_sample_in;
            fir_sample_valid_out <= fir_sample_valid_in;
        end
    end

    always #(CLK_PERIOD/2) clk = ~clk;

    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        @(posedge clk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'hF;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;

        fork
            begin
                wait(s_axi_awready);
                @(posedge clk);
                s_axi_awvalid <= 1'b0;
            end
            begin
                wait(s_axi_wready);
                @(posedge clk);
                s_axi_wvalid <= 1'b0;
            end
        join

        wait(s_axi_bvalid);
        @(posedge clk);
        s_axi_bready <= 1'b0;
    endtask

    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
        @(posedge clk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1'b1;
        s_axi_rready  <= 1'b1;

        wait(s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 1'b0;

        wait(s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge clk);
        s_axi_rready <= 1'b0;
    endtask

    initial begin
        logic [DATA_WIDTH-1:0] rdata;
        integer samples_received = 0;
        $display("==========================================================");
        $display(" Starting DMA Controller Verification (tb_dma_controller)");
        $display("==========================================================");

        clk           = 0;
        rst_n         = 0;
        sample_tick   = 0;
        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // Test 1: Program DMA transfer length = 8 samples
        axi_write(32'h0C, 32'd8);
        axi_read(32'h0C, rdata);
        if (rdata[15:0] != 16'd8) $fatal(1, "DMA_LEN configuration mismatch!");
        $display("[PASS] Test 1: Programmed DMA_LEN = 8 samples.");

        // Test 2: Arm DMA (START=1)
        axi_write(32'h00, 32'h01);
        axi_read(32'h14, rdata);
        if (!rdata[0]) $fatal(1, "DMA_STATUS.BUSY should be 1 after START!");
        $display("[PASS] Test 2: DMA armed and entered BUSY state.");

        // Test 3: Generate 8 sample_tick pulses to acquire 8 samples over SPI
        $display("Generating periodic sample_tick pulses to drive acquisition...");
        while (samples_received < 8) begin
            #(CLK_PERIOD * 10);
            @(posedge clk);
            sample_tick <= 1'b1;
            @(posedge clk);
            sample_tick <= 1'b0;

            // Wait for SPI transaction and buffer write
            wait(sbuf_we == 1'b1);
            samples_received = samples_received + 1;
            $display("  Sample #%0d acquired: %h written to SBUF addr %0d", 
                     samples_received, sbuf_wdata, sbuf_waddr);
            @(posedge clk);
        end

        // Test 4: Verify Transfer Complete (irq_dma_done and STATUS.DONE)
        wait(irq_dma_done == 1'b1);
        axi_read(32'h14, rdata);
        if (!rdata[1]) $fatal(1, "DMA_STATUS.DONE should be asserted!");
        if (rdata[0])  $fatal(1, "DMA_STATUS.BUSY should be deasserted after completion!");
        $display("[PASS] Test 4: Transfer completed. irq_dma_done asserted, BUSY cleared.");

        // Test 5: Clear DONE flag (W1C)
        axi_write(32'h14, 32'h02);
        axi_read(32'h14, rdata);
        if (rdata[1]) $fatal(1, "DMA_STATUS.DONE should be cleared!");
        if (irq_dma_done) $fatal(1, "irq_dma_done should deassert after clearing DONE!");
        $display("[PASS] Test 5: W1C clear of DMA_STATUS.DONE verified.");

        $display("==========================================================");
        $display(" ALL DMA CONTROLLER TESTS PASSED SUCCESSFULLY!            ");
        $display("==========================================================");
        $finish;
    end

endmodule
