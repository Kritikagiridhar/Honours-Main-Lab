// =============================================================================
// Testbench : tb_gpio.sv
// DUT       : gpio.sv
// Description: Comprehensive verification of GPIO Controller with AXI4-Lite CSRs
// =============================================================================

`timescale 1ns / 1ps

module tb_gpio;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam CLK_PERIOD = 10;

    logic                  clk;
    logic                  rst_n;

    logic [7:0]            gpio_in;
    wire  [7:0]            gpio_out;

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

    wire                   irq_gpio;

    // Instantiate DUT
    gpio #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
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
        .irq_gpio(irq_gpio)
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
        $display(" Starting GPIO IP Verification (tb_gpio)");
        $display("==========================================================");

        clk           = 0;
        rst_n         = 0;
        gpio_in       = 8'h00;
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

        // Test 1: Drive Output LEDs
        axi_write(32'h04, 32'hA5);
        #(CLK_PERIOD);
        if (gpio_out != 8'hA5) $fatal(1, "Mismatch in gpio_out!");
        $display("[PASS] Test 1: GPIO output drive verified (8'hA5).");

        // Test 2: Synchronized Input Read
        gpio_in = 8'h5A;
        #(CLK_PERIOD * 4); // Double-flop sync delay
        axi_read(32'h00, rdata);
        if (rdata[7:0] != 8'h5A) $fatal(1, "Mismatch in GPIO_IN read!");
        $display("[PASS] Test 2: Synchronized GPIO input read verified (8'h5A).");

        // Test 3: Enable Change Interrupt for bit 0
        axi_write(32'h08, 32'h01); // CHANGE_EN = 1 for bit 0

        // Toggle bit 0 of input
        gpio_in[0] = 1'b1;
        #(CLK_PERIOD * 5);

        if (!irq_gpio) $fatal(1, "irq_gpio should be asserted on input change!");
        axi_read(32'h0C, rdata);
        if (!rdata[0]) $fatal(1, "GPIO_STATUS.CHANGED should be set!");
        $display("[PASS] Test 3: Input edge detection & irq_gpio assertion verified.");

        // Test 4: Clear CHANGED flag (W1C)
        axi_write(32'h0C, 32'h01);
        axi_read(32'h0C, rdata);
        if (rdata[0] != 1'b0) $fatal(1, "GPIO_STATUS.CHANGED should be cleared!");
        if (irq_gpio != 1'b0) $fatal(1, "irq_gpio should be deasserted after clear!");
        $display("[PASS] Test 4: W1C clear of GPIO_STATUS.CHANGED verified.");

        $display("==========================================================");
        $display(" ALL GPIO TESTS PASSED SUCCESSFULLY!                      ");
        $display("==========================================================");
        $finish;
    end

endmodule
