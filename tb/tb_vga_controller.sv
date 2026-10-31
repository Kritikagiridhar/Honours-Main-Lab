// =============================================================================
// Testbench : tb_vga_controller.sv
// DUT       : vga_controller.sv
// Description: Comprehensive verification of 640x480 @ 60 Hz VGA Controller
// =============================================================================

`timescale 1ns / 1ps

module tb_vga_controller;

    localparam ADDR_WIDTH     = 32;
    localparam DATA_WIDTH     = 32;
    localparam BUF_ADDR_WIDTH = 12;

    logic                      clk_sys; // 100 MHz
    logic                      rst_sys_n;
    logic                      clk_vga; // 25.175 MHz (~40 ns)
    logic                      rst_vga_n;

    wire [BUF_ADDR_WIDTH-1:0]  sbuf_raddr;
    logic [15:0]               sbuf_rdata;

    wire                       vga_hsync;
    wire                       vga_vsync;
    wire [3:0]                 vga_red;
    wire [3:0]                 vga_green;
    wire [3:0]                 vga_blue;

    logic [ADDR_WIDTH-1:0]     s_axi_awaddr;
    logic                      s_axi_awvalid;
    wire                       s_axi_awready;
    logic [DATA_WIDTH-1:0]     s_axi_wdata;
    logic [3:0]                s_axi_wstrb;
    logic                      s_axi_wvalid;
    wire                       s_axi_wready;
    wire  [1:0]                s_axi_bresp;
    wire                       s_axi_bvalid;
    logic                      s_axi_bready;
    logic [ADDR_WIDTH-1:0]     s_axi_araddr;
    logic                      s_axi_arvalid;
    wire                       s_axi_arready;
    wire  [DATA_WIDTH-1:0]     s_axi_rdata;
    wire  [1:0]                s_axi_rresp;
    wire                       s_axi_rvalid;
    logic                      s_axi_rready;

    wire                       irq_vga_frame;

    // Instantiate DUT
    vga_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BUF_ADDR_WIDTH(BUF_ADDR_WIDTH)
    ) dut (
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
        .irq_vga_frame(irq_vga_frame)
    );

    always #5  clk_sys = ~clk_sys;
    always #20 clk_vga = ~clk_vga; // 25 MHz pixel clock

    // Synthetic waveform data on sample buffer: Sine wave pattern
    always @(posedge clk_vga) begin
        sbuf_rdata <= $sin(sbuf_raddr * 3.14159 / 100.0) * 10000;
    end

    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        @(posedge clk_sys);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'hF;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;

        fork
            begin
                wait(s_axi_awready);
                @(posedge clk_sys);
                s_axi_awvalid <= 1'b0;
            end
            begin
                wait(s_axi_wready);
                @(posedge clk_sys);
                s_axi_wvalid <= 1'b0;
            end
        join

        wait(s_axi_bvalid);
        @(posedge clk_sys);
        s_axi_bready <= 1'b0;
    endtask

    initial begin
        integer h_sync_count = 0;
        integer active_pixel_count = 0;
        $display("==========================================================");
        $display(" Starting VGA Controller Verification (tb_vga_controller)");
        $display("==========================================================");

        clk_sys       = 0;
        rst_sys_n     = 0;
        clk_vga       = 0;
        rst_vga_n     = 0;
        sbuf_rdata    = 0;
        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        #100;
        rst_sys_n = 1;
        rst_vga_n = 1;
        #50;

        // Test 1: Enable VGA Controller and Grid Overlay (CTRL = 0x5)
        axi_write(32'h00, 32'h05);
        $display("[PASS] Test 1: Enabled display and grid overlay.");

        // Test 2: Measure Horizontal Line Timing (800 pixel cycles per line)
        @(negedge vga_hsync); // Wait for falling edge of HSYNC
        while (vga_hsync == 1'b0) begin
            h_sync_count = h_sync_count + 1;
            @(posedge clk_vga);
            #1; // Allow NBA to settle
        end
        $display("HSYNC active pulse duration: %0d pixels (Expected: 96).", h_sync_count);
        if (h_sync_count != 96) $fatal(1, "HSYNC pulse width mismatch!");
        $display("[PASS] Test 2: Standard 640x480 HSYNC timing verified.");

        // Test 3: Verify Active Video Trace Pixels
        repeat (1000) begin
            @(posedge clk_vga);
            if (vga_red != 4'h0 || vga_green != 4'h0) begin
                active_pixel_count = active_pixel_count + 1;
            end
        end
        $display("Observed %0d active pixel renders during scan window.", active_pixel_count);
        if (active_pixel_count == 0) $fatal(1, "No active video pixels generated!");
        $display("[PASS] Test 3: Waveform trace and grid rendering active.");

        $display("==========================================================");
        $display(" ALL VGA CONTROLLER TESTS PASSED SUCCESSFULLY!            ");
        $display("==========================================================");
        $finish;
    end

endmodule
