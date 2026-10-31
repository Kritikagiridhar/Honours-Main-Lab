// =============================================================================
// Module      : axi4_to_axil_lite.sv
// Description : Protocol bridge from AXI4 Full to AXI4-Lite
//               Supports single-beat 32-bit register read/write transactions,
//               ID forwarding/reflection, and status signal management.
// =============================================================================

`resetall
`timescale 1ns / 1ps
`default_nettype none

module axi4_to_axil_lite #(
    parameter DATA_WIDTH       = 32,
    parameter ADDR_WIDTH       = 32,
    parameter STRB_WIDTH       = (DATA_WIDTH / 8),
    parameter ID_WIDTH         = 8,
    parameter AWUSER_WIDTH     = 1,
    parameter WUSER_WIDTH      = 1,
    parameter BUSER_WIDTH      = 1,
    parameter ARUSER_WIDTH     = 1,
    parameter RUSER_WIDTH      = 1
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // -------------------------------------------------------------------------
    // AXI4 Full Slave Interface (from Interconnect Master Port)
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
    input  wire [AWUSER_WIDTH-1:0]   s_axi_awuser,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]     s_axi_wstrb,
    input  wire                      s_axi_wlast,
    input  wire [WUSER_WIDTH-1:0]    s_axi_wuser,
    input  wire                      s_axi_wvalid,
    output wire                      s_axi_wready,

    output wire [ID_WIDTH-1:0]       s_axi_bid,
    output wire [1:0]                s_axi_bresp,
    output wire [BUSER_WIDTH-1:0]    s_axi_buser,
    output wire                      s_axi_bvalid,
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
    input  wire [ARUSER_WIDTH-1:0]   s_axi_aruser,
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,

    output wire [ID_WIDTH-1:0]       s_axi_rid,
    output wire [DATA_WIDTH-1:0]     s_axi_rdata,
    output wire [1:0]                s_axi_rresp,
    output wire                      s_axi_rlast,
    output wire [RUSER_WIDTH-1:0]    s_axi_ruser,
    output wire                      s_axi_rvalid,
    input  wire                      s_axi_rready,

    // -------------------------------------------------------------------------
    // AXI4-Lite Master Interface (to Peripheral IP Core)
    // -------------------------------------------------------------------------
    output wire [ADDR_WIDTH-1:0]     m_axil_awaddr,
    output wire                      m_axil_awvalid,
    input  wire                      m_axil_awready,

    output wire [DATA_WIDTH-1:0]     m_axil_wdata,
    output wire [STRB_WIDTH-1:0]     m_axil_wstrb,
    output wire                      m_axil_wvalid,
    input  wire                      m_axil_wready,

    input  wire [1:0]                m_axil_bresp,
    input  wire                      m_axil_bvalid,
    output wire                      m_axil_bready,

    output wire [ADDR_WIDTH-1:0]     m_axil_araddr,
    output wire                      m_axil_arvalid,
    input  wire                      m_axil_arready,

    input  wire [DATA_WIDTH-1:0]     m_axil_rdata,
    input  wire [1:0]                m_axil_rresp,
    input  wire                      m_axil_rvalid,
    output wire                      m_axil_rready
);

    // -------------------------------------------------------------------------
    // Write Channel Handshake & ID Tracking
    // -------------------------------------------------------------------------
    reg [ID_WIDTH-1:0] awid_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awid_q <= {ID_WIDTH{1'b0}};
        end else if (s_axi_awvalid && s_axi_awready) begin
            awid_q <= s_axi_awid;
        end
    end

    assign m_axil_awaddr  = s_axi_awaddr;
    assign m_axil_awvalid = s_axi_awvalid;
    assign s_axi_awready  = m_axil_awready;

    assign m_axil_wdata   = s_axi_wdata;
    assign m_axil_wstrb   = s_axi_wstrb;
    assign m_axil_wvalid  = s_axi_wvalid;
    assign s_axi_wready   = m_axil_wready;

    assign s_axi_bvalid   = m_axil_bvalid;
    assign m_axil_bready  = s_axi_bready;
    assign s_axi_bresp    = m_axil_bresp;
    assign s_axi_bid      = awid_q;
    assign s_axi_buser    = {BUSER_WIDTH{1'b0}};

    // -------------------------------------------------------------------------
    // Read Channel Handshake & ID Tracking
    // -------------------------------------------------------------------------
    reg [ID_WIDTH-1:0] arid_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arid_q <= {ID_WIDTH{1'b0}};
        end else if (s_axi_arvalid && s_axi_arready) begin
            arid_q <= s_axi_arid;
        end
    end

    assign m_axil_araddr  = s_axi_araddr;
    assign m_axil_arvalid = s_axi_arvalid;
    assign s_axi_arready  = m_axil_arready;

    assign s_axi_rdata    = m_axil_rdata;
    assign s_axi_rresp    = m_axil_rresp;
    assign s_axi_rvalid   = m_axil_rvalid;
    assign m_axil_rready  = s_axi_rready;
    assign s_axi_rid      = arid_q;
    assign s_axi_rlast    = m_axil_rvalid; // Single beat for AXI4-Lite
    assign s_axi_ruser    = {RUSER_WIDTH{1'b0}};

endmodule

`resetall
