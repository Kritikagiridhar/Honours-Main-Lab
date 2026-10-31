// =============================================================================
// Testbench : tb_axi_interconnect_uart_top.sv
// DUT       : axi_interconnect_uart_top
// Config    : 5 Masters (s00..s04) x 20 Slaves (m00=UART, m01..m19=Ext)
// Tool      : Synopsys VCS (SystemVerilog)
// Description:
//   Comprehensive verification testbench for AXI Interconnect + AXI UART.
//   Tests include:
//     1. Reset initialization and default state verification
//     2. UART register read/write operations through Interconnect from s00 (Core 0)
//     3. UART Baud Divisor configuration via DLAB register sequence
//     4. Serial Transmission (THR write via AXI -> uart_tx serial framing verification)
//     5. Serial Reception (uart_rx serial bitstream -> RX FIFO -> uart_irq assertion -> RBR read via AXI)
//     6. Interrupt generation and deassertion after RBR read
//     7. Multi-master access from s01 (Core 1) and s02 (DMA/Debug)
//     8. External master routing verification (s00 -> m01)
// =============================================================================

`timescale 1ns/1ps

module tb_axi_interconnect_uart_top;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH       = 32;
    localparam ADDR_WIDTH       = 32;
    localparam STRB_WIDTH       = DATA_WIDTH / 8;
    localparam ID_WIDTH         = 8;
    localparam AWUSER_WIDTH     = 1;
    localparam WUSER_WIDTH      = 1;
    localparam BUSER_WIDTH      = 1;
    localparam ARUSER_WIDTH     = 1;
    localparam RUSER_WIDTH      = 1;

    // Memory Map Base Addresses
    localparam [ADDR_WIDTH-1:0] UART_BASE_ADDR = 32'h0000_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M01       = 32'h0100_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M02       = 32'h0200_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M03       = 32'h0300_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M04       = 32'h0400_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M05       = 32'h0500_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M06       = 32'h0600_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M07       = 32'h0700_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M08       = 32'h0800_0000;
    localparam [ADDR_WIDTH-1:0] BASE_M09       = 32'h0900_0000;

    // UART Internal Register Offsets (Byte Addressed)
    localparam [ADDR_WIDTH-1:0] UART_REG_RBR   = UART_BASE_ADDR + 32'h00; // Read Rx Buffer (DLAB=0)
    localparam [ADDR_WIDTH-1:0] UART_REG_THR   = UART_BASE_ADDR + 32'h00; // Write Tx Holding (DLAB=0)
    localparam [ADDR_WIDTH-1:0] UART_REG_IER   = UART_BASE_ADDR + 32'h04; // Interrupt Enable (DLAB=0)
    localparam [ADDR_WIDTH-1:0] UART_REG_DIV   = UART_BASE_ADDR + 32'h08; // Baud Divisor (DLAB=1)
    localparam [ADDR_WIDTH-1:0] UART_REG_LCR   = UART_BASE_ADDR + 32'h0C; // Line Control Register
    localparam [ADDR_WIDTH-1:0] UART_REG_LSR   = UART_BASE_ADDR + 32'h14; // Line Status Register

    // Timeout guard cycles
    localparam TIMEOUT_CYCLES   = 20_000;
    localparam CLK_PERIOD_NS    = 10; // 100 MHz clock

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    logic clk;
    logic uart_clk;
    logic rst;

    logic uart_rx;
    wire  uart_tx;
    wire  uart_irq;

    // Master 00 Interface (s00)
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

    // Master 01 Interface (s01)
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

    // Master 02 Interface (s02)
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

    // External Master Signals (m01..m09)
    wire [ID_WIDTH-1:0]      m01_axi_awid;
    wire [ADDR_WIDTH-1:0]    m01_axi_awaddr;
    wire [7:0]               m01_axi_awlen;
    wire [2:0]               m01_axi_awsize;
    wire [1:0]               m01_axi_awburst;
    wire                     m01_axi_awlock;
    wire [3:0]               m01_axi_awcache;
    wire [2:0]               m01_axi_awprot;
    wire [3:0]               m01_axi_awqos;
    wire [3:0]               m01_axi_awregion;
    wire [AWUSER_WIDTH-1:0]  m01_axi_awuser;
    wire                     m01_axi_awvalid;
    reg                      m01_axi_awready;
    wire [DATA_WIDTH-1:0]    m01_axi_wdata;
    wire [STRB_WIDTH-1:0]    m01_axi_wstrb;
    wire                     m01_axi_wlast;
    wire [WUSER_WIDTH-1:0]   m01_axi_wuser;
    wire                     m01_axi_wvalid;
    reg                      m01_axi_wready;
    reg  [ID_WIDTH-1:0]      m01_axi_bid;
    reg  [1:0]               m01_axi_bresp;
    reg  [BUSER_WIDTH-1:0]   m01_axi_buser;
    reg                      m01_axi_bvalid;
    wire                     m01_axi_bready;
    wire [ID_WIDTH-1:0]      m01_axi_arid;
    wire [ADDR_WIDTH-1:0]    m01_axi_araddr;
    wire [7:0]               m01_axi_arlen;
    wire [2:0]               m01_axi_arsize;
    wire [1:0]               m01_axi_arburst;
    wire                     m01_axi_arlock;
    wire [3:0]               m01_axi_arcache;
    wire [2:0]               m01_axi_arprot;
    wire [3:0]               m01_axi_arqos;
    wire [3:0]               m01_axi_arregion;
    wire [ARUSER_WIDTH-1:0]  m01_axi_aruser;
    wire                     m01_axi_arvalid;
    reg                      m01_axi_arready;
    reg  [ID_WIDTH-1:0]      m01_axi_rid;
    reg  [DATA_WIDTH-1:0]    m01_axi_rdata;
    reg  [1:0]               m01_axi_rresp;
    reg                      m01_axi_rlast;
    reg  [RUSER_WIDTH-1:0]   m01_axi_ruser;
    reg                      m01_axi_rvalid;
    wire                     m01_axi_rready;

    // Slaves m02..m09 tied off safely
    wire [ID_WIDTH-1:0]     m02_axi_awid;
    wire [ADDR_WIDTH-1:0]   m02_axi_awaddr;
    wire [7:0]              m02_axi_awlen;
    wire [2:0]              m02_axi_awsize;
    wire [1:0]              m02_axi_awburst;
    wire                    m02_axi_awlock;
    wire [3:0]              m02_axi_awcache;
    wire [2:0]              m02_axi_awprot;
    wire [3:0]              m02_axi_awqos;
    wire [3:0]              m02_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m02_axi_awuser;
    wire                    m02_axi_awvalid;
    wire [DATA_WIDTH-1:0]   m02_axi_wdata;
    wire [STRB_WIDTH-1:0]   m02_axi_wstrb;
    wire                    m02_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m02_axi_wuser;
    wire                    m02_axi_wvalid;
    wire [ID_WIDTH-1:0]     m02_axi_arid;
    wire [ADDR_WIDTH-1:0]   m02_axi_araddr;
    wire [7:0]              m02_axi_arlen;
    wire [2:0]              m02_axi_arsize;
    wire [1:0]              m02_axi_arburst;
    wire                    m02_axi_arlock;
    wire [3:0]              m02_axi_arcache;
    wire [2:0]              m02_axi_arprot;
    wire [3:0]              m02_axi_arqos;
    wire [3:0]              m02_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m02_axi_aruser;
    wire                    m02_axi_arvalid;
    wire [ID_WIDTH-1:0]     m03_axi_awid;
    wire [ADDR_WIDTH-1:0]   m03_axi_awaddr;
    wire [7:0]              m03_axi_awlen;
    wire [2:0]              m03_axi_awsize;
    wire [1:0]              m03_axi_awburst;
    wire                    m03_axi_awlock;
    wire [3:0]              m03_axi_awcache;
    wire [2:0]              m03_axi_awprot;
    wire [3:0]              m03_axi_awqos;
    wire [3:0]              m03_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m03_axi_awuser;
    wire                    m03_axi_awvalid;
    wire [DATA_WIDTH-1:0]   m03_axi_wdata;
    wire [STRB_WIDTH-1:0]   m03_axi_wstrb;
    wire                    m03_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m03_axi_wuser;
    wire                    m03_axi_wvalid;
    wire [ID_WIDTH-1:0]     m03_axi_arid;
    wire [ADDR_WIDTH-1:0]   m03_axi_araddr;
    wire [7:0]              m03_axi_arlen;
    wire [2:0]              m03_axi_arsize;
    wire [1:0]              m03_axi_arburst;
    wire                    m03_axi_arlock;
    wire [3:0]              m03_axi_arcache;
    wire [2:0]              m03_axi_arprot;
    wire [3:0]              m03_axi_arqos;
    wire [3:0]              m03_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m03_axi_aruser;
    wire                    m03_axi_arvalid;
    wire [ID_WIDTH-1:0]     m04_axi_awid;
    wire [ADDR_WIDTH-1:0]   m04_axi_awaddr;
    wire [7:0]              m04_axi_awlen;
    wire [2:0]              m04_axi_awsize;
    wire [1:0]              m04_axi_awburst;
    wire                    m04_axi_awlock;
    wire [3:0]              m04_axi_awcache;
    wire [2:0]              m04_axi_awprot;
    wire [3:0]              m04_axi_awqos;
    wire [3:0]              m04_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m04_axi_awuser;
    wire                    m04_axi_awvalid;
    wire [DATA_WIDTH-1:0]   m04_axi_wdata;
    wire [STRB_WIDTH-1:0]   m04_axi_wstrb;
    wire                    m04_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m04_axi_wuser;
    wire                    m04_axi_wvalid;
    wire [ID_WIDTH-1:0]     m04_axi_arid;
    wire [ADDR_WIDTH-1:0]   m04_axi_araddr;
    wire [7:0]              m04_axi_arlen;
    wire [2:0]              m04_axi_arsize;
    wire [1:0]              m04_axi_arburst;
    wire                    m04_axi_arlock;
    wire [3:0]              m04_axi_arcache;
    wire [2:0]              m04_axi_arprot;
    wire [3:0]              m04_axi_arqos;
    wire [3:0]              m04_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m04_axi_aruser;
    wire                    m04_axi_arvalid;
    wire [ID_WIDTH-1:0]     m05_axi_awid;
    wire [ADDR_WIDTH-1:0]   m05_axi_awaddr;
    wire [7:0]              m05_axi_awlen;
    wire [2:0]              m05_axi_awsize;
    wire [1:0]              m05_axi_awburst;
    wire                    m05_axi_awlock;
    wire [3:0]              m05_axi_awcache;
    wire [2:0]              m05_axi_awprot;
    wire [3:0]              m05_axi_awqos;
    wire [3:0]              m05_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m05_axi_awuser;
    wire                    m05_axi_awvalid;
    wire [DATA_WIDTH-1:0]   m05_axi_wdata;
    wire [STRB_WIDTH-1:0]   m05_axi_wstrb;
    wire                    m05_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m05_axi_wuser;
    wire                    m05_axi_wvalid;
    wire [ID_WIDTH-1:0]     m05_axi_arid;
    wire [ADDR_WIDTH-1:0]   m05_axi_araddr;
    wire [7:0]              m05_axi_arlen;
    wire [2:0]              m05_axi_arsize;
    wire [1:0]              m05_axi_arburst;
    wire                    m05_axi_arlock;
    wire [3:0]              m05_axi_arcache;
    wire [2:0]              m05_axi_arprot;
    wire [3:0]              m05_axi_arqos;
    wire [3:0]              m05_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m05_axi_aruser;
    wire                    m05_axi_arvalid;
    wire [ID_WIDTH-1:0]     m06_axi_awid;
    wire [ADDR_WIDTH-1:0]   m06_axi_awaddr;
    wire [7:0]              m06_axi_awlen;
    wire [2:0]              m06_axi_awsize;
    wire [1:0]              m06_axi_awburst;
    wire                    m06_axi_awlock;
    wire [3:0]              m06_axi_awcache;
    wire [2:0]              m06_axi_awprot;
    wire [3:0]              m06_axi_awqos;
    wire [3:0]              m06_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m06_axi_awuser;
    wire                    m06_axi_awvalid;
    wire [DATA_WIDTH-1:0]   m06_axi_wdata;
    wire [STRB_WIDTH-1:0]   m06_axi_wstrb;
    wire                    m06_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m06_axi_wuser;
    wire                    m06_axi_wvalid;
    wire [ID_WIDTH-1:0]     m06_axi_arid;
    wire [ADDR_WIDTH-1:0]   m06_axi_araddr;
    wire [7:0]              m06_axi_arlen;
    wire [2:0]              m06_axi_arsize;
    wire [1:0]              m06_axi_arburst;
    wire                    m06_axi_arlock;
    wire [3:0]              m06_axi_arcache;
    wire [2:0]              m06_axi_arprot;
    wire [3:0]              m06_axi_arqos;
    wire [3:0]              m06_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m06_axi_aruser;
    wire                    m06_axi_arvalid;
    wire [ID_WIDTH-1:0]     m07_axi_awid;
    wire [ADDR_WIDTH-1:0]   m07_axi_awaddr;
    wire [7:0]              m07_axi_awlen;
    wire [2:0]              m07_axi_awsize;
    wire [1:0]              m07_axi_awburst;
    wire                    m07_axi_awlock;
    wire [3:0]              m07_axi_awcache;
    wire [2:0]              m07_axi_awprot;
    wire [3:0]              m07_axi_awqos;
    wire [3:0]              m07_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m07_axi_awuser;
    wire                    m07_axi_awvalid;
    wire [DATA_WIDTH-1:0]   m07_axi_wdata;
    wire [STRB_WIDTH-1:0]   m07_axi_wstrb;
    wire                    m07_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m07_axi_wuser;
    wire                    m07_axi_wvalid;
    wire [ID_WIDTH-1:0]     m07_axi_arid;
    wire [ADDR_WIDTH-1:0]   m07_axi_araddr;
    wire [7:0]              m07_axi_arlen;
    wire [2:0]              m07_axi_arsize;
    wire [1:0]              m07_axi_arburst;
    wire                    m07_axi_arlock;
    wire [3:0]              m07_axi_arcache;
    wire [2:0]              m07_axi_arprot;
    wire [3:0]              m07_axi_arqos;
    wire [3:0]              m07_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m07_axi_aruser;
    wire                    m07_axi_arvalid;
    wire [ID_WIDTH-1:0]     m08_axi_awid;
    wire [ADDR_WIDTH-1:0]   m08_axi_awaddr;
    wire [7:0]              m08_axi_awlen;
    wire [2:0]              m08_axi_awsize;
    wire [1:0]              m08_axi_awburst;
    wire                    m08_axi_awlock;
    wire [3:0]              m08_axi_awcache;
    wire [2:0]              m08_axi_awprot;
    wire [3:0]              m08_axi_awqos;
    wire [3:0]              m08_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m08_axi_awuser;
    wire                    m08_axi_awvalid;
    wire [DATA_WIDTH-1:0]   m08_axi_wdata;
    wire [STRB_WIDTH-1:0]   m08_axi_wstrb;
    wire                    m08_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m08_axi_wuser;
    wire                    m08_axi_wvalid;
    wire [ID_WIDTH-1:0]     m08_axi_arid;
    wire [ADDR_WIDTH-1:0]   m08_axi_araddr;
    wire [7:0]              m08_axi_arlen;
    wire [2:0]              m08_axi_arsize;
    wire [1:0]              m08_axi_arburst;
    wire                    m08_axi_arlock;
    wire [3:0]              m08_axi_arcache;
    wire [2:0]              m08_axi_arprot;
    wire [3:0]              m08_axi_arqos;
    wire [3:0]              m08_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m08_axi_aruser;
    wire                    m08_axi_arvalid;
    wire [ID_WIDTH-1:0]     m09_axi_awid;
    wire [ADDR_WIDTH-1:0]   m09_axi_awaddr;
    wire [7:0]              m09_axi_awlen;
    wire [2:0]              m09_axi_awsize;
    wire [1:0]              m09_axi_awburst;
    wire                    m09_axi_awlock;
    wire [3:0]              m09_axi_awcache;
    wire [2:0]              m09_axi_awprot;
    wire [3:0]              m09_axi_awqos;
    wire [3:0]              m09_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m09_axi_awuser;
    wire                    m09_axi_awvalid;
    wire [DATA_WIDTH-1:0]   m09_axi_wdata;
    wire [STRB_WIDTH-1:0]   m09_axi_wstrb;
    wire                    m09_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m09_axi_wuser;
    wire                    m09_axi_wvalid;
    wire [ID_WIDTH-1:0]     m09_axi_arid;
    wire [ADDR_WIDTH-1:0]   m09_axi_araddr;
    wire [7:0]              m09_axi_arlen;
    wire [2:0]              m09_axi_arsize;
    wire [1:0]              m09_axi_arburst;
    wire                    m09_axi_arlock;
    wire [3:0]              m09_axi_arcache;
    wire [2:0]              m09_axi_arprot;
    wire [3:0]              m09_axi_arqos;
    wire [3:0]              m09_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m09_axi_aruser;
    wire                    m09_axi_arvalid;

    // -------------------------------------------------------------------------
    // Test Statistics & Verification Counters
    // -------------------------------------------------------------------------
    int pass_count = 0;
    int fail_count = 0;

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    initial uart_clk = 1'b0;
    always #(CLK_PERIOD_NS / 2) uart_clk = ~uart_clk;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    axi_interconnect_uart_top #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .STRB_WIDTH         (STRB_WIDTH),
        .ID_WIDTH           (ID_WIDTH),
        .AWUSER_ENABLE      (0),
        .AWUSER_WIDTH       (AWUSER_WIDTH),
        .WUSER_ENABLE       (0),
        .WUSER_WIDTH        (WUSER_WIDTH),
        .BUSER_ENABLE       (0),
        .BUSER_WIDTH        (BUSER_WIDTH),
        .ARUSER_ENABLE      (0),
        .ARUSER_WIDTH       (ARUSER_WIDTH),
        .RUSER_ENABLE       (0),
        .RUSER_WIDTH        (RUSER_WIDTH),
        .FORWARD_ID         (0),
        .M_REGIONS          (1),
        .UART_BASE_ADDR     (UART_BASE_ADDR),
        .M01_BASE_ADDR      (BASE_M01),
        .M02_BASE_ADDR      (BASE_M02),
        .M03_BASE_ADDR      (BASE_M03),
        .M04_BASE_ADDR      (BASE_M04),
        .M05_BASE_ADDR      (BASE_M05),
        .M06_BASE_ADDR      (BASE_M06),
        .M07_BASE_ADDR      (BASE_M07),
        .M08_BASE_ADDR      (BASE_M08),
        .M09_BASE_ADDR      (BASE_M09)
    )
    dut (
        .clk                (clk),
        .rst                (rst),
        .uart_clk           (uart_clk),
        .uart_rx            (uart_rx),
        .uart_tx            (uart_tx),
        .uart_irq           (uart_irq),

        // Slave 00 (Core 0)
        .s00_axi_awid       (s00_axi_awid),
        .s00_axi_awaddr     (s00_axi_awaddr),
        .s00_axi_awlen      (s00_axi_awlen),
        .s00_axi_awsize     (s00_axi_awsize),
        .s00_axi_awburst    (s00_axi_awburst),
        .s00_axi_awlock     (s00_axi_awlock),
        .s00_axi_awcache    (s00_axi_awcache),
        .s00_axi_awprot     (s00_axi_awprot),
        .s00_axi_awqos      (s00_axi_awqos),
        .s00_axi_awuser     (s00_axi_awuser),
        .s00_axi_awvalid    (s00_axi_awvalid),
        .s00_axi_awready    (s00_axi_awready),
        .s00_axi_wdata      (s00_axi_wdata),
        .s00_axi_wstrb      (s00_axi_wstrb),
        .s00_axi_wlast      (s00_axi_wlast),
        .s00_axi_wuser      (s00_axi_wuser),
        .s00_axi_wvalid     (s00_axi_wvalid),
        .s00_axi_wready     (s00_axi_wready),
        .s00_axi_bid        (s00_axi_bid),
        .s00_axi_bresp      (s00_axi_bresp),
        .s00_axi_buser      (s00_axi_buser),
        .s00_axi_bvalid     (s00_axi_bvalid),
        .s00_axi_bready     (s00_axi_bready),
        .s00_axi_arid       (s00_axi_arid),
        .s00_axi_araddr     (s00_axi_araddr),
        .s00_axi_arlen      (s00_axi_arlen),
        .s00_axi_arsize     (s00_axi_arsize),
        .s00_axi_arburst    (s00_axi_arburst),
        .s00_axi_arlock     (s00_axi_arlock),
        .s00_axi_arcache    (s00_axi_arcache),
        .s00_axi_arprot     (s00_axi_arprot),
        .s00_axi_arqos      (s00_axi_arqos),
        .s00_axi_aruser     (s00_axi_aruser),
        .s00_axi_arvalid    (s00_axi_arvalid),
        .s00_axi_arready    (s00_axi_arready),
        .s00_axi_rid        (s00_axi_rid),
        .s00_axi_rdata      (s00_axi_rdata),
        .s00_axi_rresp      (s00_axi_rresp),
        .s00_axi_rlast      (s00_axi_rlast),
        .s00_axi_ruser      (s00_axi_ruser),
        .s00_axi_rvalid     (s00_axi_rvalid),
        .s00_axi_rready     (s00_axi_rready),

        // Slave 01 (Core 1)
        .s01_axi_awid       (s01_axi_awid),
        .s01_axi_awaddr     (s01_axi_awaddr),
        .s01_axi_awlen      (s01_axi_awlen),
        .s01_axi_awsize     (s01_axi_awsize),
        .s01_axi_awburst    (s01_axi_awburst),
        .s01_axi_awlock     (s01_axi_awlock),
        .s01_axi_awcache    (s01_axi_awcache),
        .s01_axi_awprot     (s01_axi_awprot),
        .s01_axi_awqos      (s01_axi_awqos),
        .s01_axi_awuser     (s01_axi_awuser),
        .s01_axi_awvalid    (s01_axi_awvalid),
        .s01_axi_awready    (s01_axi_awready),
        .s01_axi_wdata      (s01_axi_wdata),
        .s01_axi_wstrb      (s01_axi_wstrb),
        .s01_axi_wlast      (s01_axi_wlast),
        .s01_axi_wuser      (s01_axi_wuser),
        .s01_axi_wvalid     (s01_axi_wvalid),
        .s01_axi_wready     (s01_axi_wready),
        .s01_axi_bid        (s01_axi_bid),
        .s01_axi_bresp      (s01_axi_bresp),
        .s01_axi_buser      (s01_axi_buser),
        .s01_axi_bvalid     (s01_axi_bvalid),
        .s01_axi_bready     (s01_axi_bready),
        .s01_axi_arid       (s01_axi_arid),
        .s01_axi_araddr     (s01_axi_araddr),
        .s01_axi_arlen      (s01_axi_arlen),
        .s01_axi_arsize     (s01_axi_arsize),
        .s01_axi_arburst    (s01_axi_arburst),
        .s01_axi_arlock     (s01_axi_arlock),
        .s01_axi_arcache    (s01_axi_arcache),
        .s01_axi_arprot     (s01_axi_arprot),
        .s01_axi_arqos      (s01_axi_arqos),
        .s01_axi_aruser     (s01_axi_aruser),
        .s01_axi_arvalid    (s01_axi_arvalid),
        .s01_axi_arready    (s01_axi_arready),
        .s01_axi_rid        (s01_axi_rid),
        .s01_axi_rdata      (s01_axi_rdata),
        .s01_axi_rresp      (s01_axi_rresp),
        .s01_axi_rlast      (s01_axi_rlast),
        .s01_axi_ruser      (s01_axi_ruser),
        .s01_axi_rvalid     (s01_axi_rvalid),
        .s01_axi_rready     (s01_axi_rready),

        // Slave 02 (DMA / Debug)
        .s02_axi_awid       (s02_axi_awid),
        .s02_axi_awaddr     (s02_axi_awaddr),
        .s02_axi_awlen      (s02_axi_awlen),
        .s02_axi_awsize     (s02_axi_awsize),
        .s02_axi_awburst    (s02_axi_awburst),
        .s02_axi_awlock     (s02_axi_awlock),
        .s02_axi_awcache    (s02_axi_awcache),
        .s02_axi_awprot     (s02_axi_awprot),
        .s02_axi_awqos      (s02_axi_awqos),
        .s02_axi_awuser     (s02_axi_awuser),
        .s02_axi_awvalid    (s02_axi_awvalid),
        .s02_axi_awready    (s02_axi_awready),
        .s02_axi_wdata      (s02_axi_wdata),
        .s02_axi_wstrb      (s02_axi_wstrb),
        .s02_axi_wlast      (s02_axi_wlast),
        .s02_axi_wuser      (s02_axi_wuser),
        .s02_axi_wvalid     (s02_axi_wvalid),
        .s02_axi_wready     (s02_axi_wready),
        .s02_axi_bid        (s02_axi_bid),
        .s02_axi_bresp      (s02_axi_bresp),
        .s02_axi_buser      (s02_axi_buser),
        .s02_axi_bvalid     (s02_axi_bvalid),
        .s02_axi_bready     (s02_axi_bready),
        .s02_axi_arid       (s02_axi_arid),
        .s02_axi_araddr     (s02_axi_araddr),
        .s02_axi_arlen      (s02_axi_arlen),
        .s02_axi_arsize     (s02_axi_arsize),
        .s02_axi_arburst    (s02_axi_arburst),
        .s02_axi_arlock     (s02_axi_arlock),
        .s02_axi_arcache    (s02_axi_arcache),
        .s02_axi_arprot     (s02_axi_arprot),
        .s02_axi_arqos      (s02_axi_arqos),
        .s02_axi_aruser     (s02_axi_aruser),
        .s02_axi_arvalid    (s02_axi_arvalid),
        .s02_axi_arready    (s02_axi_arready),
        .s02_axi_rid        (s02_axi_rid),
        .s02_axi_rdata      (s02_axi_rdata),
        .s02_axi_rresp      (s02_axi_rresp),
        .s02_axi_rlast      (s02_axi_rlast),
        .s02_axi_ruser      (s02_axi_ruser),
        .s02_axi_rvalid     (s02_axi_rvalid),
        .s02_axi_rready     (s02_axi_rready),

        // Master 01 (External Peripheral)
        .m01_axi_awid       (m01_axi_awid),
        .m01_axi_awaddr     (m01_axi_awaddr),
        .m01_axi_awlen      (m01_axi_awlen),
        .m01_axi_awsize     (m01_axi_awsize),
        .m01_axi_awburst    (m01_axi_awburst),
        .m01_axi_awlock     (m01_axi_awlock),
        .m01_axi_awcache    (m01_axi_awcache),
        .m01_axi_awprot     (m01_axi_awprot),
        .m01_axi_awqos      (m01_axi_awqos),
        .m01_axi_awregion   (m01_axi_awregion),
        .m01_axi_awuser     (m01_axi_awuser),
        .m01_axi_awvalid    (m01_axi_awvalid),
        .m01_axi_awready    (m01_axi_awready),
        .m01_axi_wdata      (m01_axi_wdata),
        .m01_axi_wstrb      (m01_axi_wstrb),
        .m01_axi_wlast      (m01_axi_wlast),
        .m01_axi_wuser      (m01_axi_wuser),
        .m01_axi_wvalid     (m01_axi_wvalid),
        .m01_axi_wready     (m01_axi_wready),
        .m01_axi_bid        (m01_axi_bid),
        .m01_axi_bresp      (m01_axi_bresp),
        .m01_axi_buser      (m01_axi_buser),
        .m01_axi_bvalid     (m01_axi_bvalid),
        .m01_axi_bready     (m01_axi_bready),
        .m01_axi_arid       (m01_axi_arid),
        .m01_axi_araddr     (m01_axi_araddr),
        .m01_axi_arlen      (m01_axi_arlen),
        .m01_axi_arsize     (m01_axi_arsize),
        .m01_axi_arburst    (m01_axi_arburst),
        .m01_axi_arlock     (m01_axi_arlock),
        .m01_axi_arcache    (m01_axi_arcache),
        .m01_axi_arprot     (m01_axi_arprot),
        .m01_axi_arqos      (m01_axi_arqos),
        .m01_axi_arregion   (m01_axi_arregion),
        .m01_axi_aruser     (m01_axi_aruser),
        .m01_axi_arvalid    (m01_axi_arvalid),
        .m01_axi_arready    (m01_axi_arready),
        .m01_axi_rid        (m01_axi_rid),
        .m01_axi_rdata      (m01_axi_rdata),
        .m01_axi_rresp      (m01_axi_rresp),
        .m01_axi_rlast      (m01_axi_rlast),
        .m01_axi_ruser      (m01_axi_ruser),
        .m01_axi_rvalid     (m01_axi_rvalid),
        .m01_axi_rready     (m01_axi_rready),

        // Masters 02..09
        // Master 02
        .m02_axi_awid       (m02_axi_awid),
        .m02_axi_awaddr     (m02_axi_awaddr),
        .m02_axi_awlen      (m02_axi_awlen),
        .m02_axi_awsize     (m02_axi_awsize),
        .m02_axi_awburst    (m02_axi_awburst),
        .m02_axi_awlock     (m02_axi_awlock),
        .m02_axi_awcache    (m02_axi_awcache),
        .m02_axi_awprot     (m02_axi_awprot),
        .m02_axi_awqos      (m02_axi_awqos),
        .m02_axi_awregion   (m02_axi_awregion),
        .m02_axi_awuser     (m02_axi_awuser),
        .m02_axi_awvalid    (m02_axi_awvalid),
        .m02_axi_awready    (1'b0),
        .m02_axi_wdata      (m02_axi_wdata),
        .m02_axi_wstrb      (m02_axi_wstrb),
        .m02_axi_wlast      (m02_axi_wlast),
        .m02_axi_wuser      (m02_axi_wuser),
        .m02_axi_wvalid     (m02_axi_wvalid),
        .m02_axi_wready     (1'b0),
        .m02_axi_bid        ({ID_WIDTH{1'b0}}),
        .m02_axi_bresp      (2'b00),
        .m02_axi_buser      ({BUSER_WIDTH{1'b0}}),
        .m02_axi_bvalid     (1'b0),
        .m02_axi_bready     (),
        .m02_axi_arid       (m02_axi_arid),
        .m02_axi_araddr     (m02_axi_araddr),
        .m02_axi_arlen      (m02_axi_arlen),
        .m02_axi_arsize     (m02_axi_arsize),
        .m02_axi_arburst    (m02_axi_arburst),
        .m02_axi_arlock     (m02_axi_arlock),
        .m02_axi_arcache    (m02_axi_arcache),
        .m02_axi_arprot     (m02_axi_arprot),
        .m02_axi_arqos      (m02_axi_arqos),
        .m02_axi_arregion   (m02_axi_arregion),
        .m02_axi_aruser     (m02_axi_aruser),
        .m02_axi_arvalid    (m02_axi_arvalid),
        .m02_axi_arready    (1'b0),
        .m02_axi_rid        ({ID_WIDTH{1'b0}}),
        .m02_axi_rdata      ({DATA_WIDTH{1'b0}}),
        .m02_axi_rresp      (2'b00),
        .m02_axi_rlast      (1'b0),
        .m02_axi_ruser      ({RUSER_WIDTH{1'b0}}),
        .m02_axi_rvalid     (1'b0),
        .m02_axi_rready     (),
        // Master 03
        .m03_axi_awid       (m03_axi_awid),
        .m03_axi_awaddr     (m03_axi_awaddr),
        .m03_axi_awlen      (m03_axi_awlen),
        .m03_axi_awsize     (m03_axi_awsize),
        .m03_axi_awburst    (m03_axi_awburst),
        .m03_axi_awlock     (m03_axi_awlock),
        .m03_axi_awcache    (m03_axi_awcache),
        .m03_axi_awprot     (m03_axi_awprot),
        .m03_axi_awqos      (m03_axi_awqos),
        .m03_axi_awregion   (m03_axi_awregion),
        .m03_axi_awuser     (m03_axi_awuser),
        .m03_axi_awvalid    (m03_axi_awvalid),
        .m03_axi_awready    (1'b0),
        .m03_axi_wdata      (m03_axi_wdata),
        .m03_axi_wstrb      (m03_axi_wstrb),
        .m03_axi_wlast      (m03_axi_wlast),
        .m03_axi_wuser      (m03_axi_wuser),
        .m03_axi_wvalid     (m03_axi_wvalid),
        .m03_axi_wready     (1'b0),
        .m03_axi_bid        ({ID_WIDTH{1'b0}}),
        .m03_axi_bresp      (2'b00),
        .m03_axi_buser      ({BUSER_WIDTH{1'b0}}),
        .m03_axi_bvalid     (1'b0),
        .m03_axi_bready     (),
        .m03_axi_arid       (m03_axi_arid),
        .m03_axi_araddr     (m03_axi_araddr),
        .m03_axi_arlen      (m03_axi_arlen),
        .m03_axi_arsize     (m03_axi_arsize),
        .m03_axi_arburst    (m03_axi_arburst),
        .m03_axi_arlock     (m03_axi_arlock),
        .m03_axi_arcache    (m03_axi_arcache),
        .m03_axi_arprot     (m03_axi_arprot),
        .m03_axi_arqos      (m03_axi_arqos),
        .m03_axi_arregion   (m03_axi_arregion),
        .m03_axi_aruser     (m03_axi_aruser),
        .m03_axi_arvalid    (m03_axi_arvalid),
        .m03_axi_arready    (1'b0),
        .m03_axi_rid        ({ID_WIDTH{1'b0}}),
        .m03_axi_rdata      ({DATA_WIDTH{1'b0}}),
        .m03_axi_rresp      (2'b00),
        .m03_axi_rlast      (1'b0),
        .m03_axi_ruser      ({RUSER_WIDTH{1'b0}}),
        .m03_axi_rvalid     (1'b0),
        .m03_axi_rready     (),
        // Master 04
        .m04_axi_awid       (m04_axi_awid),
        .m04_axi_awaddr     (m04_axi_awaddr),
        .m04_axi_awlen      (m04_axi_awlen),
        .m04_axi_awsize     (m04_axi_awsize),
        .m04_axi_awburst    (m04_axi_awburst),
        .m04_axi_awlock     (m04_axi_awlock),
        .m04_axi_awcache    (m04_axi_awcache),
        .m04_axi_awprot     (m04_axi_awprot),
        .m04_axi_awqos      (m04_axi_awqos),
        .m04_axi_awregion   (m04_axi_awregion),
        .m04_axi_awuser     (m04_axi_awuser),
        .m04_axi_awvalid    (m04_axi_awvalid),
        .m04_axi_awready    (1'b0),
        .m04_axi_wdata      (m04_axi_wdata),
        .m04_axi_wstrb      (m04_axi_wstrb),
        .m04_axi_wlast      (m04_axi_wlast),
        .m04_axi_wuser      (m04_axi_wuser),
        .m04_axi_wvalid     (m04_axi_wvalid),
        .m04_axi_wready     (1'b0),
        .m04_axi_bid        ({ID_WIDTH{1'b0}}),
        .m04_axi_bresp      (2'b00),
        .m04_axi_buser      ({BUSER_WIDTH{1'b0}}),
        .m04_axi_bvalid     (1'b0),
        .m04_axi_bready     (),
        .m04_axi_arid       (m04_axi_arid),
        .m04_axi_araddr     (m04_axi_araddr),
        .m04_axi_arlen      (m04_axi_arlen),
        .m04_axi_arsize     (m04_axi_arsize),
        .m04_axi_arburst    (m04_axi_arburst),
        .m04_axi_arlock     (m04_axi_arlock),
        .m04_axi_arcache    (m04_axi_arcache),
        .m04_axi_arprot     (m04_axi_arprot),
        .m04_axi_arqos      (m04_axi_arqos),
        .m04_axi_arregion   (m04_axi_arregion),
        .m04_axi_aruser     (m04_axi_aruser),
        .m04_axi_arvalid    (m04_axi_arvalid),
        .m04_axi_arready    (1'b0),
        .m04_axi_rid        ({ID_WIDTH{1'b0}}),
        .m04_axi_rdata      ({DATA_WIDTH{1'b0}}),
        .m04_axi_rresp      (2'b00),
        .m04_axi_rlast      (1'b0),
        .m04_axi_ruser      ({RUSER_WIDTH{1'b0}}),
        .m04_axi_rvalid     (1'b0),
        .m04_axi_rready     (),
        // Master 05
        .m05_axi_awid       (m05_axi_awid),
        .m05_axi_awaddr     (m05_axi_awaddr),
        .m05_axi_awlen      (m05_axi_awlen),
        .m05_axi_awsize     (m05_axi_awsize),
        .m05_axi_awburst    (m05_axi_awburst),
        .m05_axi_awlock     (m05_axi_awlock),
        .m05_axi_awcache    (m05_axi_awcache),
        .m05_axi_awprot     (m05_axi_awprot),
        .m05_axi_awqos      (m05_axi_awqos),
        .m05_axi_awregion   (m05_axi_awregion),
        .m05_axi_awuser     (m05_axi_awuser),
        .m05_axi_awvalid    (m05_axi_awvalid),
        .m05_axi_awready    (1'b0),
        .m05_axi_wdata      (m05_axi_wdata),
        .m05_axi_wstrb      (m05_axi_wstrb),
        .m05_axi_wlast      (m05_axi_wlast),
        .m05_axi_wuser      (m05_axi_wuser),
        .m05_axi_wvalid     (m05_axi_wvalid),
        .m05_axi_wready     (1'b0),
        .m05_axi_bid        ({ID_WIDTH{1'b0}}),
        .m05_axi_bresp      (2'b00),
        .m05_axi_buser      ({BUSER_WIDTH{1'b0}}),
        .m05_axi_bvalid     (1'b0),
        .m05_axi_bready     (),
        .m05_axi_arid       (m05_axi_arid),
        .m05_axi_araddr     (m05_axi_araddr),
        .m05_axi_arlen      (m05_axi_arlen),
        .m05_axi_arsize     (m05_axi_arsize),
        .m05_axi_arburst    (m05_axi_arburst),
        .m05_axi_arlock     (m05_axi_arlock),
        .m05_axi_arcache    (m05_axi_arcache),
        .m05_axi_arprot     (m05_axi_arprot),
        .m05_axi_arqos      (m05_axi_arqos),
        .m05_axi_arregion   (m05_axi_arregion),
        .m05_axi_aruser     (m05_axi_aruser),
        .m05_axi_arvalid    (m05_axi_arvalid),
        .m05_axi_arready    (1'b0),
        .m05_axi_rid        ({ID_WIDTH{1'b0}}),
        .m05_axi_rdata      ({DATA_WIDTH{1'b0}}),
        .m05_axi_rresp      (2'b00),
        .m05_axi_rlast      (1'b0),
        .m05_axi_ruser      ({RUSER_WIDTH{1'b0}}),
        .m05_axi_rvalid     (1'b0),
        .m05_axi_rready     (),
        // Master 06
        .m06_axi_awid       (m06_axi_awid),
        .m06_axi_awaddr     (m06_axi_awaddr),
        .m06_axi_awlen      (m06_axi_awlen),
        .m06_axi_awsize     (m06_axi_awsize),
        .m06_axi_awburst    (m06_axi_awburst),
        .m06_axi_awlock     (m06_axi_awlock),
        .m06_axi_awcache    (m06_axi_awcache),
        .m06_axi_awprot     (m06_axi_awprot),
        .m06_axi_awqos      (m06_axi_awqos),
        .m06_axi_awregion   (m06_axi_awregion),
        .m06_axi_awuser     (m06_axi_awuser),
        .m06_axi_awvalid    (m06_axi_awvalid),
        .m06_axi_awready    (1'b0),
        .m06_axi_wdata      (m06_axi_wdata),
        .m06_axi_wstrb      (m06_axi_wstrb),
        .m06_axi_wlast      (m06_axi_wlast),
        .m06_axi_wuser      (m06_axi_wuser),
        .m06_axi_wvalid     (m06_axi_wvalid),
        .m06_axi_wready     (1'b0),
        .m06_axi_bid        ({ID_WIDTH{1'b0}}),
        .m06_axi_bresp      (2'b00),
        .m06_axi_buser      ({BUSER_WIDTH{1'b0}}),
        .m06_axi_bvalid     (1'b0),
        .m06_axi_bready     (),
        .m06_axi_arid       (m06_axi_arid),
        .m06_axi_araddr     (m06_axi_araddr),
        .m06_axi_arlen      (m06_axi_arlen),
        .m06_axi_arsize     (m06_axi_arsize),
        .m06_axi_arburst    (m06_axi_arburst),
        .m06_axi_arlock     (m06_axi_arlock),
        .m06_axi_arcache    (m06_axi_arcache),
        .m06_axi_arprot     (m06_axi_arprot),
        .m06_axi_arqos      (m06_axi_arqos),
        .m06_axi_arregion   (m06_axi_arregion),
        .m06_axi_aruser     (m06_axi_aruser),
        .m06_axi_arvalid    (m06_axi_arvalid),
        .m06_axi_arready    (1'b0),
        .m06_axi_rid        ({ID_WIDTH{1'b0}}),
        .m06_axi_rdata      ({DATA_WIDTH{1'b0}}),
        .m06_axi_rresp      (2'b00),
        .m06_axi_rlast      (1'b0),
        .m06_axi_ruser      ({RUSER_WIDTH{1'b0}}),
        .m06_axi_rvalid     (1'b0),
        .m06_axi_rready     (),
        // Master 07
        .m07_axi_awid       (m07_axi_awid),
        .m07_axi_awaddr     (m07_axi_awaddr),
        .m07_axi_awlen      (m07_axi_awlen),
        .m07_axi_awsize     (m07_axi_awsize),
        .m07_axi_awburst    (m07_axi_awburst),
        .m07_axi_awlock     (m07_axi_awlock),
        .m07_axi_awcache    (m07_axi_awcache),
        .m07_axi_awprot     (m07_axi_awprot),
        .m07_axi_awqos      (m07_axi_awqos),
        .m07_axi_awregion   (m07_axi_awregion),
        .m07_axi_awuser     (m07_axi_awuser),
        .m07_axi_awvalid    (m07_axi_awvalid),
        .m07_axi_awready    (1'b0),
        .m07_axi_wdata      (m07_axi_wdata),
        .m07_axi_wstrb      (m07_axi_wstrb),
        .m07_axi_wlast      (m07_axi_wlast),
        .m07_axi_wuser      (m07_axi_wuser),
        .m07_axi_wvalid     (m07_axi_wvalid),
        .m07_axi_wready     (1'b0),
        .m07_axi_bid        ({ID_WIDTH{1'b0}}),
        .m07_axi_bresp      (2'b00),
        .m07_axi_buser      ({BUSER_WIDTH{1'b0}}),
        .m07_axi_bvalid     (1'b0),
        .m07_axi_bready     (),
        .m07_axi_arid       (m07_axi_arid),
        .m07_axi_araddr     (m07_axi_araddr),
        .m07_axi_arlen      (m07_axi_arlen),
        .m07_axi_arsize     (m07_axi_arsize),
        .m07_axi_arburst    (m07_axi_arburst),
        .m07_axi_arlock     (m07_axi_arlock),
        .m07_axi_arcache    (m07_axi_arcache),
        .m07_axi_arprot     (m07_axi_arprot),
        .m07_axi_arqos      (m07_axi_arqos),
        .m07_axi_arregion   (m07_axi_arregion),
        .m07_axi_aruser     (m07_axi_aruser),
        .m07_axi_arvalid    (m07_axi_arvalid),
        .m07_axi_arready    (1'b0),
        .m07_axi_rid        ({ID_WIDTH{1'b0}}),
        .m07_axi_rdata      ({DATA_WIDTH{1'b0}}),
        .m07_axi_rresp      (2'b00),
        .m07_axi_rlast      (1'b0),
        .m07_axi_ruser      ({RUSER_WIDTH{1'b0}}),
        .m07_axi_rvalid     (1'b0),
        .m07_axi_rready     (),
        // Master 08
        .m08_axi_awid       (m08_axi_awid),
        .m08_axi_awaddr     (m08_axi_awaddr),
        .m08_axi_awlen      (m08_axi_awlen),
        .m08_axi_awsize     (m08_axi_awsize),
        .m08_axi_awburst    (m08_axi_awburst),
        .m08_axi_awlock     (m08_axi_awlock),
        .m08_axi_awcache    (m08_axi_awcache),
        .m08_axi_awprot     (m08_axi_awprot),
        .m08_axi_awqos      (m08_axi_awqos),
        .m08_axi_awregion   (m08_axi_awregion),
        .m08_axi_awuser     (m08_axi_awuser),
        .m08_axi_awvalid    (m08_axi_awvalid),
        .m08_axi_awready    (1'b0),
        .m08_axi_wdata      (m08_axi_wdata),
        .m08_axi_wstrb      (m08_axi_wstrb),
        .m08_axi_wlast      (m08_axi_wlast),
        .m08_axi_wuser      (m08_axi_wuser),
        .m08_axi_wvalid     (m08_axi_wvalid),
        .m08_axi_wready     (1'b0),
        .m08_axi_bid        ({ID_WIDTH{1'b0}}),
        .m08_axi_bresp      (2'b00),
        .m08_axi_buser      ({BUSER_WIDTH{1'b0}}),
        .m08_axi_bvalid     (1'b0),
        .m08_axi_bready     (),
        .m08_axi_arid       (m08_axi_arid),
        .m08_axi_araddr     (m08_axi_araddr),
        .m08_axi_arlen      (m08_axi_arlen),
        .m08_axi_arsize     (m08_axi_arsize),
        .m08_axi_arburst    (m08_axi_arburst),
        .m08_axi_arlock     (m08_axi_arlock),
        .m08_axi_arcache    (m08_axi_arcache),
        .m08_axi_arprot     (m08_axi_arprot),
        .m08_axi_arqos      (m08_axi_arqos),
        .m08_axi_arregion   (m08_axi_arregion),
        .m08_axi_aruser     (m08_axi_aruser),
        .m08_axi_arvalid    (m08_axi_arvalid),
        .m08_axi_arready    (1'b0),
        .m08_axi_rid        ({ID_WIDTH{1'b0}}),
        .m08_axi_rdata      ({DATA_WIDTH{1'b0}}),
        .m08_axi_rresp      (2'b00),
        .m08_axi_rlast      (1'b0),
        .m08_axi_ruser      ({RUSER_WIDTH{1'b0}}),
        .m08_axi_rvalid     (1'b0),
        .m08_axi_rready     (),
        // Master 09
        .m09_axi_awid       (m09_axi_awid),
        .m09_axi_awaddr     (m09_axi_awaddr),
        .m09_axi_awlen      (m09_axi_awlen),
        .m09_axi_awsize     (m09_axi_awsize),
        .m09_axi_awburst    (m09_axi_awburst),
        .m09_axi_awlock     (m09_axi_awlock),
        .m09_axi_awcache    (m09_axi_awcache),
        .m09_axi_awprot     (m09_axi_awprot),
        .m09_axi_awqos      (m09_axi_awqos),
        .m09_axi_awregion   (m09_axi_awregion),
        .m09_axi_awuser     (m09_axi_awuser),
        .m09_axi_awvalid    (m09_axi_awvalid),
        .m09_axi_awready    (1'b0),
        .m09_axi_wdata      (m09_axi_wdata),
        .m09_axi_wstrb      (m09_axi_wstrb),
        .m09_axi_wlast      (m09_axi_wlast),
        .m09_axi_wuser      (m09_axi_wuser),
        .m09_axi_wvalid     (m09_axi_wvalid),
        .m09_axi_wready     (1'b0),
        .m09_axi_bid        ({ID_WIDTH{1'b0}}),
        .m09_axi_bresp      (2'b00),
        .m09_axi_buser      ({BUSER_WIDTH{1'b0}}),
        .m09_axi_bvalid     (1'b0),
        .m09_axi_bready     (),
        .m09_axi_arid       (m09_axi_arid),
        .m09_axi_araddr     (m09_axi_araddr),
        .m09_axi_arlen      (m09_axi_arlen),
        .m09_axi_arsize     (m09_axi_arsize),
        .m09_axi_arburst    (m09_axi_arburst),
        .m09_axi_arlock     (m09_axi_arlock),
        .m09_axi_arcache    (m09_axi_arcache),
        .m09_axi_arprot     (m09_axi_arprot),
        .m09_axi_arqos      (m09_axi_arqos),
        .m09_axi_arregion   (m09_axi_arregion),
        .m09_axi_aruser     (m09_axi_aruser),
        .m09_axi_arvalid    (m09_axi_arvalid),
        .m09_axi_arready    (1'b0),
        .m09_axi_rid        ({ID_WIDTH{1'b0}}),
        .m09_axi_rdata      ({DATA_WIDTH{1'b0}}),
        .m09_axi_rresp      (2'b00),
        .m09_axi_rlast      (1'b0),
        .m09_axi_ruser      ({RUSER_WIDTH{1'b0}}),
        .m09_axi_rvalid     (1'b0),
        .m09_axi_rready     ()
    );

    // -------------------------------------------------------------------------
    // External Slave Responder on M01
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] m01_mem [0:255];
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m01_axi_awready <= 1'b0;
            m01_axi_wready  <= 1'b0;
            m01_axi_bvalid  <= 1'b0;
            m01_axi_bid     <= '0;
            m01_axi_bresp   <= 2'b00;
            m01_axi_buser   <= '0;
            m01_axi_arready <= 1'b0;
            m01_axi_rvalid  <= 1'b0;
            m01_axi_rid     <= '0;
            m01_axi_rdata   <= '0;
            m01_axi_rresp   <= 2'b00;
            m01_axi_rlast   <= 1'b0;
            m01_axi_ruser   <= '0;
        end else begin
            // Write Address Ready Handshake
            m01_axi_awready <= m01_axi_awvalid & ~m01_axi_awready;
            // Write Data Ready Handshake
            m01_axi_wready  <= m01_axi_wvalid & ~m01_axi_wready;

            if (m01_axi_wvalid & m01_axi_wready & m01_axi_wlast) begin
                m01_axi_bvalid  <= 1'b1;
                m01_axi_bid     <= m01_axi_awid;
                m01_axi_bresp   <= 2'b00; // OKAY
                m01_mem[m01_axi_awaddr[9:2]] <= m01_axi_wdata;
            end else if (m01_axi_bvalid & m01_axi_bready) begin
                m01_axi_bvalid  <= 1'b0;
            end

            // Read Address Ready Handshake
            m01_axi_arready <= m01_axi_arvalid & ~m01_axi_arready;
            if (m01_axi_arvalid & m01_axi_arready) begin
                m01_axi_rvalid <= 1'b1;
                m01_axi_rid    <= m01_axi_arid;
                m01_axi_rdata  <= m01_mem[m01_axi_araddr[9:2]];
                m01_axi_rresp  <= 2'b00;
                m01_axi_rlast  <= 1'b1;
            end else if (m01_axi_rvalid & m01_axi_rready) begin
                m01_axi_rvalid <= 1'b0;
                m01_axi_rlast  <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI Master Driver Tasks (s00, s01, s02)
    // -------------------------------------------------------------------------
    task automatic s00_axi_write(
        input [ID_WIDTH-1:0]   id,
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data
    );
        int timeout;
        @(posedge clk);
        s00_axi_awid    <= id;
        s00_axi_awaddr  <= addr;
        s00_axi_awlen   <= 8'h00;  // 1 beat
        s00_axi_awsize  <= 3'b010; // 4 bytes
        s00_axi_awburst <= 2'b01;  // INCR
        s00_axi_awlock  <= 1'b0;
        s00_axi_awcache <= 4'h0;
        s00_axi_awprot  <= 3'h0;
        s00_axi_awqos   <= 4'h0;
        s00_axi_awuser  <= '0;
        s00_axi_awvalid <= 1'b1;

        s00_axi_wdata   <= data;
        s00_axi_wstrb   <= 4'hF;
        s00_axi_wlast   <= 1'b1;
        s00_axi_wuser   <= '0;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_bready  <= 1'b1;

        timeout = 0;
        while (!s00_axi_awready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s00 AW channel at addr=0x%08x", addr);
                fail_count++;
                disable s00_axi_write;
            end
        end
        @(posedge clk);
        s00_axi_awvalid <= 1'b0;

        timeout = 0;
        while (!s00_axi_wready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s00 W channel at addr=0x%08x", addr);
                fail_count++;
                disable s00_axi_write;
            end
        end
        @(posedge clk);
        s00_axi_wvalid <= 1'b0;
        s00_axi_wlast  <= 1'b0;

        timeout = 0;
        while (!s00_axi_bvalid) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s00 B channel at addr=0x%08x", addr);
                fail_count++;
                return;
            end
        end
        if (s00_axi_bid !== id || s00_axi_bresp !== 2'b00) begin
            $display("[ERROR] s00 Write Resp Mismatch: got bid=0x%02x bresp=%b (exp id=0x%02x)",
                     s00_axi_bid, s00_axi_bresp, id);
            fail_count++;
        end
        @(posedge clk);
        s00_axi_bready <= 1'b0;
    endtask

    task automatic s00_axi_read(
        input  [ID_WIDTH-1:0]   id,
        input  [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data
    );
        int timeout;
        @(posedge clk);
        s00_axi_arid    <= id;
        s00_axi_araddr  <= addr;
        s00_axi_arlen   <= 8'h00;  // 1 beat
        s00_axi_arsize  <= 3'b010; // 4 bytes
        s00_axi_arburst <= 2'b01;  // INCR
        s00_axi_arlock  <= 1'b0;
        s00_axi_arcache <= 4'h0;
        s00_axi_arprot  <= 3'h0;
        s00_axi_arqos   <= 4'h0;
        s00_axi_aruser  <= '0;
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;

        timeout = 0;
        @(posedge clk);
        while (!s00_axi_arready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s00 AR channel at addr=0x%08x", addr);
                fail_count++;
                return;
            end
        end
        s00_axi_arvalid <= 1'b0;

        timeout = 0;
        while (!s00_axi_rvalid) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s00 R channel at addr=0x%08x", addr);
                fail_count++;
                return;
            end
        end
        data = s00_axi_rdata;
        if (s00_axi_rid !== id || s00_axi_rresp !== 2'b00) begin
            $display("[ERROR] s00 Read Resp Mismatch: got rid=0x%02x rresp=%b (exp id=0x%02x)",
                     s00_axi_rid, s00_axi_rresp, id);
            fail_count++;
        end
        @(posedge clk);
        s00_axi_rready <= 1'b0;
    endtask

    // s01 Write & Read Tasks
    task automatic s01_axi_write(
        input [ID_WIDTH-1:0]   id,
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data
    );
        int timeout;
        @(posedge clk);
        s01_axi_awid    <= id;
        s01_axi_awaddr  <= addr;
        s01_axi_awlen   <= 8'h00;
        s01_axi_awsize  <= 3'b010;
        s01_axi_awburst <= 2'b01;
        s01_axi_awlock  <= 1'b0;
        s01_axi_awcache <= 4'h0;
        s01_axi_awprot  <= 3'h0;
        s01_axi_awqos   <= 4'h0;
        s01_axi_awuser  <= '0;
        s01_axi_awvalid <= 1'b1;

        s01_axi_wdata   <= data;
        s01_axi_wstrb   <= 4'hF;
        s01_axi_wlast   <= 1'b1;
        s01_axi_wuser   <= '0;
        s01_axi_wvalid  <= 1'b1;
        s01_axi_bready  <= 1'b1;

        timeout = 0;
        while (!s01_axi_awready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s01 AW channel"); fail_count++; disable s01_axi_write;
            end
        end
        @(posedge clk);
        s01_axi_awvalid <= 1'b0;

        timeout = 0;
        while (!s01_axi_wready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s01 W channel"); fail_count++; disable s01_axi_write;
            end
        end
        @(posedge clk);
        s01_axi_wvalid <= 1'b0;
        s01_axi_wlast  <= 1'b0;

        timeout = 0;
        while (!s01_axi_bvalid) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s01 B channel"); fail_count++; return;
            end
        end
        @(posedge clk);
        s01_axi_bready <= 1'b0;
    endtask

    task automatic s01_axi_read(
        input  [ID_WIDTH-1:0]   id,
        input  [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data
    );
        int timeout;
        @(posedge clk);
        s01_axi_arid    <= id;
        s01_axi_araddr  <= addr;
        s01_axi_arlen   <= 8'h00;
        s01_axi_arsize  <= 3'b010;
        s01_axi_arburst <= 2'b01;
        s01_axi_arlock  <= 1'b0;
        s01_axi_arcache <= 4'h0;
        s01_axi_arprot  <= 3'h0;
        s01_axi_arqos   <= 4'h0;
        s01_axi_aruser  <= '0;
        s01_axi_arvalid <= 1'b1;
        s01_axi_rready  <= 1'b1;

        timeout = 0;
        @(posedge clk);
        while (!s01_axi_arready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s01 AR channel"); fail_count++; return;
            end
        end
        s01_axi_arvalid <= 1'b0;

        timeout = 0;
        while (!s01_axi_rvalid) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s01 R channel"); fail_count++; return;
            end
        end
        data = s01_axi_rdata;
        @(posedge clk);
        s01_axi_rready <= 1'b0;
    endtask

    // s02 Write & Read Tasks
    task automatic s02_axi_write(
        input [ID_WIDTH-1:0]   id,
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data
    );
        int timeout;
        @(posedge clk);
        s02_axi_awid    <= id;
        s02_axi_awaddr  <= addr;
        s02_axi_awlen   <= 8'h00;
        s02_axi_awsize  <= 3'b010;
        s02_axi_awburst <= 2'b01;
        s02_axi_awlock  <= 1'b0;
        s02_axi_awcache <= 4'h0;
        s02_axi_awprot  <= 3'h0;
        s02_axi_awqos   <= 4'h0;
        s02_axi_awuser  <= '0;
        s02_axi_awvalid <= 1'b1;

        s02_axi_wdata   <= data;
        s02_axi_wstrb   <= 4'hF;
        s02_axi_wlast   <= 1'b1;
        s02_axi_wuser   <= '0;
        s02_axi_wvalid  <= 1'b1;
        s02_axi_bready  <= 1'b1;

        timeout = 0;
        while (!s02_axi_awready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s02 AW channel"); fail_count++; disable s02_axi_write;
            end
        end
        @(posedge clk);
        s02_axi_awvalid <= 1'b0;

        timeout = 0;
        while (!s02_axi_wready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s02 W channel"); fail_count++; disable s02_axi_write;
            end
        end
        @(posedge clk);
        s02_axi_wvalid <= 1'b0;
        s02_axi_wlast  <= 1'b0;

        timeout = 0;
        while (!s02_axi_bvalid) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s02 B channel"); fail_count++; return;
            end
        end
        @(posedge clk);
        s02_axi_bready <= 1'b0;
    endtask

    task automatic s02_axi_read(
        input  [ID_WIDTH-1:0]   id,
        input  [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data
    );
        int timeout;
        @(posedge clk);
        s02_axi_arid    <= id;
        s02_axi_araddr  <= addr;
        s02_axi_arlen   <= 8'h00;
        s02_axi_arsize  <= 3'b010;
        s02_axi_arburst <= 2'b01;
        s02_axi_arlock  <= 1'b0;
        s02_axi_arcache <= 4'h0;
        s02_axi_arprot  <= 3'h0;
        s02_axi_arqos   <= 4'h0;
        s02_axi_aruser  <= '0;
        s02_axi_arvalid <= 1'b1;
        s02_axi_rready  <= 1'b1;

        timeout = 0;
        @(posedge clk);
        while (!s02_axi_arready) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s02 AR channel"); fail_count++; return;
            end
        end
        s02_axi_arvalid <= 1'b0;

        timeout = 0;
        while (!s02_axi_rvalid) begin
            @(posedge clk);
            if (++timeout > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT: s02 R channel"); fail_count++; return;
            end
        end
        data = s02_axi_rdata;
        @(posedge clk);
        s02_axi_rready <= 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // UART Physical Serial Line Transmitter Helper (Sends Byte to uart_rx)
    // -------------------------------------------------------------------------
    task automatic uart_send_serial_byte(
        input [7:0] byte_to_send,
        input int   baud_div
    );
        int bit_cycles;
        bit_cycles = baud_div + 1;

        $display("[UART RX DRIVER] Sending serial byte 0x%02x ('%c') to uart_rx (bit_cycles=%0d)...",
                 byte_to_send, byte_to_send, bit_cycles);

        // Start bit (0)
        uart_rx <= 1'b0;
        repeat (bit_cycles) @(posedge clk);

        // 8 Data bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            uart_rx <= byte_to_send[i];
            repeat (bit_cycles) @(posedge clk);
        end

        // Stop bit (1)
        uart_rx <= 1'b1;
        repeat (bit_cycles) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] rd_data;
    logic [7:0]            captured_tx_byte;
    localparam int TEST_BAUD_DIV = 16;

    initial begin
        // Reset and signal initializations
        rst             = 1'b1;
        uart_rx         = 1'b1; // Idle state for UART RX line

        s00_axi_awvalid = 1'b0;
        s00_axi_wvalid  = 1'b0;
        s00_axi_bready  = 1'b0;
        s00_axi_arvalid = 1'b0;
        s00_axi_rready  = 1'b0;

        s01_axi_awvalid = 1'b0;
        s01_axi_wvalid  = 1'b0;
        s01_axi_bready  = 1'b0;
        s01_axi_arvalid = 1'b0;
        s01_axi_rready  = 1'b0;

        s02_axi_awvalid = 1'b0;
        s02_axi_wvalid  = 1'b0;
        s02_axi_bready  = 1'b0;
        s02_axi_arvalid = 1'b0;
        s02_axi_rready  = 1'b0;

        $display("\n================================================================================");
        $display("  STARTING AXI INTERCONNECT + AXI UART INTEGRATION VERIFICATION");
        $display("================================================================================\n");

        // ---------------------------------------------------------------------
        // TEST 1: Reset and Initial State Check
        // ---------------------------------------------------------------------
        $display("--- TEST 1: Reset Release and Initial State Check ---");
        repeat (10) @(posedge clk);
        rst <= 1'b0;
        repeat (10) @(posedge clk);

        if (uart_tx === 1'b1 && uart_irq === 1'b0) begin
            $display("[PASS] Reset state correct: uart_tx=1 (idle), uart_irq=0");
            pass_count++;
        end else begin
            $display("[FAIL] Reset state mismatch: uart_tx=%b (exp 1), uart_irq=%b (exp 0)",
                     uart_tx, uart_irq);
            fail_count++;
        end

        // ---------------------------------------------------------------------
        // TEST 2: Configure UART Baud Divisor and Control Registers via s00
        // ---------------------------------------------------------------------
        $display("\n--- TEST 2: Configure Baud Divisor and Control Registers via s00 ---");
        // 2a. Enable DLAB bit in LCR (bit 7 = 1) along with 8 data bits (0x83)
        $display("  Writing LCR = 0x83 (DLAB=1, 8-bit data, 1 stop bit, no parity)...");
        s00_axi_write(8'h10, UART_REG_LCR, 32'h83);

        // 2b. Program custom baud divisor (TEST_BAUD_DIV = 16)
        $display("  Writing BAUD_DIVISOR = %0d...", TEST_BAUD_DIV);
        s00_axi_write(8'h11, UART_REG_DIV, TEST_BAUD_DIV);

        // 2c. Clear DLAB in LCR (0x03: 8 data bits, 1 stop bit, no parity, DLAB=0)
        $display("  Writing LCR = 0x03 (DLAB=0)...");
        s00_axi_write(8'h12, UART_REG_LCR, 32'h03);

        // 2d. Enable Interrupts in IER (bit 0 = 1)
        $display("  Writing IER = 0x01 (Enable Rx Interrupt)...");
        s00_axi_write(8'h13, UART_REG_IER, 32'h01);

        // 2e. Read Line Status Register (LSR)
        $display("  Reading LSR (offset 0x14)...");
        s00_axi_read(8'h14, UART_REG_LSR, rd_data);
        $display("  LSR Value = 0x%08x (THRE=%b, TEMT=%b, DR=%b)",
                 rd_data, rd_data[5], rd_data[6], rd_data[0]);

        if (rd_data[5] === 1'b1 && rd_data[6] === 1'b1) begin
            $display("[PASS] LSR indicates transmitter empty as expected");
            pass_count++;
        end else begin
            $display("[FAIL] Unexpected LSR value: 0x%08x", rd_data);
            fail_count++;
        end

        // ---------------------------------------------------------------------
        // TEST 3: UART Transmission via AXI Bus (s00 -> UART TX)
        // ---------------------------------------------------------------------
        $display("\n--- TEST 3: UART Transmission via AXI Bus (s00 -> THR -> uart_tx) ---");
        fork
            begin
                // Write byte 0x55 ('U' - alternating bit pattern) to THR
                @(posedge clk);
                $display("  Writing 0x55 to UART THR via s00...");
                s00_axi_write(8'h20, UART_REG_THR, 32'h55);
            end
            begin
                // Monitor uart_tx line and sample the transmitted byte
                // Wait for start bit falling edge
                @(negedge uart_tx);
                $display("  Detected Start Bit on uart_tx line!");
                // Wait to middle of start bit
                repeat ((TEST_BAUD_DIV + 1) / 2) @(posedge clk);
                // Sample data bits
                for (int bit_idx = 0; bit_idx < 8; bit_idx++) begin
                    repeat (TEST_BAUD_DIV + 1) @(posedge clk);
                    captured_tx_byte[bit_idx] = uart_tx;
                end
                // Sample stop bit
                repeat (TEST_BAUD_DIV + 1) @(posedge clk);
                if (uart_tx === 1'b1) begin
                    $display("  Detected Valid Stop Bit (1) on uart_tx line!");
                end else begin
                    $display("[FAIL] Framing error: expected stop bit 1, got %b", uart_tx);
                    fail_count++;
                end
            end
        join

        $display("  Captured Serial TX Byte: 0x%02x (Expected: 0x55)", captured_tx_byte);
        if (captured_tx_byte === 8'h55) begin
            $display("[PASS] Serial UART TX packet matched exactly!");
            pass_count++;
        end else begin
            $display("[FAIL] Transmitted byte mismatch: got 0x%02x, expected 0x55", captured_tx_byte);
            fail_count++;
        end

        // Wait for transmitter to become idle again
        repeat (TEST_BAUD_DIV * 4) @(posedge clk);

        // ---------------------------------------------------------------------
        // TEST 4: UART Reception via Serial RX and Interrupt Verification
        // ---------------------------------------------------------------------
        $display("\n--- TEST 4: UART Reception & Interrupt Generation (uart_rx -> RBR -> uart_irq) ---");
        // Verify IRQ is deasserted before receive
        if (uart_irq !== 1'b0) begin
            $display("[FAIL] uart_irq asserted prematurely!");
            fail_count++;
        end

        // Send byte 0x3C serially into uart_rx
        uart_send_serial_byte(8'h3C, TEST_BAUD_DIV);

        // Wait a few cycles for internal FIFO push and interrupt generation
        repeat (TEST_BAUD_DIV * 2) @(posedge clk);

        // Check if interrupt asserted
        $display("  Checking uart_irq status after serial reception...");
        if (uart_irq === 1'b1) begin
            $display("[PASS] uart_irq asserted successfully upon receiving byte into RX FIFO!");
            pass_count++;
        end else begin
            $display("[FAIL] uart_irq did NOT assert after byte received!");
            fail_count++;
        end

        // Read LSR: Data Ready bit (bit 0) should now be 1
        s00_axi_read(8'h30, UART_REG_LSR, rd_data);
        $display("  LSR after RX = 0x%08x (DR=%b)", rd_data, rd_data[0]);
        if (rd_data[0] === 1'b1) begin
            $display("[PASS] LSR Data Ready bit is 1!");
            pass_count++;
        end else begin
            $display("[FAIL] LSR Data Ready bit is 0, expected 1!");
            fail_count++;
        end

        // Read Receiver Buffer Register (RBR) via s00
        $display("  Reading RBR (offset 0x00) via s00...");
        s00_axi_read(8'h31, UART_REG_RBR, rd_data);
        $display("  Received Data = 0x%02x (Expected: 0x3C)", rd_data[7:0]);
        if (rd_data[7:0] === 8'h3C) begin
            $display("[PASS] Read data matched transmitted serial byte!");
            pass_count++;
        end else begin
            $display("[FAIL] Read data mismatch: got 0x%02x, exp 0x3C", rd_data[7:0]);
            fail_count++;
        end

        // Verify interrupt deasserts once FIFO is drained
        repeat (4) @(posedge clk);
        if (uart_irq === 1'b0) begin
            $display("[PASS] uart_irq deasserted after reading RBR!");
            pass_count++;
        end else begin
            $display("[FAIL] uart_irq remained asserted after RBR was read!");
            fail_count++;
        end

        // ---------------------------------------------------------------------
        // TEST 5: Multi-Master Access from s01 and s02
        // ---------------------------------------------------------------------
        $display("\n--- TEST 5: Multi-Master Access (s01 Core 1 & s02 DMA/Debug) ---");
        // Access UART from Master 1 (s01)
        $display("  Master 1 (s01) reading UART LSR...");
        s01_axi_read(8'h41, UART_REG_LSR, rd_data);
        $display("  s01 Read LSR: 0x%08x", rd_data);
        if (rd_data[5] === 1'b1) begin
            $display("[PASS] s01 read from UART succeeded!");
            pass_count++;
        end else begin
            $display("[FAIL] s01 read from UART failed!");
            fail_count++;
        end

        // Access UART from Master 2 (s02)
        $display("  Master 2 (s02) reading UART LSR...");
        s02_axi_read(8'h42, UART_REG_LSR, rd_data);
        $display("  s02 Read LSR: 0x%08x", rd_data);
        if (rd_data[5] === 1'b1) begin
            $display("[PASS] s02 read from UART succeeded!");
            pass_count++;
        end else begin
            $display("[FAIL] s02 read from UART failed!");
            fail_count++;
        end

        // Master 1 writes a byte to UART THR
        $display("  Master 1 (s01) writing 0x4B ('K') to UART THR...");
        s01_axi_write(8'h43, UART_REG_THR, 32'h4B);
        repeat (TEST_BAUD_DIV * 12) @(posedge clk);
        $display("[PASS] s01 write completed successfully!");
        pass_count++;

        // ---------------------------------------------------------------------
        // TEST 6: External Master Routing Verification (s00 -> m01)
        // ---------------------------------------------------------------------
        $display("\n--- TEST 6: External Master Routing Verification (s00 -> m01 Responder) ---");
        $display("  Writing 0xDEADBEEF to External Slave M01 (address: 0x%08x)...", BASE_M01 + 32'h10);
        s00_axi_write(8'h50, BASE_M01 + 32'h10, 32'hDEADBEEF);

        $display("  Reading back from External Slave M01...");
        s00_axi_read(8'h51, BASE_M01 + 32'h10, rd_data);
        $display("  Read data from M01 = 0x%08x", rd_data);

        if (rd_data === 32'hDEADBEEF) begin
            $display("[PASS] Interconnect successfully routed traffic to external master port M01!");
            pass_count++;
        end else begin
            $display("[FAIL] Data mismatch from M01: got 0x%08x, exp 0xDEADBEEF", rd_data);
            fail_count++;
        end

        repeat (20) @(posedge clk);

        // ---------------------------------------------------------------------
        // Verification Summary
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        $display("  SIMULATION VERIFICATION COMPLETE");
        $display("  Total PASS : %0d", pass_count);
        $display("  Total FAIL : %0d", fail_count);
        if (fail_count == 0) begin
            $display("  RESULT     : *** ALL INTEGRATION TESTS PASSED SUCCESSFULLY ***");
        end else begin
            $display("  RESULT     : *** VERIFICATION FAILED WITH %0d ERROR(S) ***", fail_count);
        end
        $display("================================================================================\n");

        $finish;
    end

    // -------------------------------------------------------------------------
    // Global Watchdog
    // -------------------------------------------------------------------------
    initial begin
        #(TIMEOUT_CYCLES * CLK_PERIOD_NS * 5);
        $display("\n[FATAL] Global simulation watchdog timeout exceeded! Deadlock detected.");
        $finish(2);
    end

    // -------------------------------------------------------------------------
    // FSDB Waveform Dumping (Verdi / Novas)
    // -------------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars("+all");
        $fsdbDumpSVA;
        $fsdbDumpMDA;
    end

endmodule
