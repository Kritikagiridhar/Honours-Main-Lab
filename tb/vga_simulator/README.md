# RISC-V SoC Live VGA Display Simulator

This directory integrates and adapts the VGA Display Simulator from [Saman Mohseni's VGA-Simulation](https://github.com/SamanMohseni/VGA-Simulation) for the **Honours RISC-V Real-Time Signal Processing & VGA Oscilloscope SoC**.

---

## 1. Overview & Capabilities

The simulator accurately models a standard 640x480 @ 60 Hz VGA monitor driven by the SoC's hardware VGA Controller (`rtl/vga_controller/vga_controller.sv`).

- **Physical Timing Verification:**
  - Pixel Clock: 25.175 MHz (`clk_vga`)
  - Horizontal Timing (800 pixels/line): Active (640), Front Porch (16), HSYNC (96), Back Porch (48)
  - Vertical Timing (525 lines/frame): Active (480), Front Porch (10), VSYNC (2), Back Porch (33)
- **High-Fidelity 12-bit RGB444 Sampling:**
  - Samples physical wires `vga_hsync`, `vga_vsync`, `vga_red[3:0]`, `vga_green[3:0]`, `vga_blue[3:0]`.
  - Resynchronizes raster coordinates `(x, y)` on sync pulse edges.
- **Dual Display Modes:**
  1. **Live OpenGL GUI Window:** Real-time 60 FPS interactive desktop display using FreeGLUT / OpenGL. Supports keyboard controls (`'s'` to save snapshot, `'q'` / `ESC` to quit).
  2. **Automated Headless Frame Capture:** Flushes pixel-perfect 24-bit uncompressed `.bmp` and `.ppm` image files (`vga_live_frame.bmp`, `vga_live_frame.ppm`) upon every vertical refresh pulse. Ideal for headless CI/CD, batch regression, and artifact generation.
- **Zero-Dependency Portability:** Includes self-contained FreeGLUT headers and static library for seamless compilation without requiring `sudo` or system package managers.

---

## 2. Directory Structure

```
tb/vga_simulator/
├── README.md                 # This documentation
├── README_SamanMohseni.md    # Upstream reference documentation
├── LICENSE_SamanMohseni      # Upstream MIT License
├── VGA_Simulator.png         # Upstream reference screenshot
├── vga_dpi.h                 # C-linkage DPI interface header
├── vga_live_sim.cpp          # C++ DPI simulation engine (OpenGL + BMP/PPM exporters)
├── vga_live_monitor.sv       # SystemVerilog plug-and-play monitor wrapper
├── freeglut/                 # Pre-packaged self-contained FreeGLUT headers & lib64
│   ├── include/GL/
│   └── lib64/libglut.a
├── simulator.cpp             # Upstream standalone simulator reference
├── display.v                 # Upstream reference top module
├── graphics.v                # Upstream reference test pattern generator
└── vga_controller.v          # Upstream reference VGA sync generator
```

---

## 3. How to Run

### Run from Root Repository Makefile:

- **Run Live Simulation (Headless Frame Capture):**
  ```bash
  make vga-live
  ```
  Generates `run/vga_live_frame.bmp` and `run/vga_live_frame.ppm`. Viewable with `eog run/vga_live_frame.bmp`.

- **Run with Live OpenGL GUI Window:**
  ```bash
  make vga-live-gui
  ```
  Opens an interactive 640x480 desktop window displaying the live hardware oscilloscope output in real time.

- **Open Verdi Waveforms:**
  ```bash
  make vga-live-verdi
  ```

---

## 4. Hooking into Custom Testbenches

To monitor VGA outputs in any SystemVerilog testbench, instantiate `vga_live_monitor`:

```systemverilog
vga_live_monitor u_vga_monitor (
    .clk_vga  (clk_vga),
    .rst_n    (rst_n),
    .vga_hsync(vga_hsync),
    .vga_vsync(vga_vsync),
    .vga_red  (vga_red),
    .vga_green(vga_green),
    .vga_blue (vga_blue)
);
```

Add `../tb/vga_simulator/vga_live_monitor.sv` and `../tb/vga_simulator/vga_live_sim.cpp` to your VCS filelist.
