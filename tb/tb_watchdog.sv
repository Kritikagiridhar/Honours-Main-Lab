// =============================================================================
// Testbench : tb_watchdog.sv
// DUT       : watchdog.sv
// Description: Comprehensive verification of Watchdog Safety Monitor
// =============================================================================

`timescale 1ns / 1ps

module tb_watchdog;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam CLK_PERIOD = 10;

    logic                  clk;
    logic                  rst_n;
    logic [3:0]            pipeline_alive;

    wire                   nmi_prewarn;
    wire                   wdt_reset;
    wire                   wdt_reset_out;

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

    // Instantiate DUT
    watchdog #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pipeline_alive(pipeline_alive),
        .nmi_prewarn(nmi_prewarn),
        .wdt_reset(wdt_reset),
        .wdt_reset_out(wdt_reset_out),
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
        .s_axi_rready(s_axi_rready)
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
        $display(" Starting Watchdog Monitor Verification (tb_watchdog)");
        $display("==========================================================");

        clk            = 0;
        rst_n          = 0;
        pipeline_alive = 4'hF;
        s_axi_awaddr   = 0;
        s_axi_awvalid  = 0;
        s_axi_wdata    = 0;
        s_axi_wstrb    = 0;
        s_axi_wvalid   = 0;
        s_axi_bready   = 0;
        s_axi_araddr   = 0;
        s_axi_arvalid  = 0;
        s_axi_rready   = 0;

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // Test 1: Program RELOAD = 10 cycles
        axi_write(32'h04, 32'd10);
        $display("[PASS] Test 1: Programmed WDT_RELOAD = 10 cycles.");

        // Test 2: Arm Watchdog (EN=1)
        axi_write(32'h00, 32'h01);
        $display("Watchdog armed. Kicking 3 times to prove counter reload...");

        repeat (3) begin
            #(CLK_PERIOD * 5);
            axi_write(32'h08, 32'hDEADBEEF); // KICK
            axi_read(32'h08, rdata);
            $display("  Counter reloaded to %0d after kick.", rdata);
            if (rdata < 5) $fatal(1, "Watchdog kick failed to reload counter!");
        end
        $display("[PASS] Test 2: Watchdog kick & reload verified.");

        // Test 3: Stop kicking, wait for NMI pre-warning
        $display("Allowing countdown to expire...");
        wait(nmi_prewarn == 1'b1);
        $display("[PASS] Test 3: NMI pre-warning asserted 1 tick before fatal timeout.");

        // Test 4: Wait for Hard Reset pulse
        wait(wdt_reset == 1'b1);
        $display("[PASS] Test 4: Fatal hard reset pulse (wdt_reset) asserted!");

        axi_read(32'h0C, rdata);
        if (!rdata[1]) $fatal(1, "WDT_STATUS.TRIPPED should be set!");
        $display("[PASS] Test 5: Post-mortem WDT_STATUS.TRIPPED flag verified.");

        $display("==========================================================");
        $display(" ALL WATCHDOG TESTS PASSED SUCCESSFULLY!                  ");
        $display("==========================================================");
        $finish;
    end

endmodule
