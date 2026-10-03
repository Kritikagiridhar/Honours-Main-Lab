`timescale 1ns/1ps

module axi_aes_tb;

    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg resetn;

    reg        awid;
    reg [5:0]  awaddr;
    reg [7:0]  awlen;
    reg [2:0]  awsize;
    reg [1:0]  awburst;
    reg        awvalid;
    wire       awready;

    reg [31:0] wdata;
    reg [3:0]  wstrb;
    reg        wlast;
    reg        wvalid;
    wire       wready;

    wire       bid;
    wire [1:0] bresp;
    wire       bvalid;
    reg        bready;

    reg        arid;
    reg [5:0]  araddr;
    reg [7:0]  arlen;
    reg [2:0]  arsize;
    reg [1:0]  arburst;
    reg        arvalid;
    wire       arready;

    wire       rid;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rlast;
    wire        rvalid;
    reg         rready;

    integer errors;
    reg [31:0] rd;
    reg [127:0] result;

    localparam CONTROL = 6'h00;
    localparam STATUS  = 6'h04;
    localparam KEY0    = 6'h10;
    localparam KEY1    = 6'h14;
    localparam KEY2    = 6'h18;
    localparam KEY3    = 6'h1C;
    localparam IN0     = 6'h20;
    localparam IN1     = 6'h24;
    localparam IN2     = 6'h28;
    localparam IN3     = 6'h2C;
    localparam OUT0    = 6'h30;
    localparam OUT1    = 6'h34;
    localparam OUT2    = 6'h38;
    localparam OUT3    = 6'h3C;

    axi_aes_top dut (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(resetn),

        .S_AXI_AWID(awid), .S_AXI_AWADDR(awaddr), .S_AXI_AWLEN(awlen),
        .S_AXI_AWSIZE(awsize), .S_AXI_AWBURST(awburst),
        .S_AXI_AWVALID(awvalid), .S_AXI_AWREADY(awready),

        .S_AXI_WDATA(wdata), .S_AXI_WSTRB(wstrb), .S_AXI_WLAST(wlast),
        .S_AXI_WVALID(wvalid), .S_AXI_WREADY(wready),

        .S_AXI_BID(bid), .S_AXI_BRESP(bresp), .S_AXI_BVALID(bvalid),
        .S_AXI_BREADY(bready),

        .S_AXI_ARID(arid), .S_AXI_ARADDR(araddr), .S_AXI_ARLEN(arlen),
        .S_AXI_ARSIZE(arsize), .S_AXI_ARBURST(arburst),
        .S_AXI_ARVALID(arvalid), .S_AXI_ARREADY(arready),

        .S_AXI_RID(rid), .S_AXI_RDATA(rdata), .S_AXI_RRESP(rresp),
        .S_AXI_RLAST(rlast), .S_AXI_RVALID(rvalid), .S_AXI_RREADY(rready)
    );

    task axi_write;
        input [5:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            awid=0; awaddr=addr; awlen=0; awsize=3'b010; awburst=2'b01;
            awvalid=1; wdata=data; wstrb=4'hF; wlast=1; wvalid=1;
            while (!(awready && wready)) @(posedge clk);
            @(posedge clk);
            awvalid=0; wvalid=0;
            while (!bvalid) @(posedge clk);
            bready=1;
            @(posedge clk);
            bready=0;
            if (bresp !== 2'b00) begin
                $display("AXI WRITE ERROR addr=%h resp=%b", addr, bresp);
                errors = errors + 1;
            end
        end
    endtask

    task axi_read;
        input [5:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            arid=0; araddr=addr; arlen=0; arsize=3'b010; arburst=2'b01;
            arvalid=1;
            while (!arready) @(posedge clk);
            @(posedge clk);
            arvalid=0;
            while (!rvalid) @(posedge clk);
            data = rdata;
            rready=1;
            @(posedge clk);
            rready=0;
            if (rresp !== 2'b00) begin
                $display("AXI READ ERROR addr=%h resp=%b", addr, rresp);
                errors = errors + 1;
            end
        end
    endtask

    task wait_done;
        integer i;
        reg [31:0] status;
        begin
            for (i=0; i<100; i=i+1) begin
                axi_read(STATUS, status);
                if (status[1]) begin
                    $display("AES DONE at cycle %0d", i);
                    disable wait_done;
                end
            end
            $display("TIMEOUT waiting for AES DONE");
            errors = errors + 1;
        end
    endtask

    initial begin
        errors = 0;
        resetn = 0;
        awid=0; awaddr=0; awlen=0; awsize=0; awburst=0; awvalid=0;
        wdata=0; wstrb=0; wlast=0; wvalid=0; bready=0;
        arid=0; araddr=0; arlen=0; arsize=0; arburst=0; arvalid=0; rready=0;

        repeat (5) @(posedge clk);
        resetn = 1;
        repeat (2) @(posedge clk);

        $display("==============================================");
        $display(" AXI4-Lite AES-128 ENCRYPTION TEST");
        $display("==============================================");

        // Key = 000102030405060708090A0B0C0D0E0F
        axi_write(KEY0, 32'h0C0D0E0F);
        axi_write(KEY1, 32'h08090A0B);
        axi_write(KEY2, 32'h04050607);
        axi_write(KEY3, 32'h00010203);

        // Plaintext = 00112233445566778899AABBCCDDEEFF
        axi_write(IN0, 32'hCCDDEEFF);
        axi_write(IN1, 32'h8899AABB);
        axi_write(IN2, 32'h44556677);
        axi_write(IN3, 32'h00112233);

        // Encryption: MODE=0, START=1
        axi_write(CONTROL, 32'h00000001);

        wait_done;

        axi_read(OUT0, rd); result[31:0]   = rd;
        axi_read(OUT1, rd); result[63:32]  = rd;
        axi_read(OUT2, rd); result[95:64]  = rd;
        axi_read(OUT3, rd); result[127:96] = rd;

        $display("Ciphertext = %h", result);
        if (result !== 128'h69C4E0D86A7B0430D8CDB78070B4C55A) begin
            $display("ENCRYPTION FAIL");
            errors = errors + 1;
        end else
            $display("ENCRYPTION PASS");

        $display("==============================================");
        $display(" AXI4-Lite AES-128 DECRYPTION TEST");
        $display("==============================================");

        // Input ciphertext, same key; MODE=1, START=1
        axi_write(IN0, 32'h70B4C55A);
        axi_write(IN1, 32'hD8CDB780);
        axi_write(IN2, 32'h6A7B0430);
        axi_write(IN3, 32'h69C4E0D8);

        axi_write(CONTROL, 32'h00000003);

        wait_done;

        axi_read(OUT0, rd); result[31:0]   = rd;
        axi_read(OUT1, rd); result[63:32]  = rd;
        axi_read(OUT2, rd); result[95:64]  = rd;
        axi_read(OUT3, rd); result[127:96] = rd;

        $display("Plaintext  = %h", result);
        if (result !== 128'h00112233445566778899AABBCCDDEEFF) begin
            $display("DECRYPTION FAIL");
            errors = errors + 1;
        end else
            $display("DECRYPTION PASS");

        $display("==============================================");
        if (errors == 0)
            $display("ALL AXI AES TESTS PASSED - 0 ERRORS");
        else
            $display("TEST FAILED - %0d ERRORS", errors);
        $display("==============================================");

        #20;
        $finish;
    end

	initial begin
		$fsdbDumpfile("dump.fsdb");
		$fsdbDumpvars("+all");
		$fsdbDumpSVA();
		$fsdbDumpMDA();
	end

endmodule
