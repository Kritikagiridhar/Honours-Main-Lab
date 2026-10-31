// =============================================================================
// Testbench : tb_sample_buffer.sv
// DUT       : sample_buffer.sv
// Description: Multi-clock asynchronous verification of Dual-Port Sample Buffer
// =============================================================================

`timescale 1ns / 1ps

module tb_sample_buffer;

    localparam ADDR_WIDTH     = 32;
    localparam DATA_WIDTH     = 32;
    localparam BUF_ADDR_WIDTH = 12;

    // Clocks
    logic clk_sys; // 100 MHz (10 ns)
    logic rst_sys_n;
    logic clk_vga; // 25 MHz (40 ns)
    logic rst_vga_n;

    // DMA Write Port
    logic [BUF_ADDR_WIDTH-1:0] sbuf_waddr;
    logic [15:0]               sbuf_wdata;
    logic                      sbuf_we;

    // VGA Read Port
    logic [BUF_ADDR_WIDTH-1:0] sbuf_raddr;
    wire  [15:0]               sbuf_rdata;

    // AXI4-Lite Read Port
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

    // Instantiate DUT
    sample_buffer #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BUFFER_DEPTH(4096),
        .BUF_ADDR_WIDTH(BUF_ADDR_WIDTH)
    ) dut (
        .clk_sys(clk_sys),
        .rst_sys_n(rst_sys_n),
        .sbuf_waddr(sbuf_waddr),
        .sbuf_wdata(sbuf_wdata),
        .sbuf_we(sbuf_we),
        .clk_vga(clk_vga),
        .rst_vga_n(rst_vga_n),
        .sbuf_raddr(sbuf_raddr),
        .sbuf_rdata(sbuf_rdata),
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

    // Clock Generators
    always #5  clk_sys = ~clk_sys; // 100 MHz
    always #20 clk_vga = ~clk_vga; // 25 MHz

    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
        @(posedge clk_sys);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1'b1;
        s_axi_rready  <= 1'b1;

        wait(s_axi_arready);
        @(posedge clk_sys);
        s_axi_arvalid <= 1'b0;

        wait(s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge clk_sys);
        s_axi_rready <= 1'b0;
    endtask

    initial begin
        logic [DATA_WIDTH-1:0] rdata;
        integer i;
        $display("==========================================================");
        $display(" Starting Sample Buffer Verification (tb_sample_buffer)");
        $display("==========================================================");

        clk_sys       = 0;
        rst_sys_n     = 0;
        clk_vga       = 0;
        rst_vga_n     = 0;
        sbuf_waddr    = 0;
        sbuf_wdata    = 0;
        sbuf_we       = 0;
        sbuf_raddr    = 0;
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

        // Test 1: Write 16 samples via DMA port on clk_sys
        $display("Writing 16 test samples via DMA port...");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk_sys);
            sbuf_waddr <= i[BUF_ADDR_WIDTH-1:0];
            sbuf_wdata <= 16'h1000 + i;
            sbuf_we    <= 1'b1;
        end
        @(posedge clk_sys);
        sbuf_we <= 1'b0;
        $display("[PASS] Test 1: DMA write burst completed.");

        // Test 2: Read back from VGA Port on clk_vga domain
        $display("Reading back samples from VGA port on clk_vga (25 MHz)...");
        for (i = 0; i < 16; i = i + 1) begin
            sbuf_raddr = i[BUF_ADDR_WIDTH-1:0];
            @(posedge clk_vga);
            #1; // Sample after synchronous RAM read
            if (sbuf_rdata != (16'h1000 + i)) begin
                $fatal(1, "VGA read mismatch at index %0d! Got %h, expected %h", i, sbuf_rdata, 16'h1000+i);
            end
        end
        $display("[PASS] Test 2: Asynchronous VGA read port verified.");

        // Test 3: Read back via AXI4-Lite slave port (CPU measurement path DP5)
        $display("Reading back samples via AXI4-Lite CPU read port...");
        for (i = 0; i < 16; i = i + 1) begin
            axi_read((i << 1), rdata);
            if (rdata[15:0] != (16'h1000 + i)) begin
                $fatal(1, "AXI read mismatch at index %0d! Got %h, expected %h", i, rdata[15:0], 16'h1000+i);
            end
        end
        $display("[PASS] Test 3: AXI4-Lite DP5 measurement read-back verified.");

        $display("==========================================================");
        $display(" ALL SAMPLE BUFFER TESTS PASSED SUCCESSFULLY!             ");
        $display("==========================================================");
        $finish;
    end

endmodule
