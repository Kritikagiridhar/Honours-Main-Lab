interface core_control_if;
  logic clk;
  logic rst_n;
  logic [30:0] rst_vec;
  logic nmi_int;
  logic [30:0] nmi_vec;
  logic [30:0] jtag_id;
endinterface
