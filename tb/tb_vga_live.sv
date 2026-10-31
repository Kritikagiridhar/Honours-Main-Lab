// =============================================================================
// File       : tb_vga_live.sv
// Description: Live 640x480 VGA Oscilloscope Testbench hooked to VGA Simulator
// =============================================================================

`timescale 1ns / 1ps

module tb_vga_live;

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

    // Instantiate VGA Controller DUT
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

    // Instantiate Live VGA Monitor Hook
    vga_live_monitor u_vga_monitor (
        .clk_vga  (clk_vga),
        .rst_n    (rst_vga_n),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red  (vga_red),
        .vga_green(vga_green),
        .vga_blue (vga_blue)
    );

    // Clocks
    always #5  clk_sys = ~clk_sys; // 100 MHz
    always #20 clk_vga = ~clk_vga; // 25 MHz pixel clock

    // Synthetic Sine Wave Test Signal into Sample Buffer
    always @(posedge clk_vga) begin
        // Amplitude ~80 pixels, centered around 0
        sbuf_rdata <= $rtoi(80.0 * $sin(sbuf_raddr * 6.2831853 / 200.0));
    end

    // AXI-Lite Write Task
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
        // Optional FSDB dump for Verdi
        if ($test$plusargs("FSDB") || $test$plusargs("fsdb")) begin
            $fsdbDumpfile("dump.fsdb");
            $fsdbDumpvars(0, tb_vga_live, "+all", "+mda");
        end

        $display("==========================================================");
        $display(" Starting Live VGA Simulation (tb_vga_live)               ");
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

        // Configure VGA Controller:
        // 0x00: CTRL: Enable display (bit 0), Grid (bit 2) -> 0x5
        axi_write(32'h00, 32'h05);

        // 0x20: Trace Color: Bright Lime Green (0x0F0)
        axi_write(32'h20, 32'h00F0);

        // 0x24: Grid Color: Dim Cyan (0x145)
        axi_write(32'h24, 32'h0145);

        // 0x28: BG Color: Dark Navy (0x002)
        axi_write(32'h28, 32'h0002);

        // 0x2C: Cursor A at Y = 160
        axi_write(32'h2C, 32'd160);

        // 0x30: Cursor B at Y = 320
        axi_write(32'h30, 32'd320);

        // 0x34: Cursor Color: Bright Yellow (0xFF0)
        axi_write(32'h34, 32'h0FF0);

        // 0x38: Enable Cursor A (bit 0), Cursor B (bit 1), Thick Trace (bit 2) -> 0x7
        axi_write(32'h38, 32'h07);

        $display("[INFO] VGA Controller configured:");
        $display("       - Display: ENABLED");
        $display("       - Grid: ENABLED (Cyan 0x145)");
        $display("       - Trace: Sine Wave, Thick (Lime 0x0F0)");
        $display("       - Cursors: Y=160, Y=320 (Yellow 0xFF0)");

        $display("[INFO] Waiting for full VGA frame scan (525 lines @ 800 pixels/line)...");

        // Wait for first VSYNC pulse to align to start of frame
        @(negedge vga_vsync);
        @(posedge vga_vsync);
        $display("[INFO] Frame 1 scan started.");

        // Wait for next VSYNC pulse indicating full frame completion
        @(negedge vga_vsync);
        @(posedge vga_vsync);
        $display("[INFO] Frame 1 scan completed and captured.");

        // Wait an additional 200 clocks to ensure frame flush
        repeat (200) @(posedge clk_vga);

        $display("==========================================================");
        $display(" LIVE VGA SIMULATION SUCCESSFUL!                          ");
        $display(" Frame captured to 'vga_live_frame.bmp' & 'vga_live_frame.ppm'");
        $display("==========================================================");
        $finish;
    end

endmodule
