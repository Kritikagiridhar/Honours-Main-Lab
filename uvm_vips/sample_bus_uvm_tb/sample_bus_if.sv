interface sample_bus_if;
  logic clk;
  logic rst_n;
  logic [31:0] addr;
  logic [31:0] wdata;
  logic write;
  logic [31:0] rdata;
  logic ready;
endinterface
