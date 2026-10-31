// =============================================================================
// Testbench : tb_axi_interconnect_wrap_3x14.sv
// DUT       : axi_interconnect_wrap_3x14
// Config    : 3 masters (s00-s02) x 14 slaves (m00-m13)
// Tool      : Synopsys VCS (SystemVerilog)
// Notes     : No UVM, no external VIP.  All responder logic is inline.
//             Each slave window = 24 bits (16 MB) at base address = N << 24.
// =============================================================================

`timescale 1ns/1ps

module tb_axi_interconnect_wrap_3x14;

// ---------------------------------------------------------------------------
// Parameters (must match DUT defaults)
// ---------------------------------------------------------------------------
localparam DATA_WIDTH    = 32;
localparam ADDR_WIDTH    = 32;
localparam STRB_WIDTH    = DATA_WIDTH / 8;   // 4
localparam ID_WIDTH      = 8;
localparam AWUSER_WIDTH  = 1;
localparam WUSER_WIDTH   = 1;
localparam BUSER_WIDTH   = 1;
localparam ARUSER_WIDTH  = 1;
localparam RUSER_WIDTH   = 1;

// Slave base addresses: slave N starts at N << 24 (non-overlapping 16 MB windows)
localparam [ADDR_WIDTH-1:0] BASE_M00 = 32'h0000_0000;
localparam [ADDR_WIDTH-1:0] BASE_M01 = 32'h0100_0000;
localparam [ADDR_WIDTH-1:0] BASE_M02 = 32'h0200_0000;
localparam [ADDR_WIDTH-1:0] BASE_M03 = 32'h0300_0000;
localparam [ADDR_WIDTH-1:0] BASE_M04 = 32'h0400_0000;
localparam [ADDR_WIDTH-1:0] BASE_M05 = 32'h0500_0000;
localparam [ADDR_WIDTH-1:0] BASE_M06 = 32'h0600_0000;
localparam [ADDR_WIDTH-1:0] BASE_M07 = 32'h0700_0000;
localparam [ADDR_WIDTH-1:0] BASE_M08 = 32'h0800_0000;
localparam [ADDR_WIDTH-1:0] BASE_M09 = 32'h0900_0000;
localparam [ADDR_WIDTH-1:0] BASE_M10 = 32'hA00_0000;
localparam [ADDR_WIDTH-1:0] BASE_M11 = 32'h0B00_0000;
localparam [ADDR_WIDTH-1:0] BASE_M12 = 32'h0C00_0000;
localparam [ADDR_WIDTH-1:0] BASE_M13 = 32'h0D00_0000;

// Timeout guard
localparam TIMEOUT_CYCLES = 10_000;

// ---------------------------------------------------------------------------
// Clock & reset
// ---------------------------------------------------------------------------
logic clk;
logic rst;

initial clk = 1'b0;
always #5 clk = ~clk;   // 100 MHz

// ---------------------------------------------------------------------------
// Master (slave-side of DUT) signal declarations  —  s00 / s01 / s02
// ---------------------------------------------------------------------------

// ---- s00 ----
logic [ID_WIDTH-1:0]     s00_axi_awid;
logic [ADDR_WIDTH-1:0]   s00_axi_awaddr;
logic [7:0]              s00_axi_awlen;
logic [2:0]              s00_axi_awsize;
logic [1:0]              s00_axi_awburst;
logic                    s00_axi_awlock;
logic [3:0]              s00_axi_awcache;
logic [2:0]              s00_axi_awprot;
logic [3:0]              s00_axi_awqos;
logic [AWUSER_WIDTH-1:0] s00_axi_awuser;
logic                    s00_axi_awvalid;
wire                     s00_axi_awready;
logic [DATA_WIDTH-1:0]   s00_axi_wdata;
logic [STRB_WIDTH-1:0]   s00_axi_wstrb;
logic                    s00_axi_wlast;
logic [WUSER_WIDTH-1:0]  s00_axi_wuser;
logic                    s00_axi_wvalid;
wire                     s00_axi_wready;
wire  [ID_WIDTH-1:0]     s00_axi_bid;
wire  [1:0]              s00_axi_bresp;
wire  [BUSER_WIDTH-1:0]  s00_axi_buser;
wire                     s00_axi_bvalid;
logic                    s00_axi_bready;
logic [ID_WIDTH-1:0]     s00_axi_arid;
logic [ADDR_WIDTH-1:0]   s00_axi_araddr;
logic [7:0]              s00_axi_arlen;
logic [2:0]              s00_axi_arsize;
logic [1:0]              s00_axi_arburst;
logic                    s00_axi_arlock;
logic [3:0]              s00_axi_arcache;
logic [2:0]              s00_axi_arprot;
logic [3:0]              s00_axi_arqos;
logic [ARUSER_WIDTH-1:0] s00_axi_aruser;
logic                    s00_axi_arvalid;
wire                     s00_axi_arready;
wire  [ID_WIDTH-1:0]     s00_axi_rid;
wire  [DATA_WIDTH-1:0]   s00_axi_rdata;
wire  [1:0]              s00_axi_rresp;
wire                     s00_axi_rlast;
wire  [RUSER_WIDTH-1:0]  s00_axi_ruser;
wire                     s00_axi_rvalid;
logic                    s00_axi_rready;

// ---- s01 ----
logic [ID_WIDTH-1:0]     s01_axi_awid;
logic [ADDR_WIDTH-1:0]   s01_axi_awaddr;
logic [7:0]              s01_axi_awlen;
logic [2:0]              s01_axi_awsize;
logic [1:0]              s01_axi_awburst;
logic                    s01_axi_awlock;
logic [3:0]              s01_axi_awcache;
logic [2:0]              s01_axi_awprot;
logic [3:0]              s01_axi_awqos;
logic [AWUSER_WIDTH-1:0] s01_axi_awuser;
logic                    s01_axi_awvalid;
wire                     s01_axi_awready;
logic [DATA_WIDTH-1:0]   s01_axi_wdata;
logic [STRB_WIDTH-1:0]   s01_axi_wstrb;
logic                    s01_axi_wlast;
logic [WUSER_WIDTH-1:0]  s01_axi_wuser;
logic                    s01_axi_wvalid;
wire                     s01_axi_wready;
wire  [ID_WIDTH-1:0]     s01_axi_bid;
wire  [1:0]              s01_axi_bresp;
wire  [BUSER_WIDTH-1:0]  s01_axi_buser;
wire                     s01_axi_bvalid;
logic                    s01_axi_bready;
logic [ID_WIDTH-1:0]     s01_axi_arid;
logic [ADDR_WIDTH-1:0]   s01_axi_araddr;
logic [7:0]              s01_axi_arlen;
logic [2:0]              s01_axi_arsize;
logic [1:0]              s01_axi_arburst;
logic                    s01_axi_arlock;
logic [3:0]              s01_axi_arcache;
logic [2:0]              s01_axi_arprot;
logic [3:0]              s01_axi_arqos;
logic [ARUSER_WIDTH-1:0] s01_axi_aruser;
logic                    s01_axi_arvalid;
wire                     s01_axi_arready;
wire  [ID_WIDTH-1:0]     s01_axi_rid;
wire  [DATA_WIDTH-1:0]   s01_axi_rdata;
wire  [1:0]              s01_axi_rresp;
wire                     s01_axi_rlast;
wire  [RUSER_WIDTH-1:0]  s01_axi_ruser;
wire                     s01_axi_rvalid;
logic                    s01_axi_rready;

// ---- s02 ----
logic [ID_WIDTH-1:0]     s02_axi_awid;
logic [ADDR_WIDTH-1:0]   s02_axi_awaddr;
logic [7:0]              s02_axi_awlen;
logic [2:0]              s02_axi_awsize;
logic [1:0]              s02_axi_awburst;
logic                    s02_axi_awlock;
logic [3:0]              s02_axi_awcache;
logic [2:0]              s02_axi_awprot;
logic [3:0]              s02_axi_awqos;
logic [AWUSER_WIDTH-1:0] s02_axi_awuser;
logic                    s02_axi_awvalid;
wire                     s02_axi_awready;
logic [DATA_WIDTH-1:0]   s02_axi_wdata;
logic [STRB_WIDTH-1:0]   s02_axi_wstrb;
logic                    s02_axi_wlast;
logic [WUSER_WIDTH-1:0]  s02_axi_wuser;
logic                    s02_axi_wvalid;
wire                     s02_axi_wready;
wire  [ID_WIDTH-1:0]     s02_axi_bid;
wire  [1:0]              s02_axi_bresp;
wire  [BUSER_WIDTH-1:0]  s02_axi_buser;
wire                     s02_axi_bvalid;
logic                    s02_axi_bready;
logic [ID_WIDTH-1:0]     s02_axi_arid;
logic [ADDR_WIDTH-1:0]   s02_axi_araddr;
logic [7:0]              s02_axi_arlen;
logic [2:0]              s02_axi_arsize;
logic [1:0]              s02_axi_arburst;
logic                    s02_axi_arlock;
logic [3:0]              s02_axi_arcache;
logic [2:0]              s02_axi_arprot;
logic [3:0]              s02_axi_arqos;
logic [ARUSER_WIDTH-1:0] s02_axi_aruser;
logic                    s02_axi_arvalid;
wire                     s02_axi_arready;
wire  [ID_WIDTH-1:0]     s02_axi_rid;
wire  [DATA_WIDTH-1:0]   s02_axi_rdata;
wire  [1:0]              s02_axi_rresp;
wire                     s02_axi_rlast;
wire  [RUSER_WIDTH-1:0]  s02_axi_ruser;
wire                     s02_axi_rvalid;
logic                    s02_axi_rready;

// ---------------------------------------------------------------------------
// Slave (master-side of DUT) signal declarations  —  m00 … m13
// ---------------------------------------------------------------------------

// ---- m00 ----
wire  [ID_WIDTH-1:0]     m00_axi_awid;
wire  [ADDR_WIDTH-1:0]   m00_axi_awaddr;
wire  [7:0]              m00_axi_awlen;
wire  [2:0]              m00_axi_awsize;
wire  [1:0]              m00_axi_awburst;
wire                     m00_axi_awlock;
wire  [3:0]              m00_axi_awcache;
wire  [2:0]              m00_axi_awprot;
wire  [3:0]              m00_axi_awqos;
wire  [3:0]              m00_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m00_axi_awuser;
wire                     m00_axi_awvalid;
logic                    m00_axi_awready;
wire  [DATA_WIDTH-1:0]   m00_axi_wdata;
wire  [STRB_WIDTH-1:0]   m00_axi_wstrb;
wire                     m00_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m00_axi_wuser;
wire                     m00_axi_wvalid;
logic                    m00_axi_wready;
logic [ID_WIDTH-1:0]     m00_axi_bid;
logic [1:0]              m00_axi_bresp;
logic [BUSER_WIDTH-1:0]  m00_axi_buser;
logic                    m00_axi_bvalid;
wire                     m00_axi_bready;
wire  [ID_WIDTH-1:0]     m00_axi_arid;
wire  [ADDR_WIDTH-1:0]   m00_axi_araddr;
wire  [7:0]              m00_axi_arlen;
wire  [2:0]              m00_axi_arsize;
wire  [1:0]              m00_axi_arburst;
wire                     m00_axi_arlock;
wire  [3:0]              m00_axi_arcache;
wire  [2:0]              m00_axi_arprot;
wire  [3:0]              m00_axi_arqos;
wire  [3:0]              m00_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m00_axi_aruser;
wire                     m00_axi_arvalid;
logic                    m00_axi_arready;
logic [ID_WIDTH-1:0]     m00_axi_rid;
logic [DATA_WIDTH-1:0]   m00_axi_rdata;
logic [1:0]              m00_axi_rresp;
logic                    m00_axi_rlast;
logic [RUSER_WIDTH-1:0]  m00_axi_ruser;
logic                    m00_axi_rvalid;
wire                     m00_axi_rready;

// ---- m01 ----
wire  [ID_WIDTH-1:0]     m01_axi_awid;
wire  [ADDR_WIDTH-1:0]   m01_axi_awaddr;
wire  [7:0]              m01_axi_awlen;
wire  [2:0]              m01_axi_awsize;
wire  [1:0]              m01_axi_awburst;
wire                     m01_axi_awlock;
wire  [3:0]              m01_axi_awcache;
wire  [2:0]              m01_axi_awprot;
wire  [3:0]              m01_axi_awqos;
wire  [3:0]              m01_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m01_axi_awuser;
wire                     m01_axi_awvalid;
logic                    m01_axi_awready;
wire  [DATA_WIDTH-1:0]   m01_axi_wdata;
wire  [STRB_WIDTH-1:0]   m01_axi_wstrb;
wire                     m01_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m01_axi_wuser;
wire                     m01_axi_wvalid;
logic                    m01_axi_wready;
logic [ID_WIDTH-1:0]     m01_axi_bid;
logic [1:0]              m01_axi_bresp;
logic [BUSER_WIDTH-1:0]  m01_axi_buser;
logic                    m01_axi_bvalid;
wire                     m01_axi_bready;
wire  [ID_WIDTH-1:0]     m01_axi_arid;
wire  [ADDR_WIDTH-1:0]   m01_axi_araddr;
wire  [7:0]              m01_axi_arlen;
wire  [2:0]              m01_axi_arsize;
wire  [1:0]              m01_axi_arburst;
wire                     m01_axi_arlock;
wire  [3:0]              m01_axi_arcache;
wire  [2:0]              m01_axi_arprot;
wire  [3:0]              m01_axi_arqos;
wire  [3:0]              m01_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m01_axi_aruser;
wire                     m01_axi_arvalid;
logic                    m01_axi_arready;
logic [ID_WIDTH-1:0]     m01_axi_rid;
logic [DATA_WIDTH-1:0]   m01_axi_rdata;
logic [1:0]              m01_axi_rresp;
logic                    m01_axi_rlast;
logic [RUSER_WIDTH-1:0]  m01_axi_ruser;
logic                    m01_axi_rvalid;
wire                     m01_axi_rready;

// ---- m02 ----
wire  [ID_WIDTH-1:0]     m02_axi_awid;
wire  [ADDR_WIDTH-1:0]   m02_axi_awaddr;
wire  [7:0]              m02_axi_awlen;
wire  [2:0]              m02_axi_awsize;
wire  [1:0]              m02_axi_awburst;
wire                     m02_axi_awlock;
wire  [3:0]              m02_axi_awcache;
wire  [2:0]              m02_axi_awprot;
wire  [3:0]              m02_axi_awqos;
wire  [3:0]              m02_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m02_axi_awuser;
wire                     m02_axi_awvalid;
logic                    m02_axi_awready;
wire  [DATA_WIDTH-1:0]   m02_axi_wdata;
wire  [STRB_WIDTH-1:0]   m02_axi_wstrb;
wire                     m02_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m02_axi_wuser;
wire                     m02_axi_wvalid;
logic                    m02_axi_wready;
logic [ID_WIDTH-1:0]     m02_axi_bid;
logic [1:0]              m02_axi_bresp;
logic [BUSER_WIDTH-1:0]  m02_axi_buser;
logic                    m02_axi_bvalid;
wire                     m02_axi_bready;
wire  [ID_WIDTH-1:0]     m02_axi_arid;
wire  [ADDR_WIDTH-1:0]   m02_axi_araddr;
wire  [7:0]              m02_axi_arlen;
wire  [2:0]              m02_axi_arsize;
wire  [1:0]              m02_axi_arburst;
wire                     m02_axi_arlock;
wire  [3:0]              m02_axi_arcache;
wire  [2:0]              m02_axi_arprot;
wire  [3:0]              m02_axi_arqos;
wire  [3:0]              m02_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m02_axi_aruser;
wire                     m02_axi_arvalid;
logic                    m02_axi_arready;
logic [ID_WIDTH-1:0]     m02_axi_rid;
logic [DATA_WIDTH-1:0]   m02_axi_rdata;
logic [1:0]              m02_axi_rresp;
logic                    m02_axi_rlast;
logic [RUSER_WIDTH-1:0]  m02_axi_ruser;
logic                    m02_axi_rvalid;
wire                     m02_axi_rready;

// ---- m03 ----
wire  [ID_WIDTH-1:0]     m03_axi_awid;
wire  [ADDR_WIDTH-1:0]   m03_axi_awaddr;
wire  [7:0]              m03_axi_awlen;
wire  [2:0]              m03_axi_awsize;
wire  [1:0]              m03_axi_awburst;
wire                     m03_axi_awlock;
wire  [3:0]              m03_axi_awcache;
wire  [2:0]              m03_axi_awprot;
wire  [3:0]              m03_axi_awqos;
wire  [3:0]              m03_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m03_axi_awuser;
wire                     m03_axi_awvalid;
logic                    m03_axi_awready;
wire  [DATA_WIDTH-1:0]   m03_axi_wdata;
wire  [STRB_WIDTH-1:0]   m03_axi_wstrb;
wire                     m03_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m03_axi_wuser;
wire                     m03_axi_wvalid;
logic                    m03_axi_wready;
logic [ID_WIDTH-1:0]     m03_axi_bid;
logic [1:0]              m03_axi_bresp;
logic [BUSER_WIDTH-1:0]  m03_axi_buser;
logic                    m03_axi_bvalid;
wire                     m03_axi_bready;
wire  [ID_WIDTH-1:0]     m03_axi_arid;
wire  [ADDR_WIDTH-1:0]   m03_axi_araddr;
wire  [7:0]              m03_axi_arlen;
wire  [2:0]              m03_axi_arsize;
wire  [1:0]              m03_axi_arburst;
wire                     m03_axi_arlock;
wire  [3:0]              m03_axi_arcache;
wire  [2:0]              m03_axi_arprot;
wire  [3:0]              m03_axi_arqos;
wire  [3:0]              m03_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m03_axi_aruser;
wire                     m03_axi_arvalid;
logic                    m03_axi_arready;
logic [ID_WIDTH-1:0]     m03_axi_rid;
logic [DATA_WIDTH-1:0]   m03_axi_rdata;
logic [1:0]              m03_axi_rresp;
logic                    m03_axi_rlast;
logic [RUSER_WIDTH-1:0]  m03_axi_ruser;
logic                    m03_axi_rvalid;
wire                     m03_axi_rready;

// ---- m04 ----
wire  [ID_WIDTH-1:0]     m04_axi_awid;
wire  [ADDR_WIDTH-1:0]   m04_axi_awaddr;
wire  [7:0]              m04_axi_awlen;
wire  [2:0]              m04_axi_awsize;
wire  [1:0]              m04_axi_awburst;
wire                     m04_axi_awlock;
wire  [3:0]              m04_axi_awcache;
wire  [2:0]              m04_axi_awprot;
wire  [3:0]              m04_axi_awqos;
wire  [3:0]              m04_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m04_axi_awuser;
wire                     m04_axi_awvalid;
logic                    m04_axi_awready;
wire  [DATA_WIDTH-1:0]   m04_axi_wdata;
wire  [STRB_WIDTH-1:0]   m04_axi_wstrb;
wire                     m04_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m04_axi_wuser;
wire                     m04_axi_wvalid;
logic                    m04_axi_wready;
logic [ID_WIDTH-1:0]     m04_axi_bid;
logic [1:0]              m04_axi_bresp;
logic [BUSER_WIDTH-1:0]  m04_axi_buser;
logic                    m04_axi_bvalid;
wire                     m04_axi_bready;
wire  [ID_WIDTH-1:0]     m04_axi_arid;
wire  [ADDR_WIDTH-1:0]   m04_axi_araddr;
wire  [7:0]              m04_axi_arlen;
wire  [2:0]              m04_axi_arsize;
wire  [1:0]              m04_axi_arburst;
wire                     m04_axi_arlock;
wire  [3:0]              m04_axi_arcache;
wire  [2:0]              m04_axi_arprot;
wire  [3:0]              m04_axi_arqos;
wire  [3:0]              m04_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m04_axi_aruser;
wire                     m04_axi_arvalid;
logic                    m04_axi_arready;
logic [ID_WIDTH-1:0]     m04_axi_rid;
logic [DATA_WIDTH-1:0]   m04_axi_rdata;
logic [1:0]              m04_axi_rresp;
logic                    m04_axi_rlast;
logic [RUSER_WIDTH-1:0]  m04_axi_ruser;
logic                    m04_axi_rvalid;
wire                     m04_axi_rready;

// ---- m05 ----
wire  [ID_WIDTH-1:0]     m05_axi_awid;
wire  [ADDR_WIDTH-1:0]   m05_axi_awaddr;
wire  [7:0]              m05_axi_awlen;
wire  [2:0]              m05_axi_awsize;
wire  [1:0]              m05_axi_awburst;
wire                     m05_axi_awlock;
wire  [3:0]              m05_axi_awcache;
wire  [2:0]              m05_axi_awprot;
wire  [3:0]              m05_axi_awqos;
wire  [3:0]              m05_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m05_axi_awuser;
wire                     m05_axi_awvalid;
logic                    m05_axi_awready;
wire  [DATA_WIDTH-1:0]   m05_axi_wdata;
wire  [STRB_WIDTH-1:0]   m05_axi_wstrb;
wire                     m05_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m05_axi_wuser;
wire                     m05_axi_wvalid;
logic                    m05_axi_wready;
logic [ID_WIDTH-1:0]     m05_axi_bid;
logic [1:0]              m05_axi_bresp;
logic [BUSER_WIDTH-1:0]  m05_axi_buser;
logic                    m05_axi_bvalid;
wire                     m05_axi_bready;
wire  [ID_WIDTH-1:0]     m05_axi_arid;
wire  [ADDR_WIDTH-1:0]   m05_axi_araddr;
wire  [7:0]              m05_axi_arlen;
wire  [2:0]              m05_axi_arsize;
wire  [1:0]              m05_axi_arburst;
wire                     m05_axi_arlock;
wire  [3:0]              m05_axi_arcache;
wire  [2:0]              m05_axi_arprot;
wire  [3:0]              m05_axi_arqos;
wire  [3:0]              m05_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m05_axi_aruser;
wire                     m05_axi_arvalid;
logic                    m05_axi_arready;
logic [ID_WIDTH-1:0]     m05_axi_rid;
logic [DATA_WIDTH-1:0]   m05_axi_rdata;
logic [1:0]              m05_axi_rresp;
logic                    m05_axi_rlast;
logic [RUSER_WIDTH-1:0]  m05_axi_ruser;
logic                    m05_axi_rvalid;
wire                     m05_axi_rready;

// ---- m06 ----
wire  [ID_WIDTH-1:0]     m06_axi_awid;
wire  [ADDR_WIDTH-1:0]   m06_axi_awaddr;
wire  [7:0]              m06_axi_awlen;
wire  [2:0]              m06_axi_awsize;
wire  [1:0]              m06_axi_awburst;
wire                     m06_axi_awlock;
wire  [3:0]              m06_axi_awcache;
wire  [2:0]              m06_axi_awprot;
wire  [3:0]              m06_axi_awqos;
wire  [3:0]              m06_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m06_axi_awuser;
wire                     m06_axi_awvalid;
logic                    m06_axi_awready;
wire  [DATA_WIDTH-1:0]   m06_axi_wdata;
wire  [STRB_WIDTH-1:0]   m06_axi_wstrb;
wire                     m06_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m06_axi_wuser;
wire                     m06_axi_wvalid;
logic                    m06_axi_wready;
logic [ID_WIDTH-1:0]     m06_axi_bid;
logic [1:0]              m06_axi_bresp;
logic [BUSER_WIDTH-1:0]  m06_axi_buser;
logic                    m06_axi_bvalid;
wire                     m06_axi_bready;
wire  [ID_WIDTH-1:0]     m06_axi_arid;
wire  [ADDR_WIDTH-1:0]   m06_axi_araddr;
wire  [7:0]              m06_axi_arlen;
wire  [2:0]              m06_axi_arsize;
wire  [1:0]              m06_axi_arburst;
wire                     m06_axi_arlock;
wire  [3:0]              m06_axi_arcache;
wire  [2:0]              m06_axi_arprot;
wire  [3:0]              m06_axi_arqos;
wire  [3:0]              m06_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m06_axi_aruser;
wire                     m06_axi_arvalid;
logic                    m06_axi_arready;
logic [ID_WIDTH-1:0]     m06_axi_rid;
logic [DATA_WIDTH-1:0]   m06_axi_rdata;
logic [1:0]              m06_axi_rresp;
logic                    m06_axi_rlast;
logic [RUSER_WIDTH-1:0]  m06_axi_ruser;
logic                    m06_axi_rvalid;
wire                     m06_axi_rready;

// ---- m07 ----
wire  [ID_WIDTH-1:0]     m07_axi_awid;
wire  [ADDR_WIDTH-1:0]   m07_axi_awaddr;
wire  [7:0]              m07_axi_awlen;
wire  [2:0]              m07_axi_awsize;
wire  [1:0]              m07_axi_awburst;
wire                     m07_axi_awlock;
wire  [3:0]              m07_axi_awcache;
wire  [2:0]              m07_axi_awprot;
wire  [3:0]              m07_axi_awqos;
wire  [3:0]              m07_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m07_axi_awuser;
wire                     m07_axi_awvalid;
logic                    m07_axi_awready;
wire  [DATA_WIDTH-1:0]   m07_axi_wdata;
wire  [STRB_WIDTH-1:0]   m07_axi_wstrb;
wire                     m07_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m07_axi_wuser;
wire                     m07_axi_wvalid;
logic                    m07_axi_wready;
logic [ID_WIDTH-1:0]     m07_axi_bid;
logic [1:0]              m07_axi_bresp;
logic [BUSER_WIDTH-1:0]  m07_axi_buser;
logic                    m07_axi_bvalid;
wire                     m07_axi_bready;
wire  [ID_WIDTH-1:0]     m07_axi_arid;
wire  [ADDR_WIDTH-1:0]   m07_axi_araddr;
wire  [7:0]              m07_axi_arlen;
wire  [2:0]              m07_axi_arsize;
wire  [1:0]              m07_axi_arburst;
wire                     m07_axi_arlock;
wire  [3:0]              m07_axi_arcache;
wire  [2:0]              m07_axi_arprot;
wire  [3:0]              m07_axi_arqos;
wire  [3:0]              m07_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m07_axi_aruser;
wire                     m07_axi_arvalid;
logic                    m07_axi_arready;
logic [ID_WIDTH-1:0]     m07_axi_rid;
logic [DATA_WIDTH-1:0]   m07_axi_rdata;
logic [1:0]              m07_axi_rresp;
logic                    m07_axi_rlast;
logic [RUSER_WIDTH-1:0]  m07_axi_ruser;
logic                    m07_axi_rvalid;
wire                     m07_axi_rready;

// ---- m08 ----
wire  [ID_WIDTH-1:0]     m08_axi_awid;
wire  [ADDR_WIDTH-1:0]   m08_axi_awaddr;
wire  [7:0]              m08_axi_awlen;
wire  [2:0]              m08_axi_awsize;
wire  [1:0]              m08_axi_awburst;
wire                     m08_axi_awlock;
wire  [3:0]              m08_axi_awcache;
wire  [2:0]              m08_axi_awprot;
wire  [3:0]              m08_axi_awqos;
wire  [3:0]              m08_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m08_axi_awuser;
wire                     m08_axi_awvalid;
logic                    m08_axi_awready;
wire  [DATA_WIDTH-1:0]   m08_axi_wdata;
wire  [STRB_WIDTH-1:0]   m08_axi_wstrb;
wire                     m08_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m08_axi_wuser;
wire                     m08_axi_wvalid;
logic                    m08_axi_wready;
logic [ID_WIDTH-1:0]     m08_axi_bid;
logic [1:0]              m08_axi_bresp;
logic [BUSER_WIDTH-1:0]  m08_axi_buser;
logic                    m08_axi_bvalid;
wire                     m08_axi_bready;
wire  [ID_WIDTH-1:0]     m08_axi_arid;
wire  [ADDR_WIDTH-1:0]   m08_axi_araddr;
wire  [7:0]              m08_axi_arlen;
wire  [2:0]              m08_axi_arsize;
wire  [1:0]              m08_axi_arburst;
wire                     m08_axi_arlock;
wire  [3:0]              m08_axi_arcache;
wire  [2:0]              m08_axi_arprot;
wire  [3:0]              m08_axi_arqos;
wire  [3:0]              m08_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m08_axi_aruser;
wire                     m08_axi_arvalid;
logic                    m08_axi_arready;
logic [ID_WIDTH-1:0]     m08_axi_rid;
logic [DATA_WIDTH-1:0]   m08_axi_rdata;
logic [1:0]              m08_axi_rresp;
logic                    m08_axi_rlast;
logic [RUSER_WIDTH-1:0]  m08_axi_ruser;
logic                    m08_axi_rvalid;
wire                     m08_axi_rready;

// ---- m09 ----
wire  [ID_WIDTH-1:0]     m09_axi_awid;
wire  [ADDR_WIDTH-1:0]   m09_axi_awaddr;
wire  [7:0]              m09_axi_awlen;
wire  [2:0]              m09_axi_awsize;
wire  [1:0]              m09_axi_awburst;
wire                     m09_axi_awlock;
wire  [3:0]              m09_axi_awcache;
wire  [2:0]              m09_axi_awprot;
wire  [3:0]              m09_axi_awqos;
wire  [3:0]              m09_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m09_axi_awuser;
wire                     m09_axi_awvalid;
logic                    m09_axi_awready;
wire  [DATA_WIDTH-1:0]   m09_axi_wdata;
wire  [STRB_WIDTH-1:0]   m09_axi_wstrb;
wire                     m09_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m09_axi_wuser;
wire                     m09_axi_wvalid;
logic                    m09_axi_wready;
logic [ID_WIDTH-1:0]     m09_axi_bid;
logic [1:0]              m09_axi_bresp;
logic [BUSER_WIDTH-1:0]  m09_axi_buser;
logic                    m09_axi_bvalid;
wire                     m09_axi_bready;
wire  [ID_WIDTH-1:0]     m09_axi_arid;
wire  [ADDR_WIDTH-1:0]   m09_axi_araddr;
wire  [7:0]              m09_axi_arlen;
wire  [2:0]              m09_axi_arsize;
wire  [1:0]              m09_axi_arburst;
wire                     m09_axi_arlock;
wire  [3:0]              m09_axi_arcache;
wire  [2:0]              m09_axi_arprot;
wire  [3:0]              m09_axi_arqos;
wire  [3:0]              m09_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m09_axi_aruser;
wire                     m09_axi_arvalid;
logic                    m09_axi_arready;
logic [ID_WIDTH-1:0]     m09_axi_rid;
logic [DATA_WIDTH-1:0]   m09_axi_rdata;
logic [1:0]              m09_axi_rresp;
logic                    m09_axi_rlast;
logic [RUSER_WIDTH-1:0]  m09_axi_ruser;
logic                    m09_axi_rvalid;
wire                     m09_axi_rready;

// ---- m10 ----
wire  [ID_WIDTH-1:0]     m10_axi_awid;
wire  [ADDR_WIDTH-1:0]   m10_axi_awaddr;
wire  [7:0]              m10_axi_awlen;
wire  [2:0]              m10_axi_awsize;
wire  [1:0]              m10_axi_awburst;
wire                     m10_axi_awlock;
wire  [3:0]              m10_axi_awcache;
wire  [2:0]              m10_axi_awprot;
wire  [3:0]              m10_axi_awqos;
wire  [3:0]              m10_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m10_axi_awuser;
wire                     m10_axi_awvalid;
logic                    m10_axi_awready;
wire  [DATA_WIDTH-1:0]   m10_axi_wdata;
wire  [STRB_WIDTH-1:0]   m10_axi_wstrb;
wire                     m10_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m10_axi_wuser;
wire                     m10_axi_wvalid;
logic                    m10_axi_wready;
logic [ID_WIDTH-1:0]     m10_axi_bid;
logic [1:0]              m10_axi_bresp;
logic [BUSER_WIDTH-1:0]  m10_axi_buser;
logic                    m10_axi_bvalid;
wire                     m10_axi_bready;
wire  [ID_WIDTH-1:0]     m10_axi_arid;
wire  [ADDR_WIDTH-1:0]   m10_axi_araddr;
wire  [7:0]              m10_axi_arlen;
wire  [2:0]              m10_axi_arsize;
wire  [1:0]              m10_axi_arburst;
wire                     m10_axi_arlock;
wire  [3:0]              m10_axi_arcache;
wire  [2:0]              m10_axi_arprot;
wire  [3:0]              m10_axi_arqos;
wire  [3:0]              m10_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m10_axi_aruser;
wire                     m10_axi_arvalid;
logic                    m10_axi_arready;
logic [ID_WIDTH-1:0]     m10_axi_rid;
logic [DATA_WIDTH-1:0]   m10_axi_rdata;
logic [1:0]              m10_axi_rresp;
logic                    m10_axi_rlast;
logic [RUSER_WIDTH-1:0]  m10_axi_ruser;
logic                    m10_axi_rvalid;
wire                     m10_axi_rready;

// ---- m11 ----
wire  [ID_WIDTH-1:0]     m11_axi_awid;
wire  [ADDR_WIDTH-1:0]   m11_axi_awaddr;
wire  [7:0]              m11_axi_awlen;
wire  [2:0]              m11_axi_awsize;
wire  [1:0]              m11_axi_awburst;
wire                     m11_axi_awlock;
wire  [3:0]              m11_axi_awcache;
wire  [2:0]              m11_axi_awprot;
wire  [3:0]              m11_axi_awqos;
wire  [3:0]              m11_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m11_axi_awuser;
wire                     m11_axi_awvalid;
logic                    m11_axi_awready;
wire  [DATA_WIDTH-1:0]   m11_axi_wdata;
wire  [STRB_WIDTH-1:0]   m11_axi_wstrb;
wire                     m11_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m11_axi_wuser;
wire                     m11_axi_wvalid;
logic                    m11_axi_wready;
logic [ID_WIDTH-1:0]     m11_axi_bid;
logic [1:0]              m11_axi_bresp;
logic [BUSER_WIDTH-1:0]  m11_axi_buser;
logic                    m11_axi_bvalid;
wire                     m11_axi_bready;
wire  [ID_WIDTH-1:0]     m11_axi_arid;
wire  [ADDR_WIDTH-1:0]   m11_axi_araddr;
wire  [7:0]              m11_axi_arlen;
wire  [2:0]              m11_axi_arsize;
wire  [1:0]              m11_axi_arburst;
wire                     m11_axi_arlock;
wire  [3:0]              m11_axi_arcache;
wire  [2:0]              m11_axi_arprot;
wire  [3:0]              m11_axi_arqos;
wire  [3:0]              m11_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m11_axi_aruser;
wire                     m11_axi_arvalid;
logic                    m11_axi_arready;
logic [ID_WIDTH-1:0]     m11_axi_rid;
logic [DATA_WIDTH-1:0]   m11_axi_rdata;
logic [1:0]              m11_axi_rresp;
logic                    m11_axi_rlast;
logic [RUSER_WIDTH-1:0]  m11_axi_ruser;
logic                    m11_axi_rvalid;
wire                     m11_axi_rready;

// ---- m12 ----
wire  [ID_WIDTH-1:0]     m12_axi_awid;
wire  [ADDR_WIDTH-1:0]   m12_axi_awaddr;
wire  [7:0]              m12_axi_awlen;
wire  [2:0]              m12_axi_awsize;
wire  [1:0]              m12_axi_awburst;
wire                     m12_axi_awlock;
wire  [3:0]              m12_axi_awcache;
wire  [2:0]              m12_axi_awprot;
wire  [3:0]              m12_axi_awqos;
wire  [3:0]              m12_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m12_axi_awuser;
wire                     m12_axi_awvalid;
logic                    m12_axi_awready;
wire  [DATA_WIDTH-1:0]   m12_axi_wdata;
wire  [STRB_WIDTH-1:0]   m12_axi_wstrb;
wire                     m12_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m12_axi_wuser;
wire                     m12_axi_wvalid;
logic                    m12_axi_wready;
logic [ID_WIDTH-1:0]     m12_axi_bid;
logic [1:0]              m12_axi_bresp;
logic [BUSER_WIDTH-1:0]  m12_axi_buser;
logic                    m12_axi_bvalid;
wire                     m12_axi_bready;
wire  [ID_WIDTH-1:0]     m12_axi_arid;
wire  [ADDR_WIDTH-1:0]   m12_axi_araddr;
wire  [7:0]              m12_axi_arlen;
wire  [2:0]              m12_axi_arsize;
wire  [1:0]              m12_axi_arburst;
wire                     m12_axi_arlock;
wire  [3:0]              m12_axi_arcache;
wire  [2:0]              m12_axi_arprot;
wire  [3:0]              m12_axi_arqos;
wire  [3:0]              m12_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m12_axi_aruser;
wire                     m12_axi_arvalid;
logic                    m12_axi_arready;
logic [ID_WIDTH-1:0]     m12_axi_rid;
logic [DATA_WIDTH-1:0]   m12_axi_rdata;
logic [1:0]              m12_axi_rresp;
logic                    m12_axi_rlast;
logic [RUSER_WIDTH-1:0]  m12_axi_ruser;
logic                    m12_axi_rvalid;
wire                     m12_axi_rready;

// ---- m13 ----
wire  [ID_WIDTH-1:0]     m13_axi_awid;
wire  [ADDR_WIDTH-1:0]   m13_axi_awaddr;
wire  [7:0]              m13_axi_awlen;
wire  [2:0]              m13_axi_awsize;
wire  [1:0]              m13_axi_awburst;
wire                     m13_axi_awlock;
wire  [3:0]              m13_axi_awcache;
wire  [2:0]              m13_axi_awprot;
wire  [3:0]              m13_axi_awqos;
wire  [3:0]              m13_axi_awregion;
wire  [AWUSER_WIDTH-1:0] m13_axi_awuser;
wire                     m13_axi_awvalid;
logic                    m13_axi_awready;
wire  [DATA_WIDTH-1:0]   m13_axi_wdata;
wire  [STRB_WIDTH-1:0]   m13_axi_wstrb;
wire                     m13_axi_wlast;
wire  [WUSER_WIDTH-1:0]  m13_axi_wuser;
wire                     m13_axi_wvalid;
logic                    m13_axi_wready;
logic [ID_WIDTH-1:0]     m13_axi_bid;
logic [1:0]              m13_axi_bresp;
logic [BUSER_WIDTH-1:0]  m13_axi_buser;
logic                    m13_axi_bvalid;
wire                     m13_axi_bready;
wire  [ID_WIDTH-1:0]     m13_axi_arid;
wire  [ADDR_WIDTH-1:0]   m13_axi_araddr;
wire  [7:0]              m13_axi_arlen;
wire  [2:0]              m13_axi_arsize;
wire  [1:0]              m13_axi_arburst;
wire                     m13_axi_arlock;
wire  [3:0]              m13_axi_arcache;
wire  [2:0]              m13_axi_arprot;
wire  [3:0]              m13_axi_arqos;
wire  [3:0]              m13_axi_arregion;
wire  [ARUSER_WIDTH-1:0] m13_axi_aruser;
wire                     m13_axi_arvalid;
logic                    m13_axi_arready;
logic [ID_WIDTH-1:0]     m13_axi_rid;
logic [DATA_WIDTH-1:0]   m13_axi_rdata;
logic [1:0]              m13_axi_rresp;
logic                    m13_axi_rlast;
logic [RUSER_WIDTH-1:0]  m13_axi_ruser;
logic                    m13_axi_rvalid;
wire                     m13_axi_rready;

// ---------------------------------------------------------------------------
// Scoreboard / checker state
// ---------------------------------------------------------------------------
integer pass_count;
integer fail_count;

// ===========================================================================
// DUT Instantiation
// Base addresses set to N<<24 so each slave gets a unique non-overlapping
// 16 MB window (addr_width=24).
// ===========================================================================
axi_interconnect_wrap_3x14 #(
    .DATA_WIDTH     (DATA_WIDTH),
    .ADDR_WIDTH     (ADDR_WIDTH),
    .STRB_WIDTH     (STRB_WIDTH),
    .ID_WIDTH       (ID_WIDTH),
    .AWUSER_ENABLE  (0),
    .AWUSER_WIDTH   (AWUSER_WIDTH),
    .WUSER_ENABLE   (0),
    .WUSER_WIDTH    (WUSER_WIDTH),
    .BUSER_ENABLE   (0),
    .BUSER_WIDTH    (BUSER_WIDTH),
    .ARUSER_ENABLE  (0),
    .ARUSER_WIDTH   (ARUSER_WIDTH),
    .RUSER_ENABLE   (0),
    .RUSER_WIDTH    (RUSER_WIDTH),
    .FORWARD_ID     (0),
    .M_REGIONS      (1),
    // Each slave: base = N<<24, addr_width = 24 (16 MB window)
    .M00_BASE_ADDR  (32'h0000_0000), .M00_ADDR_WIDTH ({1{32'd24}}),
    .M01_BASE_ADDR  (32'h0100_0000), .M01_ADDR_WIDTH ({1{32'd24}}),
    .M02_BASE_ADDR  (32'h0200_0000), .M02_ADDR_WIDTH ({1{32'd24}}),
    .M03_BASE_ADDR  (32'h0300_0000), .M03_ADDR_WIDTH ({1{32'd24}}),
    .M04_BASE_ADDR  (32'h0400_0000), .M04_ADDR_WIDTH ({1{32'd24}}),
    .M05_BASE_ADDR  (32'h0500_0000), .M05_ADDR_WIDTH ({1{32'd24}}),
    .M06_BASE_ADDR  (32'h0600_0000), .M06_ADDR_WIDTH ({1{32'd24}}),
    .M07_BASE_ADDR  (32'h0700_0000), .M07_ADDR_WIDTH ({1{32'd24}}),
    .M08_BASE_ADDR  (32'h0800_0000), .M08_ADDR_WIDTH ({1{32'd24}}),
    .M09_BASE_ADDR  (32'h0900_0000), .M09_ADDR_WIDTH ({1{32'd24}}),
    .M10_BASE_ADDR  (32'h0A00_0000), .M10_ADDR_WIDTH ({1{32'd24}}),
    .M11_BASE_ADDR  (32'h0B00_0000), .M11_ADDR_WIDTH ({1{32'd24}}),
    .M12_BASE_ADDR  (32'h0C00_0000), .M12_ADDR_WIDTH ({1{32'd24}}),
    .M13_BASE_ADDR  (32'h0D00_0000), .M13_ADDR_WIDTH ({1{32'd24}}),
    // All masters connectable from all 3 initiators
    .M00_CONNECT_READ (3'b111), .M00_CONNECT_WRITE (3'b111),
    .M01_CONNECT_READ (3'b111), .M01_CONNECT_WRITE (3'b111),
    .M02_CONNECT_READ (3'b111), .M02_CONNECT_WRITE (3'b111),
    .M03_CONNECT_READ (3'b111), .M03_CONNECT_WRITE (3'b111),
    .M04_CONNECT_READ (3'b111), .M04_CONNECT_WRITE (3'b111),
    .M05_CONNECT_READ (3'b111), .M05_CONNECT_WRITE (3'b111),
    .M06_CONNECT_READ (3'b111), .M06_CONNECT_WRITE (3'b111),
    .M07_CONNECT_READ (3'b111), .M07_CONNECT_WRITE (3'b111),
    .M08_CONNECT_READ (3'b111), .M08_CONNECT_WRITE (3'b111),
    .M09_CONNECT_READ (3'b111), .M09_CONNECT_WRITE (3'b111),
    .M10_CONNECT_READ (3'b111), .M10_CONNECT_WRITE (3'b111),
    .M11_CONNECT_READ (3'b111), .M11_CONNECT_WRITE (3'b111),
    .M12_CONNECT_READ (3'b111), .M12_CONNECT_WRITE (3'b111),
    .M13_CONNECT_READ (3'b111), .M13_CONNECT_WRITE (3'b111)
) dut (
    .clk  (clk),
    .rst  (rst),
    // --- slave ports (initiator side) ---
    .s00_axi_awid    (s00_axi_awid),   .s00_axi_awaddr  (s00_axi_awaddr),
    .s00_axi_awlen   (s00_axi_awlen),  .s00_axi_awsize  (s00_axi_awsize),
    .s00_axi_awburst (s00_axi_awburst),.s00_axi_awlock  (s00_axi_awlock),
    .s00_axi_awcache (s00_axi_awcache),.s00_axi_awprot  (s00_axi_awprot),
    .s00_axi_awqos   (s00_axi_awqos),  .s00_axi_awuser  (s00_axi_awuser),
    .s00_axi_awvalid (s00_axi_awvalid),.s00_axi_awready (s00_axi_awready),
    .s00_axi_wdata   (s00_axi_wdata),  .s00_axi_wstrb   (s00_axi_wstrb),
    .s00_axi_wlast   (s00_axi_wlast),  .s00_axi_wuser   (s00_axi_wuser),
    .s00_axi_wvalid  (s00_axi_wvalid), .s00_axi_wready  (s00_axi_wready),
    .s00_axi_bid     (s00_axi_bid),    .s00_axi_bresp   (s00_axi_bresp),
    .s00_axi_buser   (s00_axi_buser),  .s00_axi_bvalid  (s00_axi_bvalid),
    .s00_axi_bready  (s00_axi_bready),
    .s00_axi_arid    (s00_axi_arid),   .s00_axi_araddr  (s00_axi_araddr),
    .s00_axi_arlen   (s00_axi_arlen),  .s00_axi_arsize  (s00_axi_arsize),
    .s00_axi_arburst (s00_axi_arburst),.s00_axi_arlock  (s00_axi_arlock),
    .s00_axi_arcache (s00_axi_arcache),.s00_axi_arprot  (s00_axi_arprot),
    .s00_axi_arqos   (s00_axi_arqos),  .s00_axi_aruser  (s00_axi_aruser),
    .s00_axi_arvalid (s00_axi_arvalid),.s00_axi_arready (s00_axi_arready),
    .s00_axi_rid     (s00_axi_rid),    .s00_axi_rdata   (s00_axi_rdata),
    .s00_axi_rresp   (s00_axi_rresp),  .s00_axi_rlast   (s00_axi_rlast),
    .s00_axi_ruser   (s00_axi_ruser),  .s00_axi_rvalid  (s00_axi_rvalid),
    .s00_axi_rready  (s00_axi_rready),

    .s01_axi_awid    (s01_axi_awid),   .s01_axi_awaddr  (s01_axi_awaddr),
    .s01_axi_awlen   (s01_axi_awlen),  .s01_axi_awsize  (s01_axi_awsize),
    .s01_axi_awburst (s01_axi_awburst),.s01_axi_awlock  (s01_axi_awlock),
    .s01_axi_awcache (s01_axi_awcache),.s01_axi_awprot  (s01_axi_awprot),
    .s01_axi_awqos   (s01_axi_awqos),  .s01_axi_awuser  (s01_axi_awuser),
    .s01_axi_awvalid (s01_axi_awvalid),.s01_axi_awready (s01_axi_awready),
    .s01_axi_wdata   (s01_axi_wdata),  .s01_axi_wstrb   (s01_axi_wstrb),
    .s01_axi_wlast   (s01_axi_wlast),  .s01_axi_wuser   (s01_axi_wuser),
    .s01_axi_wvalid  (s01_axi_wvalid), .s01_axi_wready  (s01_axi_wready),
    .s01_axi_bid     (s01_axi_bid),    .s01_axi_bresp   (s01_axi_bresp),
    .s01_axi_buser   (s01_axi_buser),  .s01_axi_bvalid  (s01_axi_bvalid),
    .s01_axi_bready  (s01_axi_bready),
    .s01_axi_arid    (s01_axi_arid),   .s01_axi_araddr  (s01_axi_araddr),
    .s01_axi_arlen   (s01_axi_arlen),  .s01_axi_arsize  (s01_axi_arsize),
    .s01_axi_arburst (s01_axi_arburst),.s01_axi_arlock  (s01_axi_arlock),
    .s01_axi_arcache (s01_axi_arcache),.s01_axi_arprot  (s01_axi_arprot),
    .s01_axi_arqos   (s01_axi_arqos),  .s01_axi_aruser  (s01_axi_aruser),
    .s01_axi_arvalid (s01_axi_arvalid),.s01_axi_arready (s01_axi_arready),
    .s01_axi_rid     (s01_axi_rid),    .s01_axi_rdata   (s01_axi_rdata),
    .s01_axi_rresp   (s01_axi_rresp),  .s01_axi_rlast   (s01_axi_rlast),
    .s01_axi_ruser   (s01_axi_ruser),  .s01_axi_rvalid  (s01_axi_rvalid),
    .s01_axi_rready  (s01_axi_rready),

    .s02_axi_awid    (s02_axi_awid),   .s02_axi_awaddr  (s02_axi_awaddr),
    .s02_axi_awlen   (s02_axi_awlen),  .s02_axi_awsize  (s02_axi_awsize),
    .s02_axi_awburst (s02_axi_awburst),.s02_axi_awlock  (s02_axi_awlock),
    .s02_axi_awcache (s02_axi_awcache),.s02_axi_awprot  (s02_axi_awprot),
    .s02_axi_awqos   (s02_axi_awqos),  .s02_axi_awuser  (s02_axi_awuser),
    .s02_axi_awvalid (s02_axi_awvalid),.s02_axi_awready (s02_axi_awready),
    .s02_axi_wdata   (s02_axi_wdata),  .s02_axi_wstrb   (s02_axi_wstrb),
    .s02_axi_wlast   (s02_axi_wlast),  .s02_axi_wuser   (s02_axi_wuser),
    .s02_axi_wvalid  (s02_axi_wvalid), .s02_axi_wready  (s02_axi_wready),
    .s02_axi_bid     (s02_axi_bid),    .s02_axi_bresp   (s02_axi_bresp),
    .s02_axi_buser   (s02_axi_buser),  .s02_axi_bvalid  (s02_axi_bvalid),
    .s02_axi_bready  (s02_axi_bready),
    .s02_axi_arid    (s02_axi_arid),   .s02_axi_araddr  (s02_axi_araddr),
    .s02_axi_arlen   (s02_axi_arlen),  .s02_axi_arsize  (s02_axi_arsize),
    .s02_axi_arburst (s02_axi_arburst),.s02_axi_arlock  (s02_axi_arlock),
    .s02_axi_arcache (s02_axi_arcache),.s02_axi_arprot  (s02_axi_arprot),
    .s02_axi_arqos   (s02_axi_arqos),  .s02_axi_aruser  (s02_axi_aruser),
    .s02_axi_arvalid (s02_axi_arvalid),.s02_axi_arready (s02_axi_arready),
    .s02_axi_rid     (s02_axi_rid),    .s02_axi_rdata   (s02_axi_rdata),
    .s02_axi_rresp   (s02_axi_rresp),  .s02_axi_rlast   (s02_axi_rlast),
    .s02_axi_ruser   (s02_axi_ruser),  .s02_axi_rvalid  (s02_axi_rvalid),
    .s02_axi_rready  (s02_axi_rready),

    // --- master ports (target side) ---
    .m00_axi_awid(m00_axi_awid), .m00_axi_awaddr(m00_axi_awaddr),
    .m00_axi_awlen(m00_axi_awlen), .m00_axi_awsize(m00_axi_awsize),
    .m00_axi_awburst(m00_axi_awburst), .m00_axi_awlock(m00_axi_awlock),
    .m00_axi_awcache(m00_axi_awcache), .m00_axi_awprot(m00_axi_awprot),
    .m00_axi_awqos(m00_axi_awqos), .m00_axi_awregion(m00_axi_awregion),
    .m00_axi_awuser(m00_axi_awuser), .m00_axi_awvalid(m00_axi_awvalid),
    .m00_axi_awready(m00_axi_awready), .m00_axi_wdata(m00_axi_wdata),
    .m00_axi_wstrb(m00_axi_wstrb), .m00_axi_wlast(m00_axi_wlast),
    .m00_axi_wuser(m00_axi_wuser), .m00_axi_wvalid(m00_axi_wvalid),
    .m00_axi_wready(m00_axi_wready), .m00_axi_bid(m00_axi_bid),
    .m00_axi_bresp(m00_axi_bresp), .m00_axi_buser(m00_axi_buser),
    .m00_axi_bvalid(m00_axi_bvalid), .m00_axi_bready(m00_axi_bready),
    .m00_axi_arid(m00_axi_arid), .m00_axi_araddr(m00_axi_araddr),
    .m00_axi_arlen(m00_axi_arlen), .m00_axi_arsize(m00_axi_arsize),
    .m00_axi_arburst(m00_axi_arburst), .m00_axi_arlock(m00_axi_arlock),
    .m00_axi_arcache(m00_axi_arcache), .m00_axi_arprot(m00_axi_arprot),
    .m00_axi_arqos(m00_axi_arqos), .m00_axi_arregion(m00_axi_arregion),
    .m00_axi_aruser(m00_axi_aruser), .m00_axi_arvalid(m00_axi_arvalid),
    .m00_axi_arready(m00_axi_arready), .m00_axi_rid(m00_axi_rid),
    .m00_axi_rdata(m00_axi_rdata), .m00_axi_rresp(m00_axi_rresp),
    .m00_axi_rlast(m00_axi_rlast), .m00_axi_ruser(m00_axi_ruser),
    .m00_axi_rvalid(m00_axi_rvalid), .m00_axi_rready(m00_axi_rready),

    .m01_axi_awid(m01_axi_awid), .m01_axi_awaddr(m01_axi_awaddr),
    .m01_axi_awlen(m01_axi_awlen), .m01_axi_awsize(m01_axi_awsize),
    .m01_axi_awburst(m01_axi_awburst), .m01_axi_awlock(m01_axi_awlock),
    .m01_axi_awcache(m01_axi_awcache), .m01_axi_awprot(m01_axi_awprot),
    .m01_axi_awqos(m01_axi_awqos), .m01_axi_awregion(m01_axi_awregion),
    .m01_axi_awuser(m01_axi_awuser), .m01_axi_awvalid(m01_axi_awvalid),
    .m01_axi_awready(m01_axi_awready), .m01_axi_wdata(m01_axi_wdata),
    .m01_axi_wstrb(m01_axi_wstrb), .m01_axi_wlast(m01_axi_wlast),
    .m01_axi_wuser(m01_axi_wuser), .m01_axi_wvalid(m01_axi_wvalid),
    .m01_axi_wready(m01_axi_wready), .m01_axi_bid(m01_axi_bid),
    .m01_axi_bresp(m01_axi_bresp), .m01_axi_buser(m01_axi_buser),
    .m01_axi_bvalid(m01_axi_bvalid), .m01_axi_bready(m01_axi_bready),
    .m01_axi_arid(m01_axi_arid), .m01_axi_araddr(m01_axi_araddr),
    .m01_axi_arlen(m01_axi_arlen), .m01_axi_arsize(m01_axi_arsize),
    .m01_axi_arburst(m01_axi_arburst), .m01_axi_arlock(m01_axi_arlock),
    .m01_axi_arcache(m01_axi_arcache), .m01_axi_arprot(m01_axi_arprot),
    .m01_axi_arqos(m01_axi_arqos), .m01_axi_arregion(m01_axi_arregion),
    .m01_axi_aruser(m01_axi_aruser), .m01_axi_arvalid(m01_axi_arvalid),
    .m01_axi_arready(m01_axi_arready), .m01_axi_rid(m01_axi_rid),
    .m01_axi_rdata(m01_axi_rdata), .m01_axi_rresp(m01_axi_rresp),
    .m01_axi_rlast(m01_axi_rlast), .m01_axi_ruser(m01_axi_ruser),
    .m01_axi_rvalid(m01_axi_rvalid), .m01_axi_rready(m01_axi_rready),

    .m02_axi_awid(m02_axi_awid), .m02_axi_awaddr(m02_axi_awaddr),
    .m02_axi_awlen(m02_axi_awlen), .m02_axi_awsize(m02_axi_awsize),
    .m02_axi_awburst(m02_axi_awburst), .m02_axi_awlock(m02_axi_awlock),
    .m02_axi_awcache(m02_axi_awcache), .m02_axi_awprot(m02_axi_awprot),
    .m02_axi_awqos(m02_axi_awqos), .m02_axi_awregion(m02_axi_awregion),
    .m02_axi_awuser(m02_axi_awuser), .m02_axi_awvalid(m02_axi_awvalid),
    .m02_axi_awready(m02_axi_awready), .m02_axi_wdata(m02_axi_wdata),
    .m02_axi_wstrb(m02_axi_wstrb), .m02_axi_wlast(m02_axi_wlast),
    .m02_axi_wuser(m02_axi_wuser), .m02_axi_wvalid(m02_axi_wvalid),
    .m02_axi_wready(m02_axi_wready), .m02_axi_bid(m02_axi_bid),
    .m02_axi_bresp(m02_axi_bresp), .m02_axi_buser(m02_axi_buser),
    .m02_axi_bvalid(m02_axi_bvalid), .m02_axi_bready(m02_axi_bready),
    .m02_axi_arid(m02_axi_arid), .m02_axi_araddr(m02_axi_araddr),
    .m02_axi_arlen(m02_axi_arlen), .m02_axi_arsize(m02_axi_arsize),
    .m02_axi_arburst(m02_axi_arburst), .m02_axi_arlock(m02_axi_arlock),
    .m02_axi_arcache(m02_axi_arcache), .m02_axi_arprot(m02_axi_arprot),
    .m02_axi_arqos(m02_axi_arqos), .m02_axi_arregion(m02_axi_arregion),
    .m02_axi_aruser(m02_axi_aruser), .m02_axi_arvalid(m02_axi_arvalid),
    .m02_axi_arready(m02_axi_arready), .m02_axi_rid(m02_axi_rid),
    .m02_axi_rdata(m02_axi_rdata), .m02_axi_rresp(m02_axi_rresp),
    .m02_axi_rlast(m02_axi_rlast), .m02_axi_ruser(m02_axi_ruser),
    .m02_axi_rvalid(m02_axi_rvalid), .m02_axi_rready(m02_axi_rready),

    .m03_axi_awid(m03_axi_awid), .m03_axi_awaddr(m03_axi_awaddr),
    .m03_axi_awlen(m03_axi_awlen), .m03_axi_awsize(m03_axi_awsize),
    .m03_axi_awburst(m03_axi_awburst), .m03_axi_awlock(m03_axi_awlock),
    .m03_axi_awcache(m03_axi_awcache), .m03_axi_awprot(m03_axi_awprot),
    .m03_axi_awqos(m03_axi_awqos), .m03_axi_awregion(m03_axi_awregion),
    .m03_axi_awuser(m03_axi_awuser), .m03_axi_awvalid(m03_axi_awvalid),
    .m03_axi_awready(m03_axi_awready), .m03_axi_wdata(m03_axi_wdata),
    .m03_axi_wstrb(m03_axi_wstrb), .m03_axi_wlast(m03_axi_wlast),
    .m03_axi_wuser(m03_axi_wuser), .m03_axi_wvalid(m03_axi_wvalid),
    .m03_axi_wready(m03_axi_wready), .m03_axi_bid(m03_axi_bid),
    .m03_axi_bresp(m03_axi_bresp), .m03_axi_buser(m03_axi_buser),
    .m03_axi_bvalid(m03_axi_bvalid), .m03_axi_bready(m03_axi_bready),
    .m03_axi_arid(m03_axi_arid), .m03_axi_araddr(m03_axi_araddr),
    .m03_axi_arlen(m03_axi_arlen), .m03_axi_arsize(m03_axi_arsize),
    .m03_axi_arburst(m03_axi_arburst), .m03_axi_arlock(m03_axi_arlock),
    .m03_axi_arcache(m03_axi_arcache), .m03_axi_arprot(m03_axi_arprot),
    .m03_axi_arqos(m03_axi_arqos), .m03_axi_arregion(m03_axi_arregion),
    .m03_axi_aruser(m03_axi_aruser), .m03_axi_arvalid(m03_axi_arvalid),
    .m03_axi_arready(m03_axi_arready), .m03_axi_rid(m03_axi_rid),
    .m03_axi_rdata(m03_axi_rdata), .m03_axi_rresp(m03_axi_rresp),
    .m03_axi_rlast(m03_axi_rlast), .m03_axi_ruser(m03_axi_ruser),
    .m03_axi_rvalid(m03_axi_rvalid), .m03_axi_rready(m03_axi_rready),

    .m04_axi_awid(m04_axi_awid), .m04_axi_awaddr(m04_axi_awaddr),
    .m04_axi_awlen(m04_axi_awlen), .m04_axi_awsize(m04_axi_awsize),
    .m04_axi_awburst(m04_axi_awburst), .m04_axi_awlock(m04_axi_awlock),
    .m04_axi_awcache(m04_axi_awcache), .m04_axi_awprot(m04_axi_awprot),
    .m04_axi_awqos(m04_axi_awqos), .m04_axi_awregion(m04_axi_awregion),
    .m04_axi_awuser(m04_axi_awuser), .m04_axi_awvalid(m04_axi_awvalid),
    .m04_axi_awready(m04_axi_awready), .m04_axi_wdata(m04_axi_wdata),
    .m04_axi_wstrb(m04_axi_wstrb), .m04_axi_wlast(m04_axi_wlast),
    .m04_axi_wuser(m04_axi_wuser), .m04_axi_wvalid(m04_axi_wvalid),
    .m04_axi_wready(m04_axi_wready), .m04_axi_bid(m04_axi_bid),
    .m04_axi_bresp(m04_axi_bresp), .m04_axi_buser(m04_axi_buser),
    .m04_axi_bvalid(m04_axi_bvalid), .m04_axi_bready(m04_axi_bready),
    .m04_axi_arid(m04_axi_arid), .m04_axi_araddr(m04_axi_araddr),
    .m04_axi_arlen(m04_axi_arlen), .m04_axi_arsize(m04_axi_arsize),
    .m04_axi_arburst(m04_axi_arburst), .m04_axi_arlock(m04_axi_arlock),
    .m04_axi_arcache(m04_axi_arcache), .m04_axi_arprot(m04_axi_arprot),
    .m04_axi_arqos(m04_axi_arqos), .m04_axi_arregion(m04_axi_arregion),
    .m04_axi_aruser(m04_axi_aruser), .m04_axi_arvalid(m04_axi_arvalid),
    .m04_axi_arready(m04_axi_arready), .m04_axi_rid(m04_axi_rid),
    .m04_axi_rdata(m04_axi_rdata), .m04_axi_rresp(m04_axi_rresp),
    .m04_axi_rlast(m04_axi_rlast), .m04_axi_ruser(m04_axi_ruser),
    .m04_axi_rvalid(m04_axi_rvalid), .m04_axi_rready(m04_axi_rready),

    .m05_axi_awid(m05_axi_awid), .m05_axi_awaddr(m05_axi_awaddr),
    .m05_axi_awlen(m05_axi_awlen), .m05_axi_awsize(m05_axi_awsize),
    .m05_axi_awburst(m05_axi_awburst), .m05_axi_awlock(m05_axi_awlock),
    .m05_axi_awcache(m05_axi_awcache), .m05_axi_awprot(m05_axi_awprot),
    .m05_axi_awqos(m05_axi_awqos), .m05_axi_awregion(m05_axi_awregion),
    .m05_axi_awuser(m05_axi_awuser), .m05_axi_awvalid(m05_axi_awvalid),
    .m05_axi_awready(m05_axi_awready), .m05_axi_wdata(m05_axi_wdata),
    .m05_axi_wstrb(m05_axi_wstrb), .m05_axi_wlast(m05_axi_wlast),
    .m05_axi_wuser(m05_axi_wuser), .m05_axi_wvalid(m05_axi_wvalid),
    .m05_axi_wready(m05_axi_wready), .m05_axi_bid(m05_axi_bid),
    .m05_axi_bresp(m05_axi_bresp), .m05_axi_buser(m05_axi_buser),
    .m05_axi_bvalid(m05_axi_bvalid), .m05_axi_bready(m05_axi_bready),
    .m05_axi_arid(m05_axi_arid), .m05_axi_araddr(m05_axi_araddr),
    .m05_axi_arlen(m05_axi_arlen), .m05_axi_arsize(m05_axi_arsize),
    .m05_axi_arburst(m05_axi_arburst), .m05_axi_arlock(m05_axi_arlock),
    .m05_axi_arcache(m05_axi_arcache), .m05_axi_arprot(m05_axi_arprot),
    .m05_axi_arqos(m05_axi_arqos), .m05_axi_arregion(m05_axi_arregion),
    .m05_axi_aruser(m05_axi_aruser), .m05_axi_arvalid(m05_axi_arvalid),
    .m05_axi_arready(m05_axi_arready), .m05_axi_rid(m05_axi_rid),
    .m05_axi_rdata(m05_axi_rdata), .m05_axi_rresp(m05_axi_rresp),
    .m05_axi_rlast(m05_axi_rlast), .m05_axi_ruser(m05_axi_ruser),
    .m05_axi_rvalid(m05_axi_rvalid), .m05_axi_rready(m05_axi_rready),

    .m06_axi_awid(m06_axi_awid), .m06_axi_awaddr(m06_axi_awaddr),
    .m06_axi_awlen(m06_axi_awlen), .m06_axi_awsize(m06_axi_awsize),
    .m06_axi_awburst(m06_axi_awburst), .m06_axi_awlock(m06_axi_awlock),
    .m06_axi_awcache(m06_axi_awcache), .m06_axi_awprot(m06_axi_awprot),
    .m06_axi_awqos(m06_axi_awqos), .m06_axi_awregion(m06_axi_awregion),
    .m06_axi_awuser(m06_axi_awuser), .m06_axi_awvalid(m06_axi_awvalid),
    .m06_axi_awready(m06_axi_awready), .m06_axi_wdata(m06_axi_wdata),
    .m06_axi_wstrb(m06_axi_wstrb), .m06_axi_wlast(m06_axi_wlast),
    .m06_axi_wuser(m06_axi_wuser), .m06_axi_wvalid(m06_axi_wvalid),
    .m06_axi_wready(m06_axi_wready), .m06_axi_bid(m06_axi_bid),
    .m06_axi_bresp(m06_axi_bresp), .m06_axi_buser(m06_axi_buser),
    .m06_axi_bvalid(m06_axi_bvalid), .m06_axi_bready(m06_axi_bready),
    .m06_axi_arid(m06_axi_arid), .m06_axi_araddr(m06_axi_araddr),
    .m06_axi_arlen(m06_axi_arlen), .m06_axi_arsize(m06_axi_arsize),
    .m06_axi_arburst(m06_axi_arburst), .m06_axi_arlock(m06_axi_arlock),
    .m06_axi_arcache(m06_axi_arcache), .m06_axi_arprot(m06_axi_arprot),
    .m06_axi_arqos(m06_axi_arqos), .m06_axi_arregion(m06_axi_arregion),
    .m06_axi_aruser(m06_axi_aruser), .m06_axi_arvalid(m06_axi_arvalid),
    .m06_axi_arready(m06_axi_arready), .m06_axi_rid(m06_axi_rid),
    .m06_axi_rdata(m06_axi_rdata), .m06_axi_rresp(m06_axi_rresp),
    .m06_axi_rlast(m06_axi_rlast), .m06_axi_ruser(m06_axi_ruser),
    .m06_axi_rvalid(m06_axi_rvalid), .m06_axi_rready(m06_axi_rready),

    .m07_axi_awid(m07_axi_awid), .m07_axi_awaddr(m07_axi_awaddr),
    .m07_axi_awlen(m07_axi_awlen), .m07_axi_awsize(m07_axi_awsize),
    .m07_axi_awburst(m07_axi_awburst), .m07_axi_awlock(m07_axi_awlock),
    .m07_axi_awcache(m07_axi_awcache), .m07_axi_awprot(m07_axi_awprot),
    .m07_axi_awqos(m07_axi_awqos), .m07_axi_awregion(m07_axi_awregion),
    .m07_axi_awuser(m07_axi_awuser), .m07_axi_awvalid(m07_axi_awvalid),
    .m07_axi_awready(m07_axi_awready), .m07_axi_wdata(m07_axi_wdata),
    .m07_axi_wstrb(m07_axi_wstrb), .m07_axi_wlast(m07_axi_wlast),
    .m07_axi_wuser(m07_axi_wuser), .m07_axi_wvalid(m07_axi_wvalid),
    .m07_axi_wready(m07_axi_wready), .m07_axi_bid(m07_axi_bid),
    .m07_axi_bresp(m07_axi_bresp), .m07_axi_buser(m07_axi_buser),
    .m07_axi_bvalid(m07_axi_bvalid), .m07_axi_bready(m07_axi_bready),
    .m07_axi_arid(m07_axi_arid), .m07_axi_araddr(m07_axi_araddr),
    .m07_axi_arlen(m07_axi_arlen), .m07_axi_arsize(m07_axi_arsize),
    .m07_axi_arburst(m07_axi_arburst), .m07_axi_arlock(m07_axi_arlock),
    .m07_axi_arcache(m07_axi_arcache), .m07_axi_arprot(m07_axi_arprot),
    .m07_axi_arqos(m07_axi_arqos), .m07_axi_arregion(m07_axi_arregion),
    .m07_axi_aruser(m07_axi_aruser), .m07_axi_arvalid(m07_axi_arvalid),
    .m07_axi_arready(m07_axi_arready), .m07_axi_rid(m07_axi_rid),
    .m07_axi_rdata(m07_axi_rdata), .m07_axi_rresp(m07_axi_rresp),
    .m07_axi_rlast(m07_axi_rlast), .m07_axi_ruser(m07_axi_ruser),
    .m07_axi_rvalid(m07_axi_rvalid), .m07_axi_rready(m07_axi_rready),

    .m08_axi_awid(m08_axi_awid), .m08_axi_awaddr(m08_axi_awaddr),
    .m08_axi_awlen(m08_axi_awlen), .m08_axi_awsize(m08_axi_awsize),
    .m08_axi_awburst(m08_axi_awburst), .m08_axi_awlock(m08_axi_awlock),
    .m08_axi_awcache(m08_axi_awcache), .m08_axi_awprot(m08_axi_awprot),
    .m08_axi_awqos(m08_axi_awqos), .m08_axi_awregion(m08_axi_awregion),
    .m08_axi_awuser(m08_axi_awuser), .m08_axi_awvalid(m08_axi_awvalid),
    .m08_axi_awready(m08_axi_awready), .m08_axi_wdata(m08_axi_wdata),
    .m08_axi_wstrb(m08_axi_wstrb), .m08_axi_wlast(m08_axi_wlast),
    .m08_axi_wuser(m08_axi_wuser), .m08_axi_wvalid(m08_axi_wvalid),
    .m08_axi_wready(m08_axi_wready), .m08_axi_bid(m08_axi_bid),
    .m08_axi_bresp(m08_axi_bresp), .m08_axi_buser(m08_axi_buser),
    .m08_axi_bvalid(m08_axi_bvalid), .m08_axi_bready(m08_axi_bready),
    .m08_axi_arid(m08_axi_arid), .m08_axi_araddr(m08_axi_araddr),
    .m08_axi_arlen(m08_axi_arlen), .m08_axi_arsize(m08_axi_arsize),
    .m08_axi_arburst(m08_axi_arburst), .m08_axi_arlock(m08_axi_arlock),
    .m08_axi_arcache(m08_axi_arcache), .m08_axi_arprot(m08_axi_arprot),
    .m08_axi_arqos(m08_axi_arqos), .m08_axi_arregion(m08_axi_arregion),
    .m08_axi_aruser(m08_axi_aruser), .m08_axi_arvalid(m08_axi_arvalid),
    .m08_axi_arready(m08_axi_arready), .m08_axi_rid(m08_axi_rid),
    .m08_axi_rdata(m08_axi_rdata), .m08_axi_rresp(m08_axi_rresp),
    .m08_axi_rlast(m08_axi_rlast), .m08_axi_ruser(m08_axi_ruser),
    .m08_axi_rvalid(m08_axi_rvalid), .m08_axi_rready(m08_axi_rready),

    .m09_axi_awid(m09_axi_awid), .m09_axi_awaddr(m09_axi_awaddr),
    .m09_axi_awlen(m09_axi_awlen), .m09_axi_awsize(m09_axi_awsize),
    .m09_axi_awburst(m09_axi_awburst), .m09_axi_awlock(m09_axi_awlock),
    .m09_axi_awcache(m09_axi_awcache), .m09_axi_awprot(m09_axi_awprot),
    .m09_axi_awqos(m09_axi_awqos), .m09_axi_awregion(m09_axi_awregion),
    .m09_axi_awuser(m09_axi_awuser), .m09_axi_awvalid(m09_axi_awvalid),
    .m09_axi_awready(m09_axi_awready), .m09_axi_wdata(m09_axi_wdata),
    .m09_axi_wstrb(m09_axi_wstrb), .m09_axi_wlast(m09_axi_wlast),
    .m09_axi_wuser(m09_axi_wuser), .m09_axi_wvalid(m09_axi_wvalid),
    .m09_axi_wready(m09_axi_wready), .m09_axi_bid(m09_axi_bid),
    .m09_axi_bresp(m09_axi_bresp), .m09_axi_buser(m09_axi_buser),
    .m09_axi_bvalid(m09_axi_bvalid), .m09_axi_bready(m09_axi_bready),
    .m09_axi_arid(m09_axi_arid), .m09_axi_araddr(m09_axi_araddr),
    .m09_axi_arlen(m09_axi_arlen), .m09_axi_arsize(m09_axi_arsize),
    .m09_axi_arburst(m09_axi_arburst), .m09_axi_arlock(m09_axi_arlock),
    .m09_axi_arcache(m09_axi_arcache), .m09_axi_arprot(m09_axi_arprot),
    .m09_axi_arqos(m09_axi_arqos), .m09_axi_arregion(m09_axi_arregion),
    .m09_axi_aruser(m09_axi_aruser), .m09_axi_arvalid(m09_axi_arvalid),
    .m09_axi_arready(m09_axi_arready), .m09_axi_rid(m09_axi_rid),
    .m09_axi_rdata(m09_axi_rdata), .m09_axi_rresp(m09_axi_rresp),
    .m09_axi_rlast(m09_axi_rlast), .m09_axi_ruser(m09_axi_ruser),
    .m09_axi_rvalid(m09_axi_rvalid), .m09_axi_rready(m09_axi_rready),

    .m10_axi_awid(m10_axi_awid), .m10_axi_awaddr(m10_axi_awaddr),
    .m10_axi_awlen(m10_axi_awlen), .m10_axi_awsize(m10_axi_awsize),
    .m10_axi_awburst(m10_axi_awburst), .m10_axi_awlock(m10_axi_awlock),
    .m10_axi_awcache(m10_axi_awcache), .m10_axi_awprot(m10_axi_awprot),
    .m10_axi_awqos(m10_axi_awqos), .m10_axi_awregion(m10_axi_awregion),
    .m10_axi_awuser(m10_axi_awuser), .m10_axi_awvalid(m10_axi_awvalid),
    .m10_axi_awready(m10_axi_awready), .m10_axi_wdata(m10_axi_wdata),
    .m10_axi_wstrb(m10_axi_wstrb), .m10_axi_wlast(m10_axi_wlast),
    .m10_axi_wuser(m10_axi_wuser), .m10_axi_wvalid(m10_axi_wvalid),
    .m10_axi_wready(m10_axi_wready), .m10_axi_bid(m10_axi_bid),
    .m10_axi_bresp(m10_axi_bresp), .m10_axi_buser(m10_axi_buser),
    .m10_axi_bvalid(m10_axi_bvalid), .m10_axi_bready(m10_axi_bready),
    .m10_axi_arid(m10_axi_arid), .m10_axi_araddr(m10_axi_araddr),
    .m10_axi_arlen(m10_axi_arlen), .m10_axi_arsize(m10_axi_arsize),
    .m10_axi_arburst(m10_axi_arburst), .m10_axi_arlock(m10_axi_arlock),
    .m10_axi_arcache(m10_axi_arcache), .m10_axi_arprot(m10_axi_arprot),
    .m10_axi_arqos(m10_axi_arqos), .m10_axi_arregion(m10_axi_arregion),
    .m10_axi_aruser(m10_axi_aruser), .m10_axi_arvalid(m10_axi_arvalid),
    .m10_axi_arready(m10_axi_arready), .m10_axi_rid(m10_axi_rid),
    .m10_axi_rdata(m10_axi_rdata), .m10_axi_rresp(m10_axi_rresp),
    .m10_axi_rlast(m10_axi_rlast), .m10_axi_ruser(m10_axi_ruser),
    .m10_axi_rvalid(m10_axi_rvalid), .m10_axi_rready(m10_axi_rready),

    .m11_axi_awid(m11_axi_awid), .m11_axi_awaddr(m11_axi_awaddr),
    .m11_axi_awlen(m11_axi_awlen), .m11_axi_awsize(m11_axi_awsize),
    .m11_axi_awburst(m11_axi_awburst), .m11_axi_awlock(m11_axi_awlock),
    .m11_axi_awcache(m11_axi_awcache), .m11_axi_awprot(m11_axi_awprot),
    .m11_axi_awqos(m11_axi_awqos), .m11_axi_awregion(m11_axi_awregion),
    .m11_axi_awuser(m11_axi_awuser), .m11_axi_awvalid(m11_axi_awvalid),
    .m11_axi_awready(m11_axi_awready), .m11_axi_wdata(m11_axi_wdata),
    .m11_axi_wstrb(m11_axi_wstrb), .m11_axi_wlast(m11_axi_wlast),
    .m11_axi_wuser(m11_axi_wuser), .m11_axi_wvalid(m11_axi_wvalid),
    .m11_axi_wready(m11_axi_wready), .m11_axi_bid(m11_axi_bid),
    .m11_axi_bresp(m11_axi_bresp), .m11_axi_buser(m11_axi_buser),
    .m11_axi_bvalid(m11_axi_bvalid), .m11_axi_bready(m11_axi_bready),
    .m11_axi_arid(m11_axi_arid), .m11_axi_araddr(m11_axi_araddr),
    .m11_axi_arlen(m11_axi_arlen), .m11_axi_arsize(m11_axi_arsize),
    .m11_axi_arburst(m11_axi_arburst), .m11_axi_arlock(m11_axi_arlock),
    .m11_axi_arcache(m11_axi_arcache), .m11_axi_arprot(m11_axi_arprot),
    .m11_axi_arqos(m11_axi_arqos), .m11_axi_arregion(m11_axi_arregion),
    .m11_axi_aruser(m11_axi_aruser), .m11_axi_arvalid(m11_axi_arvalid),
    .m11_axi_arready(m11_axi_arready), .m11_axi_rid(m11_axi_rid),
    .m11_axi_rdata(m11_axi_rdata), .m11_axi_rresp(m11_axi_rresp),
    .m11_axi_rlast(m11_axi_rlast), .m11_axi_ruser(m11_axi_ruser),
    .m11_axi_rvalid(m11_axi_rvalid), .m11_axi_rready(m11_axi_rready),

    .m12_axi_awid(m12_axi_awid), .m12_axi_awaddr(m12_axi_awaddr),
    .m12_axi_awlen(m12_axi_awlen), .m12_axi_awsize(m12_axi_awsize),
    .m12_axi_awburst(m12_axi_awburst), .m12_axi_awlock(m12_axi_awlock),
    .m12_axi_awcache(m12_axi_awcache), .m12_axi_awprot(m12_axi_awprot),
    .m12_axi_awqos(m12_axi_awqos), .m12_axi_awregion(m12_axi_awregion),
    .m12_axi_awuser(m12_axi_awuser), .m12_axi_awvalid(m12_axi_awvalid),
    .m12_axi_awready(m12_axi_awready), .m12_axi_wdata(m12_axi_wdata),
    .m12_axi_wstrb(m12_axi_wstrb), .m12_axi_wlast(m12_axi_wlast),
    .m12_axi_wuser(m12_axi_wuser), .m12_axi_wvalid(m12_axi_wvalid),
    .m12_axi_wready(m12_axi_wready), .m12_axi_bid(m12_axi_bid),
    .m12_axi_bresp(m12_axi_bresp), .m12_axi_buser(m12_axi_buser),
    .m12_axi_bvalid(m12_axi_bvalid), .m12_axi_bready(m12_axi_bready),
    .m12_axi_arid(m12_axi_arid), .m12_axi_araddr(m12_axi_araddr),
    .m12_axi_arlen(m12_axi_arlen), .m12_axi_arsize(m12_axi_arsize),
    .m12_axi_arburst(m12_axi_arburst), .m12_axi_arlock(m12_axi_arlock),
    .m12_axi_arcache(m12_axi_arcache), .m12_axi_arprot(m12_axi_arprot),
    .m12_axi_arqos(m12_axi_arqos), .m12_axi_arregion(m12_axi_arregion),
    .m12_axi_aruser(m12_axi_aruser), .m12_axi_arvalid(m12_axi_arvalid),
    .m12_axi_arready(m12_axi_arready), .m12_axi_rid(m12_axi_rid),
    .m12_axi_rdata(m12_axi_rdata), .m12_axi_rresp(m12_axi_rresp),
    .m12_axi_rlast(m12_axi_rlast), .m12_axi_ruser(m12_axi_ruser),
    .m12_axi_rvalid(m12_axi_rvalid), .m12_axi_rready(m12_axi_rready),

    .m13_axi_awid(m13_axi_awid), .m13_axi_awaddr(m13_axi_awaddr),
    .m13_axi_awlen(m13_axi_awlen), .m13_axi_awsize(m13_axi_awsize),
    .m13_axi_awburst(m13_axi_awburst), .m13_axi_awlock(m13_axi_awlock),
    .m13_axi_awcache(m13_axi_awcache), .m13_axi_awprot(m13_axi_awprot),
    .m13_axi_awqos(m13_axi_awqos), .m13_axi_awregion(m13_axi_awregion),
    .m13_axi_awuser(m13_axi_awuser), .m13_axi_awvalid(m13_axi_awvalid),
    .m13_axi_awready(m13_axi_awready), .m13_axi_wdata(m13_axi_wdata),
    .m13_axi_wstrb(m13_axi_wstrb), .m13_axi_wlast(m13_axi_wlast),
    .m13_axi_wuser(m13_axi_wuser), .m13_axi_wvalid(m13_axi_wvalid),
    .m13_axi_wready(m13_axi_wready), .m13_axi_bid(m13_axi_bid),
    .m13_axi_bresp(m13_axi_bresp), .m13_axi_buser(m13_axi_buser),
    .m13_axi_bvalid(m13_axi_bvalid), .m13_axi_bready(m13_axi_bready),
    .m13_axi_arid(m13_axi_arid), .m13_axi_araddr(m13_axi_araddr),
    .m13_axi_arlen(m13_axi_arlen), .m13_axi_arsize(m13_axi_arsize),
    .m13_axi_arburst(m13_axi_arburst), .m13_axi_arlock(m13_axi_arlock),
    .m13_axi_arcache(m13_axi_arcache), .m13_axi_arprot(m13_axi_arprot),
    .m13_axi_arqos(m13_axi_arqos), .m13_axi_arregion(m13_axi_arregion),
    .m13_axi_aruser(m13_axi_aruser), .m13_axi_arvalid(m13_axi_arvalid),
    .m13_axi_arready(m13_axi_arready), .m13_axi_rid(m13_axi_rid),
    .m13_axi_rdata(m13_axi_rdata), .m13_axi_rresp(m13_axi_rresp),
    .m13_axi_rlast(m13_axi_rlast), .m13_axi_ruser(m13_axi_ruser),
    .m13_axi_rvalid(m13_axi_rvalid), .m13_axi_rready(m13_axi_rready)
);

// ===========================================================================
// Slave Responder Logic  (one independent always block per slave port)
//
// Each responder:
//   Write path: accept AW, accept W beats, send B=OKAY
//   Read  path: accept AR, return rdata = {slaveN_id, araddr[7:0]} * beat_num
//               rlast on final beat
// ===========================================================================

// ---------- helper macro-like task (used inline per slave) -----------------
// We define one always block per slave to keep each self-contained.

// ---- Slave 0 (m00) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m00_axi_awready <= 1'b0; m00_axi_wready  <= 1'b0;
        m00_axi_bvalid  <= 1'b0; m00_axi_bid     <= '0;
        m00_axi_bresp   <= 2'b00; m00_axi_buser  <= '0;
        m00_axi_arready <= 1'b0; m00_axi_rvalid  <= 1'b0;
        m00_axi_rid     <= '0;   m00_axi_rdata   <= '0;
        m00_axi_rresp   <= 2'b00; m00_axi_rlast  <= 1'b0;
        m00_axi_ruser   <= '0;
    end else begin
        // Write address
        m00_axi_awready <= m00_axi_awvalid & ~m00_axi_awready;
        // Write data
        m00_axi_wready  <= m00_axi_wvalid  & ~m00_axi_wready;
        // Write response
        if (m00_axi_wvalid & m00_axi_wready & m00_axi_wlast) begin
            m00_axi_bvalid <= 1'b1;
            m00_axi_bid    <= m00_axi_awid;
            m00_axi_bresp  <= 2'b00;
        end else if (m00_axi_bvalid & m00_axi_bready)
            m00_axi_bvalid <= 1'b0;
        // Read address + data (single-beat for simplicity)
        m00_axi_arready <= m00_axi_arvalid & ~m00_axi_arready;
        if (m00_axi_arvalid & m00_axi_arready) begin
            m00_axi_rvalid <= 1'b1;
            m00_axi_rid    <= m00_axi_arid;
            m00_axi_rdata  <= {24'hC0_0000, m00_axi_araddr[7:0]};
            m00_axi_rresp  <= 2'b00;
            m00_axi_rlast  <= 1'b1;
        end else if (m00_axi_rvalid & m00_axi_rready) begin
            m00_axi_rvalid <= 1'b0;
            m00_axi_rlast  <= 1'b0;
        end
    end
end

// ---- Slave 1 (m01) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m01_axi_awready <= 1'b0; m01_axi_wready  <= 1'b0;
        m01_axi_bvalid  <= 1'b0; m01_axi_bid     <= '0;
        m01_axi_bresp   <= 2'b00; m01_axi_buser  <= '0;
        m01_axi_arready <= 1'b0; m01_axi_rvalid  <= 1'b0;
        m01_axi_rid     <= '0;   m01_axi_rdata   <= '0;
        m01_axi_rresp   <= 2'b00; m01_axi_rlast  <= 1'b0;
        m01_axi_ruser   <= '0;
    end else begin
        m01_axi_awready <= m01_axi_awvalid & ~m01_axi_awready;
        m01_axi_wready  <= m01_axi_wvalid  & ~m01_axi_wready;
        if (m01_axi_wvalid & m01_axi_wready & m01_axi_wlast) begin
            m01_axi_bvalid <= 1'b1; m01_axi_bid <= m01_axi_awid; m01_axi_bresp <= 2'b00;
        end else if (m01_axi_bvalid & m01_axi_bready) m01_axi_bvalid <= 1'b0;
        m01_axi_arready <= m01_axi_arvalid & ~m01_axi_arready;
        if (m01_axi_arvalid & m01_axi_arready) begin
            m01_axi_rvalid <= 1'b1; m01_axi_rid <= m01_axi_arid;
            m01_axi_rdata  <= {24'hC0_0001, m01_axi_araddr[7:0]};
            m01_axi_rresp  <= 2'b00; m01_axi_rlast <= 1'b1;
        end else if (m01_axi_rvalid & m01_axi_rready) begin
            m01_axi_rvalid <= 1'b0; m01_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 2 (m02) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m02_axi_awready <= 1'b0; m02_axi_wready  <= 1'b0;
        m02_axi_bvalid  <= 1'b0; m02_axi_bid     <= '0;
        m02_axi_bresp   <= 2'b00; m02_axi_buser  <= '0;
        m02_axi_arready <= 1'b0; m02_axi_rvalid  <= 1'b0;
        m02_axi_rid     <= '0;   m02_axi_rdata   <= '0;
        m02_axi_rresp   <= 2'b00; m02_axi_rlast  <= 1'b0;
        m02_axi_ruser   <= '0;
    end else begin
        m02_axi_awready <= m02_axi_awvalid & ~m02_axi_awready;
        m02_axi_wready  <= m02_axi_wvalid  & ~m02_axi_wready;
        if (m02_axi_wvalid & m02_axi_wready & m02_axi_wlast) begin
            m02_axi_bvalid <= 1'b1; m02_axi_bid <= m02_axi_awid; m02_axi_bresp <= 2'b00;
        end else if (m02_axi_bvalid & m02_axi_bready) m02_axi_bvalid <= 1'b0;
        m02_axi_arready <= m02_axi_arvalid & ~m02_axi_arready;
        if (m02_axi_arvalid & m02_axi_arready) begin
            m02_axi_rvalid <= 1'b1; m02_axi_rid <= m02_axi_arid;
            m02_axi_rdata  <= {24'hC0_0002, m02_axi_araddr[7:0]};
            m02_axi_rresp  <= 2'b00; m02_axi_rlast <= 1'b1;
        end else if (m02_axi_rvalid & m02_axi_rready) begin
            m02_axi_rvalid <= 1'b0; m02_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 3 (m03) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m03_axi_awready <= 1'b0; m03_axi_wready  <= 1'b0;
        m03_axi_bvalid  <= 1'b0; m03_axi_bid     <= '0;
        m03_axi_bresp   <= 2'b00; m03_axi_buser  <= '0;
        m03_axi_arready <= 1'b0; m03_axi_rvalid  <= 1'b0;
        m03_axi_rid     <= '0;   m03_axi_rdata   <= '0;
        m03_axi_rresp   <= 2'b00; m03_axi_rlast  <= 1'b0;
        m03_axi_ruser   <= '0;
    end else begin
        m03_axi_awready <= m03_axi_awvalid & ~m03_axi_awready;
        m03_axi_wready  <= m03_axi_wvalid  & ~m03_axi_wready;
        if (m03_axi_wvalid & m03_axi_wready & m03_axi_wlast) begin
            m03_axi_bvalid <= 1'b1; m03_axi_bid <= m03_axi_awid; m03_axi_bresp <= 2'b00;
        end else if (m03_axi_bvalid & m03_axi_bready) m03_axi_bvalid <= 1'b0;
        m03_axi_arready <= m03_axi_arvalid & ~m03_axi_arready;
        if (m03_axi_arvalid & m03_axi_arready) begin
            m03_axi_rvalid <= 1'b1; m03_axi_rid <= m03_axi_arid;
            m03_axi_rdata  <= {24'hC0_0003, m03_axi_araddr[7:0]};
            m03_axi_rresp  <= 2'b00; m03_axi_rlast <= 1'b1;
        end else if (m03_axi_rvalid & m03_axi_rready) begin
            m03_axi_rvalid <= 1'b0; m03_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 4 (m04) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m04_axi_awready <= 1'b0; m04_axi_wready  <= 1'b0;
        m04_axi_bvalid  <= 1'b0; m04_axi_bid     <= '0;
        m04_axi_bresp   <= 2'b00; m04_axi_buser  <= '0;
        m04_axi_arready <= 1'b0; m04_axi_rvalid  <= 1'b0;
        m04_axi_rid     <= '0;   m04_axi_rdata   <= '0;
        m04_axi_rresp   <= 2'b00; m04_axi_rlast  <= 1'b0;
        m04_axi_ruser   <= '0;
    end else begin
        m04_axi_awready <= m04_axi_awvalid & ~m04_axi_awready;
        m04_axi_wready  <= m04_axi_wvalid  & ~m04_axi_wready;
        if (m04_axi_wvalid & m04_axi_wready & m04_axi_wlast) begin
            m04_axi_bvalid <= 1'b1; m04_axi_bid <= m04_axi_awid; m04_axi_bresp <= 2'b00;
        end else if (m04_axi_bvalid & m04_axi_bready) m04_axi_bvalid <= 1'b0;
        m04_axi_arready <= m04_axi_arvalid & ~m04_axi_arready;
        if (m04_axi_arvalid & m04_axi_arready) begin
            m04_axi_rvalid <= 1'b1; m04_axi_rid <= m04_axi_arid;
            m04_axi_rdata  <= {24'hC0_0004, m04_axi_araddr[7:0]};
            m04_axi_rresp  <= 2'b00; m04_axi_rlast <= 1'b1;
        end else if (m04_axi_rvalid & m04_axi_rready) begin
            m04_axi_rvalid <= 1'b0; m04_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 5 (m05) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m05_axi_awready <= 1'b0; m05_axi_wready  <= 1'b0;
        m05_axi_bvalid  <= 1'b0; m05_axi_bid     <= '0;
        m05_axi_bresp   <= 2'b00; m05_axi_buser  <= '0;
        m05_axi_arready <= 1'b0; m05_axi_rvalid  <= 1'b0;
        m05_axi_rid     <= '0;   m05_axi_rdata   <= '0;
        m05_axi_rresp   <= 2'b00; m05_axi_rlast  <= 1'b0;
        m05_axi_ruser   <= '0;
    end else begin
        m05_axi_awready <= m05_axi_awvalid & ~m05_axi_awready;
        m05_axi_wready  <= m05_axi_wvalid  & ~m05_axi_wready;
        if (m05_axi_wvalid & m05_axi_wready & m05_axi_wlast) begin
            m05_axi_bvalid <= 1'b1; m05_axi_bid <= m05_axi_awid; m05_axi_bresp <= 2'b00;
        end else if (m05_axi_bvalid & m05_axi_bready) m05_axi_bvalid <= 1'b0;
        m05_axi_arready <= m05_axi_arvalid & ~m05_axi_arready;
        if (m05_axi_arvalid & m05_axi_arready) begin
            m05_axi_rvalid <= 1'b1; m05_axi_rid <= m05_axi_arid;
            m05_axi_rdata  <= {24'hC0_0005, m05_axi_araddr[7:0]};
            m05_axi_rresp  <= 2'b00; m05_axi_rlast <= 1'b1;
        end else if (m05_axi_rvalid & m05_axi_rready) begin
            m05_axi_rvalid <= 1'b0; m05_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 6 (m06) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m06_axi_awready <= 1'b0; m06_axi_wready  <= 1'b0;
        m06_axi_bvalid  <= 1'b0; m06_axi_bid     <= '0;
        m06_axi_bresp   <= 2'b00; m06_axi_buser  <= '0;
        m06_axi_arready <= 1'b0; m06_axi_rvalid  <= 1'b0;
        m06_axi_rid     <= '0;   m06_axi_rdata   <= '0;
        m06_axi_rresp   <= 2'b00; m06_axi_rlast  <= 1'b0;
        m06_axi_ruser   <= '0;
    end else begin
        m06_axi_awready <= m06_axi_awvalid & ~m06_axi_awready;
        m06_axi_wready  <= m06_axi_wvalid  & ~m06_axi_wready;
        if (m06_axi_wvalid & m06_axi_wready & m06_axi_wlast) begin
            m06_axi_bvalid <= 1'b1; m06_axi_bid <= m06_axi_awid; m06_axi_bresp <= 2'b00;
        end else if (m06_axi_bvalid & m06_axi_bready) m06_axi_bvalid <= 1'b0;
        m06_axi_arready <= m06_axi_arvalid & ~m06_axi_arready;
        if (m06_axi_arvalid & m06_axi_arready) begin
            m06_axi_rvalid <= 1'b1; m06_axi_rid <= m06_axi_arid;
            m06_axi_rdata  <= {24'hC0_0006, m06_axi_araddr[7:0]};
            m06_axi_rresp  <= 2'b00; m06_axi_rlast <= 1'b1;
        end else if (m06_axi_rvalid & m06_axi_rready) begin
            m06_axi_rvalid <= 1'b0; m06_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 7 (m07) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m07_axi_awready <= 1'b0; m07_axi_wready  <= 1'b0;
        m07_axi_bvalid  <= 1'b0; m07_axi_bid     <= '0;
        m07_axi_bresp   <= 2'b00; m07_axi_buser  <= '0;
        m07_axi_arready <= 1'b0; m07_axi_rvalid  <= 1'b0;
        m07_axi_rid     <= '0;   m07_axi_rdata   <= '0;
        m07_axi_rresp   <= 2'b00; m07_axi_rlast  <= 1'b0;
        m07_axi_ruser   <= '0;
    end else begin
        m07_axi_awready <= m07_axi_awvalid & ~m07_axi_awready;
        m07_axi_wready  <= m07_axi_wvalid  & ~m07_axi_wready;
        if (m07_axi_wvalid & m07_axi_wready & m07_axi_wlast) begin
            m07_axi_bvalid <= 1'b1; m07_axi_bid <= m07_axi_awid; m07_axi_bresp <= 2'b00;
        end else if (m07_axi_bvalid & m07_axi_bready) m07_axi_bvalid <= 1'b0;
        m07_axi_arready <= m07_axi_arvalid & ~m07_axi_arready;
        if (m07_axi_arvalid & m07_axi_arready) begin
            m07_axi_rvalid <= 1'b1; m07_axi_rid <= m07_axi_arid;
            m07_axi_rdata  <= {24'hC0_0007, m07_axi_araddr[7:0]};
            m07_axi_rresp  <= 2'b00; m07_axi_rlast <= 1'b1;
        end else if (m07_axi_rvalid & m07_axi_rready) begin
            m07_axi_rvalid <= 1'b0; m07_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 8 (m08) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m08_axi_awready <= 1'b0; m08_axi_wready  <= 1'b0;
        m08_axi_bvalid  <= 1'b0; m08_axi_bid     <= '0;
        m08_axi_bresp   <= 2'b00; m08_axi_buser  <= '0;
        m08_axi_arready <= 1'b0; m08_axi_rvalid  <= 1'b0;
        m08_axi_rid     <= '0;   m08_axi_rdata   <= '0;
        m08_axi_rresp   <= 2'b00; m08_axi_rlast  <= 1'b0;
        m08_axi_ruser   <= '0;
    end else begin
        m08_axi_awready <= m08_axi_awvalid & ~m08_axi_awready;
        m08_axi_wready  <= m08_axi_wvalid  & ~m08_axi_wready;
        if (m08_axi_wvalid & m08_axi_wready & m08_axi_wlast) begin
            m08_axi_bvalid <= 1'b1; m08_axi_bid <= m08_axi_awid; m08_axi_bresp <= 2'b00;
        end else if (m08_axi_bvalid & m08_axi_bready) m08_axi_bvalid <= 1'b0;
        m08_axi_arready <= m08_axi_arvalid & ~m08_axi_arready;
        if (m08_axi_arvalid & m08_axi_arready) begin
            m08_axi_rvalid <= 1'b1; m08_axi_rid <= m08_axi_arid;
            m08_axi_rdata  <= {24'hC0_0008, m08_axi_araddr[7:0]};
            m08_axi_rresp  <= 2'b00; m08_axi_rlast <= 1'b1;
        end else if (m08_axi_rvalid & m08_axi_rready) begin
            m08_axi_rvalid <= 1'b0; m08_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 9 (m09) --------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m09_axi_awready <= 1'b0; m09_axi_wready  <= 1'b0;
        m09_axi_bvalid  <= 1'b0; m09_axi_bid     <= '0;
        m09_axi_bresp   <= 2'b00; m09_axi_buser  <= '0;
        m09_axi_arready <= 1'b0; m09_axi_rvalid  <= 1'b0;
        m09_axi_rid     <= '0;   m09_axi_rdata   <= '0;
        m09_axi_rresp   <= 2'b00; m09_axi_rlast  <= 1'b0;
        m09_axi_ruser   <= '0;
    end else begin
        m09_axi_awready <= m09_axi_awvalid & ~m09_axi_awready;
        m09_axi_wready  <= m09_axi_wvalid  & ~m09_axi_wready;
        if (m09_axi_wvalid & m09_axi_wready & m09_axi_wlast) begin
            m09_axi_bvalid <= 1'b1; m09_axi_bid <= m09_axi_awid; m09_axi_bresp <= 2'b00;
        end else if (m09_axi_bvalid & m09_axi_bready) m09_axi_bvalid <= 1'b0;
        m09_axi_arready <= m09_axi_arvalid & ~m09_axi_arready;
        if (m09_axi_arvalid & m09_axi_arready) begin
            m09_axi_rvalid <= 1'b1; m09_axi_rid <= m09_axi_arid;
            m09_axi_rdata  <= {24'hC0_0009, m09_axi_araddr[7:0]};
            m09_axi_rresp  <= 2'b00; m09_axi_rlast <= 1'b1;
        end else if (m09_axi_rvalid & m09_axi_rready) begin
            m09_axi_rvalid <= 1'b0; m09_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 10 (m10) -------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m10_axi_awready <= 1'b0; m10_axi_wready  <= 1'b0;
        m10_axi_bvalid  <= 1'b0; m10_axi_bid     <= '0;
        m10_axi_bresp   <= 2'b00; m10_axi_buser  <= '0;
        m10_axi_arready <= 1'b0; m10_axi_rvalid  <= 1'b0;
        m10_axi_rid     <= '0;   m10_axi_rdata   <= '0;
        m10_axi_rresp   <= 2'b00; m10_axi_rlast  <= 1'b0;
        m10_axi_ruser   <= '0;
    end else begin
        m10_axi_awready <= m10_axi_awvalid & ~m10_axi_awready;
        m10_axi_wready  <= m10_axi_wvalid  & ~m10_axi_wready;
        if (m10_axi_wvalid & m10_axi_wready & m10_axi_wlast) begin
            m10_axi_bvalid <= 1'b1; m10_axi_bid <= m10_axi_awid; m10_axi_bresp <= 2'b00;
        end else if (m10_axi_bvalid & m10_axi_bready) m10_axi_bvalid <= 1'b0;
        m10_axi_arready <= m10_axi_arvalid & ~m10_axi_arready;
        if (m10_axi_arvalid & m10_axi_arready) begin
            m10_axi_rvalid <= 1'b1; m10_axi_rid <= m10_axi_arid;
            m10_axi_rdata  <= {24'hC0_000A, m10_axi_araddr[7:0]};
            m10_axi_rresp  <= 2'b00; m10_axi_rlast <= 1'b1;
        end else if (m10_axi_rvalid & m10_axi_rready) begin
            m10_axi_rvalid <= 1'b0; m10_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 11 (m11) -------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m11_axi_awready <= 1'b0; m11_axi_wready  <= 1'b0;
        m11_axi_bvalid  <= 1'b0; m11_axi_bid     <= '0;
        m11_axi_bresp   <= 2'b00; m11_axi_buser  <= '0;
        m11_axi_arready <= 1'b0; m11_axi_rvalid  <= 1'b0;
        m11_axi_rid     <= '0;   m11_axi_rdata   <= '0;
        m11_axi_rresp   <= 2'b00; m11_axi_rlast  <= 1'b0;
        m11_axi_ruser   <= '0;
    end else begin
        m11_axi_awready <= m11_axi_awvalid & ~m11_axi_awready;
        m11_axi_wready  <= m11_axi_wvalid  & ~m11_axi_wready;
        if (m11_axi_wvalid & m11_axi_wready & m11_axi_wlast) begin
            m11_axi_bvalid <= 1'b1; m11_axi_bid <= m11_axi_awid; m11_axi_bresp <= 2'b00;
        end else if (m11_axi_bvalid & m11_axi_bready) m11_axi_bvalid <= 1'b0;
        m11_axi_arready <= m11_axi_arvalid & ~m11_axi_arready;
        if (m11_axi_arvalid & m11_axi_arready) begin
            m11_axi_rvalid <= 1'b1; m11_axi_rid <= m11_axi_arid;
            m11_axi_rdata  <= {24'hC0_000B, m11_axi_araddr[7:0]};
            m11_axi_rresp  <= 2'b00; m11_axi_rlast <= 1'b1;
        end else if (m11_axi_rvalid & m11_axi_rready) begin
            m11_axi_rvalid <= 1'b0; m11_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 12 (m12) -------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m12_axi_awready <= 1'b0; m12_axi_wready  <= 1'b0;
        m12_axi_bvalid  <= 1'b0; m12_axi_bid     <= '0;
        m12_axi_bresp   <= 2'b00; m12_axi_buser  <= '0;
        m12_axi_arready <= 1'b0; m12_axi_rvalid  <= 1'b0;
        m12_axi_rid     <= '0;   m12_axi_rdata   <= '0;
        m12_axi_rresp   <= 2'b00; m12_axi_rlast  <= 1'b0;
        m12_axi_ruser   <= '0;
    end else begin
        m12_axi_awready <= m12_axi_awvalid & ~m12_axi_awready;
        m12_axi_wready  <= m12_axi_wvalid  & ~m12_axi_wready;
        if (m12_axi_wvalid & m12_axi_wready & m12_axi_wlast) begin
            m12_axi_bvalid <= 1'b1; m12_axi_bid <= m12_axi_awid; m12_axi_bresp <= 2'b00;
        end else if (m12_axi_bvalid & m12_axi_bready) m12_axi_bvalid <= 1'b0;
        m12_axi_arready <= m12_axi_arvalid & ~m12_axi_arready;
        if (m12_axi_arvalid & m12_axi_arready) begin
            m12_axi_rvalid <= 1'b1; m12_axi_rid <= m12_axi_arid;
            m12_axi_rdata  <= {24'hC0_000C, m12_axi_araddr[7:0]};
            m12_axi_rresp  <= 2'b00; m12_axi_rlast <= 1'b1;
        end else if (m12_axi_rvalid & m12_axi_rready) begin
            m12_axi_rvalid <= 1'b0; m12_axi_rlast <= 1'b0;
        end
    end
end

// ---- Slave 13 (m13) -------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        m13_axi_awready <= 1'b0; m13_axi_wready  <= 1'b0;
        m13_axi_bvalid  <= 1'b0; m13_axi_bid     <= '0;
        m13_axi_bresp   <= 2'b00; m13_axi_buser  <= '0;
        m13_axi_arready <= 1'b0; m13_axi_rvalid  <= 1'b0;
        m13_axi_rid     <= '0;   m13_axi_rdata   <= '0;
        m13_axi_rresp   <= 2'b00; m13_axi_rlast  <= 1'b0;
        m13_axi_ruser   <= '0;
    end else begin
        m13_axi_awready <= m13_axi_awvalid & ~m13_axi_awready;
        m13_axi_wready  <= m13_axi_wvalid  & ~m13_axi_wready;
        if (m13_axi_wvalid & m13_axi_wready & m13_axi_wlast) begin
            m13_axi_bvalid <= 1'b1; m13_axi_bid <= m13_axi_awid; m13_axi_bresp <= 2'b00;
        end else if (m13_axi_bvalid & m13_axi_bready) m13_axi_bvalid <= 1'b0;
        m13_axi_arready <= m13_axi_arvalid & ~m13_axi_arready;
        if (m13_axi_arvalid & m13_axi_arready) begin
            m13_axi_rvalid <= 1'b1; m13_axi_rid <= m13_axi_arid;
            m13_axi_rdata  <= {24'hC0_000D, m13_axi_araddr[7:0]};
            m13_axi_rresp  <= 2'b00; m13_axi_rlast <= 1'b1;
        end else if (m13_axi_rvalid & m13_axi_rready) begin
            m13_axi_rvalid <= 1'b0; m13_axi_rlast <= 1'b0;
        end
    end
end

// ===========================================================================
// Master Driver Tasks
// ===========================================================================

// ---------------------------------------------------------------------------
// Generic AXI write task  (operates on one master's signal bundle by name)
// We provide three concrete tasks: one per initiator port.
// ---------------------------------------------------------------------------

// ---- Master 0 (s00) write / read tasks ------------------------------------
task automatic s00_axi_write (
    input [ID_WIDTH-1:0]   id,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data
);
    integer timeout;
    // AW
    @(posedge clk);
    s00_axi_awid    <= id;
    s00_axi_awaddr  <= addr;
    s00_axi_awlen   <= 8'h00;      // 1 beat
    s00_axi_awsize  <= 3'b010;     // 4 bytes
    s00_axi_awburst <= 2'b01;      // INCR
    s00_axi_awlock  <= 1'b0;
    s00_axi_awcache <= 4'h0;
    s00_axi_awprot  <= 3'h0;
    s00_axi_awqos   <= 4'h0;
    s00_axi_awuser  <= 1'b0;
    s00_axi_awvalid <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s00_axi_awready) begin
        @(posedge clk);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s00 AW channel, addr=%0h", addr);
            fail_count++; disable s00_axi_write;
        end
    end
    s00_axi_awvalid <= 1'b0;
    // W
    s00_axi_wdata  <= data;
    s00_axi_wstrb  <= 4'hF;
    s00_axi_wlast  <= 1'b1;
    s00_axi_wuser  <= 1'b0;
    s00_axi_wvalid <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s00_axi_wready) begin
        @(posedge clk);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s00 W channel, addr=%0h", addr);
            fail_count++; disable s00_axi_write;
        end
    end
    s00_axi_wvalid <= 1'b0;
    s00_axi_wlast  <= 1'b0;
    // B
    s00_axi_bready <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s00_axi_bvalid) begin
        @(posedge clk);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s00 B channel, addr=%0h", addr);
            fail_count++; disable s00_axi_write;
        end
    end
    if (s00_axi_bresp !== 2'b00) begin
        $display("FAIL: s00 write bresp=%0b addr=%0h", s00_axi_bresp, addr);
        fail_count++;
    end else begin
        $display("PASS: s00 write addr=%0h data=%0h bresp=OKAY", addr, data);
        pass_count++;
    end
    s00_axi_bready <= 1'b0;
    @(posedge clk);
endtask

task automatic s00_axi_read (
    input  [ID_WIDTH-1:0]   id,
    input  [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] rdata_out
);
    integer timeout;
    // AR
    @(posedge clk);
    s00_axi_arid    <= id;
    s00_axi_araddr  <= addr;
    s00_axi_arlen   <= 8'h00;
    s00_axi_arsize  <= 3'b010;
    s00_axi_arburst <= 2'b01;
    s00_axi_arlock  <= 1'b0;
    s00_axi_arcache <= 4'h0;
    s00_axi_arprot  <= 3'h0;
    s00_axi_arqos   <= 4'h0;
    s00_axi_aruser  <= 1'b0;
    s00_axi_arvalid <= 1'b1;
    s00_axi_rready  <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s00_axi_arready) begin
        @(posedge clk);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s00 AR channel, addr=%0h", addr);
            fail_count++; disable s00_axi_read;
        end
    end
    s00_axi_arvalid <= 1'b0;
    // R
    timeout = 0;
    @(posedge clk);
    while (!s00_axi_rvalid) begin
        @(posedge clk);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s00 R channel, addr=%0h", addr);
            fail_count++; disable s00_axi_read;
        end
    end
    rdata_out = s00_axi_rdata;
    if (s00_axi_rresp !== 2'b00) begin
        $display("FAIL: s00 read rresp=%0b addr=%0h", s00_axi_rresp, addr);
        fail_count++;
    end else begin
        $display("PASS: s00 read  addr=%0h rdata=%0h rresp=OKAY", addr, s00_axi_rdata);
        pass_count++;
    end
    s00_axi_rready <= 1'b0;
    @(posedge clk);
endtask

// ---- Master 1 (s01) write / read tasks ------------------------------------
task automatic s01_axi_write (
    input [ID_WIDTH-1:0]   id,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data
);
    integer timeout;
    @(posedge clk);
    s01_axi_awid    <= id;   s01_axi_awaddr  <= addr;
    s01_axi_awlen   <= 8'h00; s01_axi_awsize  <= 3'b010;
    s01_axi_awburst <= 2'b01; s01_axi_awlock  <= 1'b0;
    s01_axi_awcache <= 4'h0;  s01_axi_awprot  <= 3'h0;
    s01_axi_awqos   <= 4'h0;  s01_axi_awuser  <= 1'b0;
    s01_axi_awvalid <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s01_axi_awready) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s01 AW channel, addr=%0h", addr);
            fail_count++; disable s01_axi_write;
        end
    end
    s01_axi_awvalid <= 1'b0;
    s01_axi_wdata  <= data;  s01_axi_wstrb  <= 4'hF;
    s01_axi_wlast  <= 1'b1; s01_axi_wuser  <= 1'b0;
    s01_axi_wvalid <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s01_axi_wready) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s01 W channel, addr=%0h", addr);
            fail_count++; disable s01_axi_write;
        end
    end
    s01_axi_wvalid <= 1'b0; s01_axi_wlast <= 1'b0;
    s01_axi_bready <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s01_axi_bvalid) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s01 B channel, addr=%0h", addr);
            fail_count++; disable s01_axi_write;
        end
    end
    if (s01_axi_bresp !== 2'b00) begin
        $display("FAIL: s01 write bresp=%0b addr=%0h", s01_axi_bresp, addr);
        fail_count++;
    end else begin
        $display("PASS: s01 write addr=%0h data=%0h bresp=OKAY", addr, data);
        pass_count++;
    end
    s01_axi_bready <= 1'b0;
    @(posedge clk);
endtask

task automatic s01_axi_read (
    input  [ID_WIDTH-1:0]   id,
    input  [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] rdata_out
);
    integer timeout;
    @(posedge clk);
    s01_axi_arid    <= id;    s01_axi_araddr  <= addr;
    s01_axi_arlen   <= 8'h00; s01_axi_arsize  <= 3'b010;
    s01_axi_arburst <= 2'b01; s01_axi_arlock  <= 1'b0;
    s01_axi_arcache <= 4'h0;  s01_axi_arprot  <= 3'h0;
    s01_axi_arqos   <= 4'h0;  s01_axi_aruser  <= 1'b0;
    s01_axi_arvalid <= 1'b1;  s01_axi_rready  <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s01_axi_arready) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s01 AR channel, addr=%0h", addr);
            fail_count++; disable s01_axi_read;
        end
    end
    s01_axi_arvalid <= 1'b0;
    timeout = 0;
    @(posedge clk);
    while (!s01_axi_rvalid) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s01 R channel, addr=%0h", addr);
            fail_count++; disable s01_axi_read;
        end
    end
    rdata_out = s01_axi_rdata;
    if (s01_axi_rresp !== 2'b00) begin
        $display("FAIL: s01 read rresp=%0b addr=%0h", s01_axi_rresp, addr);
        fail_count++;
    end else begin
        $display("PASS: s01 read  addr=%0h rdata=%0h rresp=OKAY", addr, s01_axi_rdata);
        pass_count++;
    end
    s01_axi_rready <= 1'b0;
    @(posedge clk);
endtask

// ---- Master 2 (s02) write / read tasks ------------------------------------
task automatic s02_axi_write (
    input [ID_WIDTH-1:0]   id,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data
);
    integer timeout;
    @(posedge clk);
    s02_axi_awid    <= id;   s02_axi_awaddr  <= addr;
    s02_axi_awlen   <= 8'h00; s02_axi_awsize  <= 3'b010;
    s02_axi_awburst <= 2'b01; s02_axi_awlock  <= 1'b0;
    s02_axi_awcache <= 4'h0;  s02_axi_awprot  <= 3'h0;
    s02_axi_awqos   <= 4'h0;  s02_axi_awuser  <= 1'b0;
    s02_axi_awvalid <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s02_axi_awready) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s02 AW channel, addr=%0h", addr);
            fail_count++; disable s02_axi_write;
        end
    end
    s02_axi_awvalid <= 1'b0;
    s02_axi_wdata  <= data;  s02_axi_wstrb  <= 4'hF;
    s02_axi_wlast  <= 1'b1; s02_axi_wuser  <= 1'b0;
    s02_axi_wvalid <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s02_axi_wready) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s02 W channel, addr=%0h", addr);
            fail_count++; disable s02_axi_write;
        end
    end
    s02_axi_wvalid <= 1'b0; s02_axi_wlast <= 1'b0;
    s02_axi_bready <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s02_axi_bvalid) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s02 B channel, addr=%0h", addr);
            fail_count++; disable s02_axi_write;
        end
    end
    if (s02_axi_bresp !== 2'b00) begin
        $display("FAIL: s02 write bresp=%0b addr=%0h", s02_axi_bresp, addr);
        fail_count++;
    end else begin
        $display("PASS: s02 write addr=%0h data=%0h bresp=OKAY", addr, data);
        pass_count++;
    end
    s02_axi_bready <= 1'b0;
    @(posedge clk);
endtask

task automatic s02_axi_read (
    input  [ID_WIDTH-1:0]   id,
    input  [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] rdata_out
);
    integer timeout;
    @(posedge clk);
    s02_axi_arid    <= id;    s02_axi_araddr  <= addr;
    s02_axi_arlen   <= 8'h00; s02_axi_arsize  <= 3'b010;
    s02_axi_arburst <= 2'b01; s02_axi_arlock  <= 1'b0;
    s02_axi_arcache <= 4'h0;  s02_axi_arprot  <= 3'h0;
    s02_axi_arqos   <= 4'h0;  s02_axi_aruser  <= 1'b0;
    s02_axi_arvalid <= 1'b1;  s02_axi_rready  <= 1'b1;
    timeout = 0;
    @(posedge clk);
    while (!s02_axi_arready) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s02 AR channel, addr=%0h", addr);
            fail_count++; disable s02_axi_read;
        end
    end
    s02_axi_arvalid <= 1'b0;
    timeout = 0;
    @(posedge clk);
    while (!s02_axi_rvalid) begin
        @(posedge clk); timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("TIMEOUT: s02 R channel, addr=%0h", addr);
            fail_count++; disable s02_axi_read;
        end
    end
    rdata_out = s02_axi_rdata;
    if (s02_axi_rresp !== 2'b00) begin
        $display("FAIL: s02 read rresp=%0b addr=%0h", s02_axi_rresp, addr);
        fail_count++;
    end else begin
        $display("PASS: s02 read  addr=%0h rdata=%0h rresp=OKAY", addr, s02_axi_rdata);
        pass_count++;
    end
    s02_axi_rready <= 1'b0;
    @(posedge clk);
endtask

// ===========================================================================
// Initial block — reset, then run test stimulus
// ===========================================================================
logic [DATA_WIDTH-1:0] rd_data;

initial begin
    // ------------------------------------------------------------------
    // Initialise all master-drive signals to idle
    // ------------------------------------------------------------------
    pass_count = 0; fail_count = 0;
    rst = 1'b1;

    // s00 idle
    s00_axi_awid=0; s00_axi_awaddr=0; s00_axi_awlen=0; s00_axi_awsize=0;
    s00_axi_awburst=0; s00_axi_awlock=0; s00_axi_awcache=0; s00_axi_awprot=0;
    s00_axi_awqos=0; s00_axi_awuser=0; s00_axi_awvalid=0;
    s00_axi_wdata=0; s00_axi_wstrb=0; s00_axi_wlast=0; s00_axi_wuser=0;
    s00_axi_wvalid=0; s00_axi_bready=0;
    s00_axi_arid=0; s00_axi_araddr=0; s00_axi_arlen=0; s00_axi_arsize=0;
    s00_axi_arburst=0; s00_axi_arlock=0; s00_axi_arcache=0; s00_axi_arprot=0;
    s00_axi_arqos=0; s00_axi_aruser=0; s00_axi_arvalid=0; s00_axi_rready=0;

    // s01 idle
    s01_axi_awid=0; s01_axi_awaddr=0; s01_axi_awlen=0; s01_axi_awsize=0;
    s01_axi_awburst=0; s01_axi_awlock=0; s01_axi_awcache=0; s01_axi_awprot=0;
    s01_axi_awqos=0; s01_axi_awuser=0; s01_axi_awvalid=0;
    s01_axi_wdata=0; s01_axi_wstrb=0; s01_axi_wlast=0; s01_axi_wuser=0;
    s01_axi_wvalid=0; s01_axi_bready=0;
    s01_axi_arid=0; s01_axi_araddr=0; s01_axi_arlen=0; s01_axi_arsize=0;
    s01_axi_arburst=0; s01_axi_arlock=0; s01_axi_arcache=0; s01_axi_arprot=0;
    s01_axi_arqos=0; s01_axi_aruser=0; s01_axi_arvalid=0; s01_axi_rready=0;

    // s02 idle
    s02_axi_awid=0; s02_axi_awaddr=0; s02_axi_awlen=0; s02_axi_awsize=0;
    s02_axi_awburst=0; s02_axi_awlock=0; s02_axi_awcache=0; s02_axi_awprot=0;
    s02_axi_awqos=0; s02_axi_awuser=0; s02_axi_awvalid=0;
    s02_axi_wdata=0; s02_axi_wstrb=0; s02_axi_wlast=0; s02_axi_wuser=0;
    s02_axi_wvalid=0; s02_axi_bready=0;
    s02_axi_arid=0; s02_axi_araddr=0; s02_axi_arlen=0; s02_axi_arsize=0;
    s02_axi_arburst=0; s02_axi_arlock=0; s02_axi_arcache=0; s02_axi_arprot=0;
    s02_axi_arqos=0; s02_axi_aruser=0; s02_axi_arvalid=0; s02_axi_rready=0;

    // ------------------------------------------------------------------
    // Apply reset for 10 cycles
    // ------------------------------------------------------------------
    repeat (10) @(posedge clk);
    rst = 1'b0;
    repeat (4)  @(posedge clk);

    $display("\n=== TEST: s00 writes to all 14 slaves ===");
    s00_axi_write(8'h10, BASE_M00 + 32'h00, 32'hDEAD_0000);
    s00_axi_write(8'h11, BASE_M01 + 32'h04, 32'hDEAD_0001);
    s00_axi_write(8'h12, BASE_M02 + 32'h08, 32'hDEAD_0002);
    s00_axi_write(8'h13, BASE_M03 + 32'h0C, 32'hDEAD_0003);
    s00_axi_write(8'h14, BASE_M04 + 32'h10, 32'hDEAD_0004);
    s00_axi_write(8'h15, BASE_M05 + 32'h14, 32'hDEAD_0005);
    s00_axi_write(8'h16, BASE_M06 + 32'h18, 32'hDEAD_0006);
    s00_axi_write(8'h17, BASE_M07 + 32'h1C, 32'hDEAD_0007);
    s00_axi_write(8'h18, BASE_M08 + 32'h20, 32'hDEAD_0008);
    s00_axi_write(8'h19, BASE_M09 + 32'h24, 32'hDEAD_0009);
    s00_axi_write(8'h1A, BASE_M10 + 32'h28, 32'hDEAD_000A);
    s00_axi_write(8'h1B, BASE_M11 + 32'h2C, 32'hDEAD_000B);
    s00_axi_write(8'h1C, BASE_M12 + 32'h30, 32'hDEAD_000C);
    s00_axi_write(8'h1D, BASE_M13 + 32'h34, 32'hDEAD_000D);

    $display("\n=== TEST: s00 reads from all 14 slaves ===");
    s00_axi_read(8'h20, BASE_M00 + 32'h00, rd_data);
    s00_axi_read(8'h21, BASE_M01 + 32'h04, rd_data);
    s00_axi_read(8'h22, BASE_M02 + 32'h08, rd_data);
    s00_axi_read(8'h23, BASE_M03 + 32'h0C, rd_data);
    s00_axi_read(8'h24, BASE_M04 + 32'h10, rd_data);
    s00_axi_read(8'h25, BASE_M05 + 32'h14, rd_data);
    s00_axi_read(8'h26, BASE_M06 + 32'h18, rd_data);
    s00_axi_read(8'h27, BASE_M07 + 32'h1C, rd_data);
    s00_axi_read(8'h28, BASE_M08 + 32'h20, rd_data);
    s00_axi_read(8'h29, BASE_M09 + 32'h24, rd_data);
    s00_axi_read(8'h2A, BASE_M10 + 32'h28, rd_data);
    s00_axi_read(8'h2B, BASE_M11 + 32'h2C, rd_data);
    s00_axi_read(8'h2C, BASE_M12 + 32'h30, rd_data);
    s00_axi_read(8'h2D, BASE_M13 + 32'h34, rd_data);

    $display("\n=== TEST: s01 writes to selected slaves ===");
    s01_axi_write(8'h30, BASE_M00 + 32'h40, 32'hBEEF_AA00);
    s01_axi_write(8'h31, BASE_M05 + 32'h44, 32'hBEEF_AA05);
    s01_axi_write(8'h32, BASE_M09 + 32'h48, 32'hBEEF_AA09);
    s01_axi_write(8'h33, BASE_M13 + 32'h4C, 32'hBEEF_AA0D);

    $display("\n=== TEST: s01 reads from selected slaves ===");
    s01_axi_read(8'h40, BASE_M00 + 32'h40, rd_data);
    s01_axi_read(8'h41, BASE_M07 + 32'h44, rd_data);
    s01_axi_read(8'h42, BASE_M13 + 32'h48, rd_data);

    $display("\n=== TEST: s02 writes to selected slaves ===");
    s02_axi_write(8'h50, BASE_M02 + 32'h50, 32'hCAFE_0002);
    s02_axi_write(8'h51, BASE_M06 + 32'h54, 32'hCAFE_0006);
    s02_axi_write(8'h52, BASE_M11 + 32'h58, 32'hCAFE_000B);

    $display("\n=== TEST: s02 reads from selected slaves ===");
    s02_axi_read(8'h60, BASE_M02 + 32'h50, rd_data);
    s02_axi_read(8'h61, BASE_M06 + 32'h54, rd_data);
    s02_axi_read(8'h62, BASE_M11 + 32'h58, rd_data);
    s02_axi_read(8'h63, BASE_M13 + 32'h5C, rd_data);

    repeat (8) @(posedge clk);

    // ------------------------------------------------------------------
    // Summary
    // ------------------------------------------------------------------
    $display("\n============================================");
    $display("  SIMULATION COMPLETE");
    $display("  PASS : %0d", pass_count);
    $display("  FAIL : %0d", fail_count);
    if (fail_count == 0)
        $display("  RESULT : *** ALL TESTS PASSED ***");
    else
        $display("  RESULT : *** %0d TEST(S) FAILED ***", fail_count);
    $display("============================================\n");
    $finish;
end

// ===========================================================================
// Simulation watchdog  — kills the run if it hangs past TIMEOUT_CYCLES
// ===========================================================================
initial begin
    #(TIMEOUT_CYCLES * 10 * 2);   // 2x the per-handshake budget in ns
    $display("FATAL: global simulation timeout — possible deadlock");
    $finish(2);
end
initial
begin
$fsdbDumpfile("dump.fsdb");
$fsdbDumpvars("+all");
$fsdbDumpSVA;
$fsdbDumpMDA;
end

endmodule
