// =============================================================================
// File       : vga_live_monitor.sv
// Description: SystemVerilog Monitor Module Hooking VGA Signals to Live Simulator
// =============================================================================

`timescale 1ns / 1ps

module vga_live_monitor (
    input wire       clk_vga,
    input wire       rst_n,
    input wire       vga_hsync,
    input wire       vga_vsync,
    input wire [3:0] vga_red,
    input wire [3:0] vga_green,
    input wire [3:0] vga_blue
);

    import "DPI-C" function void vga_dpi_init();
    import "DPI-C" function void vga_dpi_sample(
        input bit  hsync,
        input bit  vsync,
        input byte r,
        input byte g,
        input byte b
    );
    import "DPI-C" function void vga_dpi_finish();

    initial begin
        vga_dpi_init();
    end

    always @(posedge clk_vga) begin
        if (rst_n) begin
            vga_dpi_sample(vga_hsync, vga_vsync, {4'b0, vga_red}, {4'b0, vga_green}, {4'b0, vga_blue});
        end
    end

    final begin
        vga_dpi_finish();
    end

endmodule
