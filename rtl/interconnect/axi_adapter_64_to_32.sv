/*
 * AXI4 64-bit to 32-bit Width Down-Converter Adapter
 *
 * Connects a 64-bit AXI4 Master (e.g., VeeR EL2 RISC-V Core LSU/IFU)
 * to a 32-bit AXI4 Interconnect / Slave.
 *
 * Supports:
 * - Single-beat 32-bit, 16-bit, and 8-bit read/write accesses (size <= 2)
 *   with proper sub-word byte routing based on address[2].
 * - 64-bit transfers (size == 3): splits each 64-bit beat into two
 *   sequential 32-bit beats (lower 32 bits at addr, upper 32 bits at addr+4).
 * - Multi-beat bursts (INCR).
 * - Full AXI ID, response (bresp/rresp), and handshake tracking.
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

module axi_adapter_64_to_32 #
(
    parameter ADDR_WIDTH      = 32,
    parameter ID_WIDTH        = 8,
    parameter AWUSER_ENABLE   = 0,
    parameter AWUSER_WIDTH    = 1,
    parameter WUSER_ENABLE    = 0,
    parameter WUSER_WIDTH     = 1,
    parameter BUSER_ENABLE    = 0,
    parameter BUSER_WIDTH     = 1,
    parameter ARUSER_ENABLE   = 0,
    parameter ARUSER_WIDTH    = 1,
    parameter RUSER_ENABLE    = 0,
    parameter RUSER_WIDTH     = 1
)
(
    input  wire                      clk,
    input  wire                      rst,

    // =========================================================================
    // Slave Interface (64-bit Data, connects to Master)
    // =========================================================================
    // Write Address Channel
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
    input  wire [AWUSER_WIDTH-1:0]   s_axi_awuser,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,

    // Write Data Channel
    input  wire [63:0]               s_axi_wdata,
    input  wire [7:0]                s_axi_wstrb,
    input  wire                      s_axi_wlast,
    input  wire [WUSER_WIDTH-1:0]    s_axi_wuser,
    input  wire                      s_axi_wvalid,
    output wire                      s_axi_wready,

    // Write Response Channel
    output wire [ID_WIDTH-1:0]       s_axi_bid,
    output wire [1:0]                s_axi_bresp,
    output wire [BUSER_WIDTH-1:0]    s_axi_buser,
    output wire                      s_axi_bvalid,
    input  wire                      s_axi_bready,

    // Read Address Channel
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
    input  wire [ARUSER_WIDTH-1:0]   s_axi_aruser,
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,

    // Read Data Channel
    output wire [ID_WIDTH-1:0]       s_axi_rid,
    output wire [63:0]               s_axi_rdata,
    output wire [1:0]                s_axi_rresp,
    output wire                      s_axi_rlast,
    output wire [RUSER_WIDTH-1:0]    s_axi_ruser,
    output wire                      s_axi_rvalid,
    input  wire                      s_axi_rready,

    // =========================================================================
    // Master Interface (32-bit Data, connects to Interconnect / Slave)
    // =========================================================================
    // Write Address Channel
    output wire [ID_WIDTH-1:0]       m_axi_awid,
    output wire [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output wire [7:0]                m_axi_awlen,
    output wire [2:0]                m_axi_awsize,
    output wire [1:0]                m_axi_awburst,
    output wire                      m_axi_awlock,
    output wire [3:0]                m_axi_awcache,
    output wire [2:0]                m_axi_awprot,
    output wire [3:0]                m_axi_awqos,
    output wire [3:0]                m_axi_awregion,
    output wire [AWUSER_WIDTH-1:0]   m_axi_awuser,
    output wire                      m_axi_awvalid,
    input  wire                      m_axi_awready,

    // Write Data Channel
    output wire [31:0]               m_axi_wdata,
    output wire [3:0]                m_axi_wstrb,
    output wire                      m_axi_wlast,
    output wire [WUSER_WIDTH-1:0]    m_axi_wuser,
    output wire                      m_axi_wvalid,
    input  wire                      m_axi_wready,

    // Write Response Channel
    input  wire [ID_WIDTH-1:0]       m_axi_bid,
    input  wire [1:0]                m_axi_bresp,
    input  wire [BUSER_WIDTH-1:0]    m_axi_buser,
    input  wire                      m_axi_bvalid,
    output wire                      m_axi_bready,

    // Read Address Channel
    output wire [ID_WIDTH-1:0]       m_axi_arid,
    output wire [ADDR_WIDTH-1:0]     m_axi_araddr,
    output wire [7:0]                m_axi_arlen,
    output wire [2:0]                m_axi_arsize,
    output wire [1:0]                m_axi_arburst,
    output wire                      m_axi_arlock,
    output wire [3:0]                m_axi_arcache,
    output wire [2:0]                m_axi_arprot,
    output wire [3:0]                m_axi_arqos,
    output wire [3:0]                m_axi_arregion,
    output wire [ARUSER_WIDTH-1:0]   m_axi_aruser,
    output wire                      m_axi_arvalid,
    input  wire                      m_axi_arready,

    // Read Data Channel
    input  wire [ID_WIDTH-1:0]       m_axi_rid,
    input  wire [31:0]               m_axi_rdata,
    input  wire [1:0]                m_axi_rresp,
    input  wire                      m_axi_rlast,
    input  wire [RUSER_WIDTH-1:0]    m_axi_ruser,
    input  wire                      m_axi_rvalid,
    output wire                      m_axi_rready
);

    // =========================================================================
    // 1. Write Address Channel
    // =========================================================================
    wire aw_is_64 = (s_axi_awsize == 3'b011);

    // If master requested 64-bit access, double the burst length:
    // new_len = (orig_len + 1) * 2 - 1 = orig_len * 2 + 1
    wire [7:0] awlen_converted = aw_is_64 ? ({s_axi_awlen[6:0], 1'b1}) : s_axi_awlen;
    wire [2:0] awsize_converted = aw_is_64 ? 3'b010 : s_axi_awsize;

    assign m_axi_awid       = s_axi_awid;
    assign m_axi_awaddr     = s_axi_awaddr;
    assign m_axi_awlen      = awlen_converted;
    assign m_axi_awsize     = awsize_converted;
    assign m_axi_awburst    = s_axi_awburst;
    assign m_axi_awlock     = s_axi_awlock;
    assign m_axi_awcache    = s_axi_awcache;
    assign m_axi_awprot     = s_axi_awprot;
    assign m_axi_awqos      = s_axi_awqos;
    assign m_axi_awregion   = s_axi_awregion;
    assign m_axi_awuser     = s_axi_awuser;
    assign m_axi_awvalid    = s_axi_awvalid;
    assign s_axi_awready    = m_axi_awready;

    // Track write transaction attributes
    reg wr_is_64_reg;
    reg wr_addr_bit2_reg;
    reg wr_in_progress;
    reg wr_second_half;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_is_64_reg     <= 1'b0;
            wr_addr_bit2_reg <= 1'b0;
            wr_in_progress   <= 1'b0;
            wr_second_half   <= 1'b0;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                wr_is_64_reg     <= aw_is_64;
                wr_addr_bit2_reg <= s_axi_awaddr[2];
                wr_in_progress   <= 1'b1;
                wr_second_half   <= 1'b0;
            end else if (m_axi_wvalid && m_axi_wready && m_axi_wlast) begin
                wr_in_progress   <= 1'b0;
                wr_second_half   <= 1'b0;
            end else if (wr_is_64_reg && m_axi_wvalid && m_axi_wready) begin
                wr_second_half   <= ~wr_second_half;
            end
        end
    end

    // =========================================================================
    // 2. Write Data Channel
    // =========================================================================
    // Determine active half for <=32-bit transfer
    wire wr_subword_hi = wr_in_progress ? wr_addr_bit2_reg : s_axi_awaddr[2];

    reg [31:0] wdata_mux;
    reg [3:0]  wstrb_mux;
    reg        wlast_mux;
    reg        s_wready_val;

    always @(*) begin
        if (wr_is_64_reg) begin
            if (!wr_second_half) begin
                // First half (lower 32 bits)
                wdata_mux    = s_axi_wdata[31:0];
                wstrb_mux    = s_axi_wstrb[3:0];
                wlast_mux    = 1'b0;
                s_wready_val = 1'b0; // Wait for second half before completing slave handshake
            end else begin
                // Second half (upper 32 bits)
                wdata_mux    = s_axi_wdata[63:32];
                wstrb_mux    = s_axi_wstrb[7:4];
                wlast_mux    = s_axi_wlast;
                s_wready_val = m_axi_wready;
            end
        end else begin
            // Single 32-bit or sub-word access
            if (wr_subword_hi) begin
                wdata_mux    = s_axi_wdata[63:32];
                wstrb_mux    = s_axi_wstrb[7:4];
            end else begin
                wdata_mux    = s_axi_wdata[31:0];
                wstrb_mux    = s_axi_wstrb[3:0];
            end
            wlast_mux    = s_axi_wlast;
            s_wready_val = m_axi_wready;
        end
    end

    assign m_axi_wdata  = wdata_mux;
    assign m_axi_wstrb  = wstrb_mux;
    assign m_axi_wlast  = wlast_mux;
    assign m_axi_wuser  = s_axi_wuser;
    assign m_axi_wvalid = s_axi_wvalid;
    assign s_axi_wready = s_wready_val;

    // =========================================================================
    // 3. Write Response Channel
    // =========================================================================
    assign s_axi_bid    = m_axi_bid;
    assign s_axi_bresp  = m_axi_bresp;
    assign s_axi_buser  = m_axi_buser;
    assign s_axi_bvalid = m_axi_bvalid;
    assign m_axi_bready = s_axi_bready;

    // =========================================================================
    // 4. Read Address Channel
    // =========================================================================
    wire ar_is_64 = (s_axi_arsize == 3'b011);

    wire [7:0] arlen_converted = ar_is_64 ? ({s_axi_arlen[6:0], 1'b1}) : s_axi_arlen;
    wire [2:0] arsize_converted = ar_is_64 ? 3'b010 : s_axi_arsize;

    assign m_axi_arid     = s_axi_arid;
    assign m_axi_araddr   = s_axi_araddr;
    assign m_axi_arlen    = arlen_converted;
    assign m_axi_arsize   = arsize_converted;
    assign m_axi_arburst  = s_axi_arburst;
    assign m_axi_arlock   = s_axi_arlock;
    assign m_axi_arcache  = s_axi_arcache;
    assign m_axi_arprot   = s_axi_arprot;
    assign m_axi_arqos    = s_axi_arqos;
    assign m_axi_arregion = s_axi_arregion;
    assign m_axi_aruser   = s_axi_aruser;
    assign m_axi_arvalid  = s_axi_arvalid;
    assign s_axi_arready  = m_axi_arready;

    // Track read transaction attributes
    reg rd_is_64_reg;
    reg rd_second_half;
    reg [31:0] rd_data_lo_reg;
    reg [1:0]  rd_resp_lo_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_is_64_reg   <= 1'b0;
            rd_second_half <= 1'b0;
            rd_data_lo_reg <= 32'd0;
            rd_resp_lo_reg <= 2'b00;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                rd_is_64_reg   <= ar_is_64;
                rd_second_half <= 1'b0;
            end else if (rd_is_64_reg && m_axi_rvalid) begin
                if (!rd_second_half) begin
                    // Latch lower 32-bit word
                    rd_data_lo_reg <= m_axi_rdata;
                    rd_resp_lo_reg <= m_axi_rresp;
                    rd_second_half <= 1'b1;
                end else if (s_axi_rready) begin
                    // Upper half consumed
                    rd_second_half <= 1'b0;
                end
            end
        end
    end

    // =========================================================================
    // 5. Read Data Channel
    // =========================================================================
    reg [63:0] rdata_mux;
    reg [1:0]  rresp_mux;
    reg        rvalid_mux;
    reg        rlast_mux;
    reg        m_rready_mux;

    always @(*) begin
        if (rd_is_64_reg) begin
            if (!rd_second_half) begin
                // Waiting for second half, do not assert s_axi_rvalid yet
                rdata_mux    = 64'd0;
                rresp_mux    = 2'b00;
                rvalid_mux   = 1'b0;
                rlast_mux    = 1'b0;
                m_rready_mux = 1'b1; // Always accept lower beat into internal register
            end else begin
                // Both halves ready: form 64-bit word
                rdata_mux    = {m_axi_rdata, rd_data_lo_reg};
                rresp_mux    = (m_axi_rresp != 2'b00) ? m_axi_rresp : rd_resp_lo_reg;
                rvalid_mux   = m_axi_rvalid;
                rlast_mux    = m_axi_rlast;
                m_rready_mux = s_axi_rready;
            end
        end else begin
            // Replicate 32-bit data to both halves so CPU gets correct data
            // regardless of whether it samples lower or upper word based on addr[2]
            rdata_mux    = {m_axi_rdata, m_axi_rdata};
            rresp_mux    = m_axi_rresp;
            rvalid_mux   = m_axi_rvalid;
            rlast_mux    = m_axi_rlast;
            m_rready_mux = s_axi_rready;
        end
    end

    assign s_axi_rid    = m_axi_rid;
    assign s_axi_rdata  = rdata_mux;
    assign s_axi_rresp  = rresp_mux;
    assign s_axi_rlast  = rlast_mux;
    assign s_axi_ruser  = m_axi_ruser;
    assign s_axi_rvalid = rvalid_mux;
    assign m_axi_rready = m_rready_mux;

endmodule

`resetall
