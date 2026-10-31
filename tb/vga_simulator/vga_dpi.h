// =============================================================================
// File: vga_dpi.h
// Description: DPI-C Header for VGA Live Simulation Interface
// =============================================================================

#ifndef VGA_DPI_H
#define VGA_DPI_H

#ifdef __cplusplus
extern "C" {
#endif

// Initialize the VGA live simulation monitor
void vga_dpi_init();

// Sample VGA physical signals at every pixel clock rising edge
void vga_dpi_sample(
    unsigned char hsync,
    unsigned char vsync,
    unsigned char r,
    unsigned char g,
    unsigned char b
);

// Finalize simulation, flush final frame to disk, and print summary
void vga_dpi_finish();

#ifdef __cplusplus
}
#endif

#endif // VGA_DPI_H
