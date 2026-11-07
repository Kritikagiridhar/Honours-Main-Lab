interface gpio_if(input logic clk, input logic rst_n);
  logic [7:0] gpio_in;
  logic [7:0] gpio_out;
endinterface
