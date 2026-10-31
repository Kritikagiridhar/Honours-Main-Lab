// =============================================================================
// Module      : axi_ram.sv
// Description : Parameterized 32-bit AXI4 Synchronous SRAM
//               Supports single-beat and burst (INCR) transfers,
//               byte-write enables (wstrb), and optional hex initialization.
// =============================================================================

`resetall
`timescale 1ns / 1ps
`default_nettype none

module axi_ram #(
    parameter DATA_WIDTH       = 32,
    parameter ADDR_WIDTH       = 32,
    parameter STRB_WIDTH       = (DATA_WIDTH / 8),
    parameter ID_WIDTH         = 8,
    parameter DEPTH            = 16384,            // 16384 words * 4 bytes = 64 KB
    parameter MEM_ADDR_WIDTH   = 14,               // $clog2(DEPTH)
    parameter INIT_FILE        = ""
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // -------------------------------------------------------------------------
    // AXI4 Slave Interface
    // -------------------------------------------------------------------------
    input  wire [ID_WIDTH-1:0]       s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [7:0]                s_axi_awlen,
    input  wire [2:0]                s_axi_awsize,
    input  wire [1:0]                s_axi_awburst,
    input  wire                      s_axi_awlock,
    input  wire [3:0]                s_axi_awcache,
    input  wire [2:0]                s_axi_awprot,
    input  wire [3:0]                s_axi_awqos,
    input  wire [3:0]                s_axi_awregion,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]     s_axi_wstrb,
    input  wire                      s_axi_wlast,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    output reg  [ID_WIDTH-1:0]       s_axi_bid,
    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    input  wire [ID_WIDTH-1:0]       s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire [7:0]                s_axi_arlen,
    input  wire [2:0]                s_axi_arsize,
    input  wire [1:0]                s_axi_arburst,
    input  wire                      s_axi_arlock,
    input  wire [3:0]                s_axi_arcache,
    input  wire [2:0]                s_axi_arprot,
    input  wire [3:0]                s_axi_arqos,
    input  wire [3:0]                s_axi_arregion,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    output reg  [ID_WIDTH-1:0]       s_axi_rid,
    output reg  [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rlast,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready
);

    // Memory array
    reg [7:0] mem_0 [0:DEPTH-1];
    reg [7:0] mem_1 [0:DEPTH-1];
    reg [7:0] mem_2 [0:DEPTH-1];
    reg [7:0] mem_3 [0:DEPTH-1];

    // Optional Hex initialization
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem_0);
        end
    end

    // -------------------------------------------------------------------------
    // Write Channel
    // -------------------------------------------------------------------------
    reg [ID_WIDTH-1:0]       wr_id_q;
    reg [MEM_ADDR_WIDTH-1:0] wr_addr_q;
    reg [7:0]                wr_len_q;
    reg                      wr_busy_q;

    wire [MEM_ADDR_WIDTH-1:0] aw_word_addr = s_axi_awaddr[MEM_ADDR_WIDTH+1:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b1;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            s_axi_bresp   <= 2'b00;
            wr_busy_q     <= 1'b0;
            wr_addr_q     <= {MEM_ADDR_WIDTH{1'b0}};
            wr_len_q      <= 8'd0;
            wr_id_q       <= {ID_WIDTH{1'b0}};
        end else begin
            // Accept write address
            if (s_axi_awvalid && s_axi_awready) begin
                wr_id_q       <= s_axi_awid;
                wr_addr_q     <= aw_word_addr;
                wr_len_q      <= s_axi_awlen;
                wr_busy_q     <= 1'b1;
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b1;
            end

            // Accept write data beats
            if (s_axi_wvalid && s_axi_wready) begin
                if (s_axi_wstrb[0]) mem_0[wr_addr_q] <= s_axi_wdata[7:0];
                if (s_axi_wstrb[1]) mem_1[wr_addr_q] <= s_axi_wdata[15:8];
                if (s_axi_wstrb[2]) mem_2[wr_addr_q] <= s_axi_wdata[23:16];
                if (s_axi_wstrb[3]) mem_3[wr_addr_q] <= s_axi_wdata[31:24];

                wr_addr_q <= wr_addr_q + 1'b1;

                if (s_axi_wlast || wr_len_q == 8'd0) begin
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b1;
                    s_axi_bid    <= wr_id_q;
                    s_axi_bresp  <= 2'b00; // OKAY
                    wr_busy_q    <= 1'b0;
                end else begin
                    wr_len_q <= wr_len_q - 1'b1;
                end
            end

            // Clear write response
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid  <= 1'b0;
                s_axi_awready <= 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read Channel (Burst / Single Beat)
    // -------------------------------------------------------------------------
    reg [ID_WIDTH-1:0]       rd_id_q;
    reg [MEM_ADDR_WIDTH-1:0] rd_addr_q;
    reg [7:0]                rd_len_q;
    reg                      rd_busy_q;

    wire [MEM_ADDR_WIDTH-1:0] ar_word_addr = s_axi_araddr[MEM_ADDR_WIDTH+1:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b0;
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rlast   <= 1'b0;
            rd_busy_q     <= 1'b0;
            rd_addr_q     <= {MEM_ADDR_WIDTH{1'b0}};
            rd_len_q      <= 8'd0;
            rd_id_q       <= {ID_WIDTH{1'b0}};
        end else begin
            // Address handshake
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_arready <= 1'b0;
                rd_id_q       <= s_axi_arid;
                rd_addr_q     <= ar_word_addr + 1'b1;
                rd_len_q      <= s_axi_arlen;
                rd_busy_q     <= 1'b1;

                // First beat response
                s_axi_rvalid  <= 1'b1;
                s_axi_rid     <= s_axi_arid;
                s_axi_rresp   <= 2'b00; // OKAY
                s_axi_rdata   <= {mem_3[ar_word_addr], mem_2[ar_word_addr], mem_1[ar_word_addr], mem_0[ar_word_addr]};
                s_axi_rlast   <= (s_axi_arlen == 8'd0);
            end else if (s_axi_rvalid && s_axi_rready) begin
                if (rd_len_q > 8'd0) begin
                    // Subsequent burst beats
                    s_axi_rvalid <= 1'b1;
                    s_axi_rid    <= rd_id_q;
                    s_axi_rresp  <= 2'b00;
                    s_axi_rdata  <= {mem_3[rd_addr_q], mem_2[rd_addr_q], mem_1[rd_addr_q], mem_0[rd_addr_q]};
                    s_axi_rlast  <= (rd_len_q == 8'd1);
                    rd_addr_q    <= rd_addr_q + 1'b1;
                    rd_len_q     <= rd_len_q - 1'b1;
                end else begin
                    // Burst complete
                    s_axi_rvalid  <= 1'b0;
                    s_axi_rlast   <= 1'b0;
                    rd_busy_q     <= 1'b0;
                    s_axi_arready <= 1'b1;
                end
            end
        end
    end

endmodule

`resetall
