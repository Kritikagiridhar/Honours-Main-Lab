// =============================================================================
// Testbench : tb_fir_filter.sv
// DUT       : fir_filter.sv
// Description: Comprehensive verification of 16-Tap FIR Filter with Q1.15 MAC
// =============================================================================

`timescale 1ns / 1ps

module tb_fir_filter;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam CLK_PERIOD = 10;

    logic                  clk;
    logic                  rst_n;

    logic signed [15:0]    fir_sample_in;
    logic                  fir_sample_valid_in;
    wire  signed [15:0]    fir_sample_out;
    wire                   fir_sample_valid_out;

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

    wire                   irq_fir;

    // Instantiate DUT
    fir_filter #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_TAPS(16)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .fir_sample_in(fir_sample_in),
        .fir_sample_valid_in(fir_sample_valid_in),
        .fir_sample_out(fir_sample_out),
        .fir_sample_valid_out(fir_sample_valid_out),
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
        .irq_fir(irq_fir)
    );

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
        $display("==========================================================");
        $display(" Starting FIR Filter IP Verification (tb_fir_filter)");
        $display("==========================================================");

        clk                 = 0;
        rst_n               = 0;
        fir_sample_in       = 0;
        fir_sample_valid_in = 0;
        s_axi_awaddr        = 0;
        s_axi_awvalid       = 0;
        s_axi_wdata         = 0;
        s_axi_wstrb         = 0;
        s_axi_wvalid        = 0;
        s_axi_bready        = 0;
        s_axi_araddr        = 0;
        s_axi_arvalid       = 0;
        s_axi_rready        = 0;

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // Test 1: Verify Default Bypass Mode (BYPASS=1 at reset)
        fir_sample_in       <= 16'sd12345;
        fir_sample_valid_in <= 1'b1;
        @(posedge clk);
        fir_sample_valid_in <= 1'b0;
        @(posedge clk);

        if (fir_sample_out != 16'sd12345) $fatal(1, "Bypass mode sample mismatch!");
        $display("[PASS] Test 1: Hardware Bypass Mode verified (Sample: %0d).", fir_sample_out);

        // Test 2: Program 4-Tap Moving Average Filter
        // Coeff = 0.25 in Q1.15: 0.25 * 32768 = 8192 (16'h2000)
        axi_write(32'h04, 32'd4); // NTAPS = 4
        axi_write(32'h08, 32'h2000); // COEF0
        axi_write(32'h0C, 32'h2000); // COEF1
        axi_write(32'h10, 32'h2000); // COEF2
        axi_write(32'h14, 32'h2000); // COEF3 (Triggers COEF_LOAD_DONE)

        axi_read(32'h48, rdata);
        if (!rdata[0]) $fatal(1, "FIR_STATUS.COEF_LOAD_DONE should be set!");
        $display("[PASS] Test 2: Programmed 4 taps (0.25 each) and verified COEF_LOAD_DONE.");

        // Clear COEF_LOAD_DONE (W1C)
        axi_write(32'h48, 32'd1);

        // Test 3: Enable Filter Pipeline (EN=1, BYPASS=0 => CTRL=0x1)
        axi_write(32'h00, 32'h01);

        // Feed Step Input: Sample = 16000
        $display("Streaming 4 samples of value 16000 into active filter...");
        repeat (4) begin
            @(posedge clk);
            fir_sample_in       <= 16'sd16000;
            fir_sample_valid_in <= 1'b1;
            @(posedge clk);
            fir_sample_valid_in <= 1'b0;
            @(posedge clk);
            $display("  Sample Output: %0d", fir_sample_out);
        end

        // After 4 samples of 16000, 4-tap average of 0.25*16000 * 4 = 16000
        if (fir_sample_out < 16'sd15500 || fir_sample_out > 16'sd16500) begin
            $fatal(1, "Filter step response mismatch! Expected ~16000, got %0d", fir_sample_out);
        end
        $display("[PASS] Test 3: 4-Tap Moving Average MAC convergence verified (~16000).");

        $display("==========================================================");
        $display(" ALL FIR FILTER TESTS PASSED SUCCESSFULLY!                ");
        $display("==========================================================");
        $finish;
    end

endmodule
