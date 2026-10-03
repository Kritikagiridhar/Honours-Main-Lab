`timescale 1ns / 10ps

module aes_axi4lite_slave (
    input  wire        ACLK,
    input  wire        ARESETn,

    input  wire [5:0]  AWADDR,
    input  wire        AWVALID,
    output wire        AWREADY,

    input  wire [31:0] WDATA,
    input  wire [3:0]  WSTRB,
    input  wire        WVALID,
    output wire        WREADY,

    output reg  [1:0]  BRESP,
    output reg         BVALID,
    input  wire        BREADY,

    input  wire [5:0]  ARADDR,
    input  wire        ARVALID,
    output wire        ARREADY,

    output reg  [31:0] RDATA,
    output reg  [1:0]  RRESP,
    output reg         RVALID,
    input  wire         RREADY
);

localparam [5:0] KEY0   = 6'h00;
localparam [5:0] KEY1   = 6'h04;
localparam [5:0] KEY2   = 6'h08;
localparam [5:0] KEY3   = 6'h0C;

localparam [5:0] TEXT0  = 6'h10;
localparam [5:0] TEXT1  = 6'h14;
localparam [5:0] TEXT2  = 6'h18;
localparam [5:0] TEXT3  = 6'h1C;

localparam [5:0] CTRL   = 6'h20;
localparam [5:0] STATUS = 6'h24;

localparam [5:0] OUT0   = 6'h28;
localparam [5:0] OUT1   = 6'h2C;
localparam [5:0] OUT2   = 6'h30;
localparam [5:0] OUT3   = 6'h34;

reg [31:0] key0_reg, key1_reg, key2_reg, key3_reg;
reg [31:0] text0_reg, text1_reg, text2_reg, text3_reg;

reg [31:0] out0_reg, out1_reg, out2_reg, out3_reg;

reg [5:0]  awaddr_reg;
reg [31:0] wdata_reg;
reg [3:0]  wstrb_reg;

reg aw_pending;
reg w_pending;

reg busy;
reg done_sticky;
reg aes_ld;

wire aes_done;
wire [127:0] aes_text_out;

wire [127:0] aes_key =
    {key0_reg, key1_reg, key2_reg, key3_reg};

wire [127:0] aes_text_in =
    {text0_reg, text1_reg, text2_reg, text3_reg};

wire write_fire =
    aw_pending && w_pending && !BVALID;

assign AWREADY = !aw_pending && !BVALID;
assign WREADY  = !w_pending  && !BVALID;
assign ARREADY = !RVALID;

function [31:0] merge_wstrb;
    input [31:0] old_data;
    input [31:0] new_data;
    input [3:0]  strb;

    begin
        merge_wstrb = old_data;

        if (strb[0])
            merge_wstrb[7:0] = new_data[7:0];

        if (strb[1])
            merge_wstrb[15:8] = new_data[15:8];

        if (strb[2])
            merge_wstrb[23:16] = new_data[23:16];

        if (strb[3])
            merge_wstrb[31:24] = new_data[31:24];
    end
endfunction

reg [31:0] read_data;

always @(*) begin

    case (ARADDR)

        STATUS:
            read_data = {30'b0, busy, done_sticky};

        OUT0:
            read_data = out0_reg;

        OUT1:
            read_data = out1_reg;

        OUT2:
            read_data = out2_reg;

        OUT3:
            read_data = out3_reg;

        default:
            read_data = 32'h00000000;

    endcase

end

aes_cipher_top aes_core (
    .clk      (ACLK),
    .rst      (ARESETn),
    .ld       (aes_ld),
    .done     (aes_done),
    .key      (aes_key),
    .text_in  (aes_text_in),
    .text_out (aes_text_out)
);

always @(posedge ACLK) begin

    if (!ARESETn) begin

        key0_reg  <= 32'h0;
        key1_reg  <= 32'h0;
        key2_reg  <= 32'h0;
        key3_reg  <= 32'h0;

        text0_reg <= 32'h0;
        text1_reg <= 32'h0;
        text2_reg <= 32'h0;
        text3_reg <= 32'h0;

        out0_reg <= 32'h0;
        out1_reg <= 32'h0;
        out2_reg <= 32'h0;
        out3_reg <= 32'h0;

        awaddr_reg <= 6'h0;
        wdata_reg  <= 32'h0;
        wstrb_reg  <= 4'h0;

        aw_pending <= 1'b0;
        w_pending  <= 1'b0;

        busy       <= 1'b0;
        done_sticky <= 1'b0;
        aes_ld     <= 1'b0;

        BVALID <= 1'b0;
        BRESP  <= 2'b00;

        RVALID <= 1'b0;
        RRESP  <= 2'b00;
        RDATA  <= 32'h0;

    end

    else begin

        aes_ld <= 1'b0;

        if (AWVALID && AWREADY) begin
            awaddr_reg <= AWADDR;
            aw_pending <= 1'b1;
        end

        if (WVALID && WREADY) begin
            wdata_reg <= WDATA;
            wstrb_reg <= WSTRB;
            w_pending <= 1'b1;
        end

        if (write_fire) begin

            case (awaddr_reg)

                KEY0:
                    key0_reg <= merge_wstrb(
                        key0_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                KEY1:
                    key1_reg <= merge_wstrb(
                        key1_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                KEY2:
                    key2_reg <= merge_wstrb(
                        key2_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                KEY3:
                    key3_reg <= merge_wstrb(
                        key3_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                TEXT0:
                    text0_reg <= merge_wstrb(
                        text0_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                TEXT1:
                    text1_reg <= merge_wstrb(
                        text1_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                TEXT2:
                    text2_reg <= merge_wstrb(
                        text2_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                TEXT3:
                    text3_reg <= merge_wstrb(
                        text3_reg,
                        wdata_reg,
                        wstrb_reg
                    );

                CTRL: begin

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

            aw_pending <= 1'b0;
            w_pending  <= 1'b0;

            BRESP  <= 2'b00;
            BVALID <= 1'b1;

        end

        if (BVALID && BREADY)
            BVALID <= 1'b0;

        if (aes_done) begin

            out0_reg <= aes_text_out[127:96];
            out1_reg <= aes_text_out[95:64];
            out2_reg <= aes_text_out[63:32];
            out3_reg <= aes_text_out[31:0];

            done_sticky <= 1'b1;
            busy        <= 1'b0;

        end

        if (ARVALID && ARREADY) begin

            RDATA  <= read_data;
            RRESP  <= 2'b00;
            RVALID <= 1'b1;

        end

        if (RVALID && RREADY)
            RVALID <= 1'b0;

    end

end

endmodule
