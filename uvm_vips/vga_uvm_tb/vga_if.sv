interface vga_if;
  logic clk;
  logic rst_n;
  logic vga_hsync;
  logic vga_vsync;
  logic [3:0] vga_red;
  logic [3:0] vga_green;
  logic [3:0] vga_blue;
endinterface
