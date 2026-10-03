
`timescale 1ns / 10ps

module aes_axi4lite_slave (
    input  wire        ACLK,
    input  wire        ARESETn,

    // AXI WRITE ADDRESS
    input  wire [5:0]  AWADDR,
    input  wire        AWVALID,
    output wire        AWREADY,

    // AXI WRITE DATA
    input  wire [31:0] WDATA,
    input  wire [3:0]  WSTRB,
    input  wire        WVALID,
    output wire        WREADY,

    // AXI WRITE RESPONSE
    output reg  [1:0]  BRESP,
    output reg         BVALID,
    input  wire        BREADY,

    // AXI READ ADDRESS
    input  wire [5:0]  ARADDR,
    input  wire        ARVALID,
    output wire        ARREADY,

    // AXI READ DATA
    output reg  [31:0] RDATA,
    output reg  [1:0]  RRESP,
    output reg         RVALID,
    input  wire        RREADY
);

    // ============================================================
    // REGISTER MAP
    // ============================================================

    localparam [5:0] ADDR_KEY0   = 6'h00;
    localparam [5:0] ADDR_KEY1   = 6'h04;
    localparam [5:0] ADDR_KEY2   = 6'h08;
    localparam [5:0] ADDR_KEY3   = 6'h0C;

    localparam [5:0] ADDR_TEXT0  = 6'h10;
    localparam [5:0] ADDR_TEXT1  = 6'h14;
    localparam [5:0] ADDR_TEXT2  = 6'h18;
    localparam [5:0] ADDR_TEXT3  = 6'h1C;

    localparam [5:0] ADDR_CTRL   = 6'h20;
    localparam [5:0] ADDR_STATUS = 6'h24;

    localparam [5:0] ADDR_OUT0   = 6'h28;
    localparam [5:0] ADDR_OUT1   = 6'h2C;
    localparam [5:0] ADDR_OUT2   = 6'h30;
    localparam [5:0] ADDR_OUT3   = 6'h34;

    // ============================================================
    // AES REGISTERS
    // ============================================================

    reg [31:0] key0;
    reg [31:0] key1;
    reg [31:0] key2;
    reg [31:0] key3;

    reg [31:0] text0;
    reg [31:0] text1;
    reg [31:0] text2;
    reg [31:0] text3;

    reg [31:0] out0;
    reg [31:0] out1;
    reg [31:0] out2;
    reg [31:0] out3;

    // ============================================================
    // AXI WRITE STORAGE
    // ============================================================

    reg [5:0]  awaddr_reg;
    reg        awaddr_valid;

    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;
    reg        wdata_valid;

    // ============================================================
    // STATUS
    // ============================================================

    reg busy;
    reg done_sticky;

    // ============================================================
    // AES SIGNALS
    // ============================================================

    reg         aes_ld;
    wire        aes_done;
    wire [127:0] aes_text_out;

    wire [127:0] aes_key;
    wire [127:0] aes_text_in;

    assign aes_key =
        {key0, key1, key2, key3};

    assign aes_text_in =
        {text0, text1, text2, text3};

    // ============================================================
    // AXI READY SIGNALS
    //
    // READY is combinational.
    // This prevents the deadlock seen with the previous wrapper.
    // ============================================================

    assign AWREADY = !awaddr_valid && !BVALID;

    assign WREADY  = !wdata_valid && !BVALID;

    assign ARREADY = !RVALID;

    // ============================================================
    // WSTRB MERGE FUNCTION
    // ============================================================

    function [31:0] merge_wstrb;
        input [31:0] old_value;
        input [31:0] new_value;
        input [3:0]  strb;

        begin

            merge_wstrb = old_value;

            if (strb[0])
                merge_wstrb[7:0] = new_value[7:0];

            if (strb[1])
                merge_wstrb[15:8] = new_value[15:8];

            if (strb[2])
                merge_wstrb[23:16] = new_value[23:16];

            if (strb[3])
                merge_wstrb[31:24] = new_value[31:24];

        end
    endfunction

    // ============================================================
    // AES CORE
    // ORIGINAL AES CORE IS NOT MODIFIED
    // ============================================================

    aes_cipher_top u_aes_core (
        .clk      (ACLK),
        .rst      (ARESETn),
        .ld       (aes_ld),
        .done     (aes_done),
        .key      (aes_key),
        .text_in  (aes_text_in),
        .text_out (aes_text_out)
    );

    // ============================================================
    // MAIN SEQUENTIAL LOGIC
    // ============================================================

    always @(posedge ACLK) begin

        if (!ARESETn) begin

            // ----------------------------------------------------
            // RESET REGISTERS
            // ----------------------------------------------------

            key0 <= 32'h00000000;
            key1 <= 32'h00000000;
            key2 <= 32'h00000000;
            key3 <= 32'h00000000;

            text0 <= 32'h00000000;
            text1 <= 32'h00000000;
            text2 <= 32'h00000000;
            text3 <= 32'h00000000;

            out0 <= 32'h00000000;
            out1 <= 32'h00000000;
            out2 <= 32'h00000000;
            out3 <= 32'h00000000;

            awaddr_reg   <= 6'h00;
            awaddr_valid <= 1'b0;

            wdata_reg    <= 32'h00000000;
            wstrb_reg    <= 4'h0;
            wdata_valid  <= 1'b0;

            BVALID <= 1'b0;
            BRESP  <= 2'b00;

            RVALID <= 1'b0;
            RDATA  <= 32'h00000000;
            RRESP  <= 2'b00;

            busy        <= 1'b0;
            done_sticky <= 1'b0;

            aes_ld <= 1'b0;

        end
        else begin

            // ----------------------------------------------------
            // AES START PULSE DEFAULT
            // ----------------------------------------------------

            aes_ld <= 1'b0;

            // ----------------------------------------------------
            // CAPTURE WRITE ADDRESS
            // ----------------------------------------------------

            if (AWVALID && AWREADY) begin

                awaddr_reg   <= AWADDR;
                awaddr_valid <= 1'b1;

            end

            // ----------------------------------------------------
            // CAPTURE WRITE DATA
            // ----------------------------------------------------

            if (WVALID && WREADY) begin

                wdata_reg   <= WDATA;
                wstrb_reg   <= WSTRB;
                wdata_valid <= 1'b1;

            end

            // ----------------------------------------------------
            // COMPLETE WRITE WHEN BOTH ADDRESS AND DATA EXIST
            // ----------------------------------------------------

            if (awaddr_valid &&
                wdata_valid &&
                !BVALID) begin

                case (awaddr_reg)

                    // ------------------------------------------------
                    // AES KEY
                    // ------------------------------------------------

                    ADDR_KEY0:
                        key0 <= merge_wstrb(
                            key0,
                            wdata_reg,
                            wstrb_reg
                        );

                    ADDR_KEY1:
                        key1 <= merge_wstrb(
                            key1,
                            wdata_reg,
                            wstrb_reg
                        );

                    ADDR_KEY2:
                        key2 <= merge_wstrb(
                            key2,
                            wdata_reg,
                            wstrb_reg
                        );

                    ADDR_KEY3:
                        key3 <= merge_wstrb(
                            key3,
                            wdata_reg,
                            wstrb_reg
                        );

                    // ------------------------------------------------
                    // AES PLAINTEXT
                    // ------------------------------------------------

                    ADDR_TEXT0:
                        text0 <= merge_wstrb(
                            text0,
                            wdata_reg,
                            wstrb_reg
                        );

                    ADDR_TEXT1:
                        text1 <= merge_wstrb(
                            text1,
                            wdata_reg,
                            wstrb_reg
                        );

                    ADDR_TEXT2:
                        text2 <= merge_wstrb(
                            text2,
                            wdata_reg,
                            wstrb_reg
                        );

                    ADDR_TEXT3:
                        text3 <= merge_wstrb(
                            text3,
                            wdata_reg,
                            wstrb_reg
                        );

                    // ------------------------------------------------
                    // CONTROL REGISTER
                    // ------------------------------------------------

                    ADDR_CTRL: begin

                        if (wstrb_reg[0] &&
                            wdata_reg[0] &&
                            !busy) begin

                            aes_ld      <= 1'b1;
                            busy        <= 1'b1;
                            done_sticky <= 1'b0;

                        end

                    end

                    default: begin
                    end

                endcase

                // Clear pending write
                awaddr_valid <= 1'b0;
                wdata_valid  <= 1'b0;

                // Generate AXI OKAY response
                BVALID <= 1'b1;
                BRESP  <= 2'b00;

            end

            // ----------------------------------------------------
            // WRITE RESPONSE HANDSHAKE
            // ----------------------------------------------------

            if (BVALID && BREADY) begin

                BVALID <= 1'b0;

            end

            // ----------------------------------------------------
            // AES DONE
            // ----------------------------------------------------

            if (aes_done) begin

                out0 <= aes_text_out[127:96];
                out1 <= aes_text_out[95:64];
                out2 <= aes_text_out[63:32];
                out3 <= aes_text_out[31:0];

                busy        <= 1'b0;
                done_sticky <= 1'b1;

            end

            // ----------------------------------------------------
            // READ ADDRESS + READ DATA
            // ----------------------------------------------------

            if (ARVALID && ARREADY) begin

                case (ARADDR)

                    ADDR_STATUS:
                        RDATA <= {
                            30'b0,
                            busy,
                            done_sticky
                        };

                    ADDR_OUT0:
                        RDATA <= out0;

                    ADDR_OUT1:
                        RDATA <= out1;

                    ADDR_OUT2:
                        RDATA <= out2;

                    ADDR_OUT3:
                        RDATA <= out3;

                    default:
                        RDATA <= 32'h00000000;

                endcase

                RRESP  <= 2'b00;
                RVALID <= 1'b1;

            end

            // ----------------------------------------------------
            // READ RESPONSE HANDSHAKE
            // ----------------------------------------------------

            if (RVALID && RREADY) begin

                RVALID <= 1'b0;

            end

        end

    end

endmodule

