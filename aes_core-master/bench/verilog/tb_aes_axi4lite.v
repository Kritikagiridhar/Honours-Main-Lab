
`timescale 1ns / 10ps

module tb_aes_axi4lite;

    // ============================================================
    // CLOCK AND RESET
    // ============================================================
    reg ACLK;
    reg ARESETn;

    initial begin
        ACLK = 1'b0;
        forever #5 ACLK = ~ACLK;
    end

    initial begin
        ARESETn = 1'b0;
        #100;
        ARESETn = 1'b1;
    end

    // ============================================================
    // AXI4-LITE WRITE ADDRESS CHANNEL
    // ============================================================
    reg  [5:0] AWADDR;
    reg        AWVALID;
    wire       AWREADY;

    // ============================================================
    // AXI4-LITE WRITE DATA CHANNEL
    // ============================================================
    reg  [31:0] WDATA;
    reg  [3:0]  WSTRB;
    reg         WVALID;
    wire        WREADY;

    // ============================================================
    // AXI4-LITE WRITE RESPONSE CHANNEL
    // ============================================================
    wire [1:0] BRESP;
    wire       BVALID;
    reg        BREADY;

    // ============================================================
    // AXI4-LITE READ ADDRESS CHANNEL
    // ============================================================
    reg  [5:0] ARADDR;
    reg        ARVALID;
    wire       ARREADY;

    // ============================================================
    // AXI4-LITE READ DATA CHANNEL
    // ============================================================
    wire [31:0] RDATA;
    wire [1:0]  RRESP;
    wire        RVALID;
    reg         RREADY;

    // ============================================================
    // DUT
    // ============================================================
    aes_axi4lite_slave dut (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        .AWADDR  (AWADDR),
        .AWVALID (AWVALID),
        .AWREADY (AWREADY),

        .WDATA   (WDATA),
        .WSTRB   (WSTRB),
        .WVALID  (WVALID),
        .WREADY  (WREADY),

        .BRESP   (BRESP),
        .BVALID  (BVALID),
        .BREADY  (BREADY),

        .ARADDR  (ARADDR),
        .ARVALID (ARVALID),
        .ARREADY (ARREADY),

        .RDATA   (RDATA),
        .RRESP   (RRESP),
        .RVALID  (RVALID),
        .RREADY  (RREADY)
    );

    // ============================================================
    // AXI WRITE TASK
    // ============================================================
    task axi_write;
        input [5:0]  addr;
        input [31:0] data;

        begin

            // Present address and data
            @(posedge ACLK);

            AWADDR  = addr;
            AWVALID = 1'b1;

            WDATA   = data;
            WSTRB   = 4'b1111;
            WVALID  = 1'b1;

            BREADY  = 1'b1;

            // Wait for address handshake
            while (AWREADY !== 1'b1)
                @(posedge ACLK);

            @(posedge ACLK);
            AWVALID = 1'b0;

            // Wait for data handshake
            while (WREADY !== 1'b1)
                @(posedge ACLK);

            @(posedge ACLK);
            WVALID = 1'b0;
            WSTRB  = 4'b0000;

            // Wait for write response
            while (BVALID !== 1'b1)
                @(posedge ACLK);

            @(posedge ACLK);
            BREADY = 1'b0;

        end
    endtask

    // ============================================================
    // AXI READ TASK
    // ============================================================
    task axi_read;
        input  [5:0]  addr;
        output [31:0] data;

        begin

            @(posedge ACLK);

            ARADDR  = addr;
            ARVALID = 1'b1;
            RREADY  = 1'b1;

            // Wait for address handshake
            while (ARREADY !== 1'b1)
                @(posedge ACLK);

            @(posedge ACLK);
            ARVALID = 1'b0;

            // Wait for read response
            while (RVALID !== 1'b1)
                @(posedge ACLK);

            data = RDATA;

            @(posedge ACLK);
            RREADY = 1'b0;

        end
    endtask

    // ============================================================
    // TEST VARIABLES
    // ============================================================
    reg [31:0] read_data;

    // ============================================================
    // MAIN TEST
    // ============================================================
    initial begin

        // Initial AXI values
        AWADDR  = 6'h00;
        AWVALID = 1'b0;

        WDATA   = 32'h00000000;
        WSTRB   = 4'h0;
        WVALID  = 1'b0;

        BREADY  = 1'b0;

        ARADDR  = 6'h00;
        ARVALID = 1'b0;
        RREADY  = 1'b0;

        // Wait for reset release
        @(posedge ARESETn);
        repeat (2) @(posedge ACLK);

        $display("");
        $display("*****************************************************");
        $display("*        AES AXI4-LITE SLAVE TESTBENCH              *");
        $display("*****************************************************");

        // ========================================================
        // WRITE AES KEY
        // ========================================================

        $display("[INFO] Writing AES key:");
        $display("       000102030405060708090A0B0C0D0E0F");

        $display("[DEBUG] KEY0");
        axi_write(6'h00, 32'h00010203);

        $display("[DEBUG] KEY1");
        axi_write(6'h04, 32'h04050607);

        $display("[DEBUG] KEY2");
        axi_write(6'h08, 32'h08090A0B);

        $display("[DEBUG] KEY3");
        axi_write(6'h0C, 32'h0C0D0E0F);

        // ========================================================
        // WRITE PLAINTEXT
        // ========================================================

        $display("[INFO] Writing plaintext:");
        $display("       00112233445566778899AABBCCDDEEFF");

        $display("[DEBUG] TEXT0");
        axi_write(6'h10, 32'h00112233);

        $display("[DEBUG] TEXT1");
        axi_write(6'h14, 32'h44556677);

        $display("[DEBUG] TEXT2");
        axi_write(6'h18, 32'h8899AABB);

        $display("[DEBUG] TEXT3");
        axi_write(6'h1C, 32'hCCDDEEFF);

        // ========================================================
        // START AES
        // ========================================================

        $display("[INFO] Starting AES encryption");

        axi_write(6'h20, 32'h00000001);

        // ========================================================
        // WAIT FOR AES DONE
        // ========================================================

        $display("[INFO] Waiting for AES completion");

        while (1) begin

            axi_read(6'h24, read_data);

            $display("[DEBUG] STATUS = %08h", read_data);

            if (read_data[0] == 1'b1)
                break;

        end

        $display("[INFO] AES DONE detected");

        // ========================================================
        // READ OUTPUT WORD 0
        // ========================================================

        axi_read(6'h28, read_data);

        $display("[RESULT] OUT0 = %08h", read_data);

        if (read_data !== 32'h69C4E0D8) begin
            $display("[ERROR] OUT0 mismatch");
            $display("[ERROR] Expected: 69C4E0D8");
            $display("[ERROR] Received: %08h", read_data);
            $finish;
        end

        // ========================================================
        // READ OUTPUT WORD 1
        // ========================================================

        axi_read(6'h2C, read_data);

        $display("[RESULT] OUT1 = %08h", read_data);

        if (read_data !== 32'h6A7B0430) begin
            $display("[ERROR] OUT1 mismatch");
            $display("[ERROR] Expected: 6A7B0430");
            $display("[ERROR] Received: %08h", read_data);
            $finish;
        end

        // ========================================================
        // READ OUTPUT WORD 2
        // ========================================================

        axi_read(6'h30, read_data);

        $display("[RESULT] OUT2 = %08h", read_data);

        if (read_data !== 32'hD8CDB780) begin
            $display("[ERROR] OUT2 mismatch");
            $display("[ERROR] Expected: D8CDB780");
            $display("[ERROR] Received: %08h", read_data);
            $finish;
        end

        // ========================================================
        // READ OUTPUT WORD 3
        // ========================================================

        axi_read(6'h34, read_data);

        $display("[RESULT] OUT3 = %08h", read_data);

        if (read_data !== 32'h70B4C55A) begin
            $display("[ERROR] OUT3 mismatch");
            $display("[ERROR] Expected: 70B4C55A");
            $display("[ERROR] Received: %08h", read_data);
            $finish;
        end

        // ========================================================
        // FINAL PASS
        // ========================================================

        $display("");
        $display("*****************************************************");
        $display("*                 AES TEST PASSED                   *");
        $display("*                                                   *");
        $display("* Ciphertext: 69C4E0D86A7B0430D8CDB78070B4C55A    *");
        $display("*                                                   *");
        $display("*****************************************************");
        $display("");

        #20;
        $finish;

    end

    // ============================================================
    // OPTIONAL FSDB WAVES
    // Compile with +define+WAVES to enable
    // ============================================================
`ifdef WAVES
    initial begin
        $fsdbDumpfile("axi_dump.fsdb");
        $fsdbDumpvars("+all");
    end
`endif

endmodule

