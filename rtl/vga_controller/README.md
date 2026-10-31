# Real-Time Oscilloscope VGA Display Controller (`vga_controller.sv`)

## 1. Overview & Architecture Reference
- **Module Name**: `vga_controller`
- **Source File**: [`rtl/vga_controller/vga_controller.sv`](vga_controller.sv)
- **Testbench**: [`tb/tb_vga_controller.sv`](../../tb/tb_vga_controller.sv)
- **Specification Reference**: `doc/ArchitectureDocument.md` (Section 8.9 & 10.4)
- **System Memory Base**: `0x8000_5000` (Slave Port 11 on AXI Interconnect)

The **VGA Controller** generates industry-standard 640x480 @ 60 Hz video timing and renders an authentic digital storage oscilloscope display in real time. It scans the Sample Buffer, applies vertical scaling (V/div) and vertical offset math, generates a reference graticule grid, and outputs 12-bit digital RGB444 color to an external video DAC.

```
                      +-------------------------------------------------------+
                      |                 VGA Controller                        |
                      |                                                       |
    s_axi_* --------->| [AXI4-Lite CSRs (clk_sys)]                            |
                      |   - 0x00: VGA_CTRL (EN, FREEZE, GRID, TRIG)           |
                      |   - 0x04: VGA_STATUS                                  |
                      |   - 0x08: VGA_VDIV                                    |
                      |   - 0x0C: VGA_TDIV                                    |
                      |   - 0x10: VGA_OFFSET                                  |
                      |   - 0x14: VGA_TRIG_LEVEL                              |
                      |                                                       |
                      |          [CDC Multi-Flop Parameter Bridge]            |
                      |                                                       |
    clk_vga --------->| [640x480 @ 60Hz Raster Timing Engine]                 |
                      |   - HSYNC Generator (96 pixel pulse, 800 line total)  |
                      |   - VSYNC Generator (2 line pulse, 525 frame total)   |
                      |                                                       |
    sbuf_rdata ------>| [Waveform Trace & Grid Compositor]                    |
                      |   - Y_screen = 240 - (sample * VDIV >> 8) - OFFSET    |
                      |   - 50x50 Pixel Graticule Crosshair Overlay           |
                      +---------------------------+---------------------------+
                                                  |
                                                  +---> vga_hsync, vga_vsync
                                                  +---> vga_red, green, blue
```

---

## 2. Port Interface

| Port Signal | Direction | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk_sys` | Input | 1 | `clk_sys` | Host System Clock (100 MHz) |
| `rst_sys_n` | Input | 1 | `clk_sys` | Host Reset (Active-Low) |
| `clk_vga` | Input | 1 | `clk_vga` | Pixel Clock (25.175 MHz) |
| `rst_vga_n` | Input | 1 | `clk_vga` | Video Domain Reset (Active-Low) |
| `sbuf_raddr` | Output | 12 | `clk_vga` | Read Address to Sample Buffer Port B |
| `sbuf_rdata` | Input | 16 | `clk_vga` | 16-bit signed sample read from buffer |
| `vga_hsync` | Output | 1 | `clk_vga` | Horizontal Synchronization (Active-Low) |
| `vga_vsync` | Output | 1 | `clk_vga` | Vertical Synchronization (Active-Low) |
| `vga_red` | Output | 4 | `clk_vga` | Red Color Channel (4-bit DAC) |
| `vga_green` | Output | 4 | `clk_vga` | Green Color Channel (4-bit DAC) |
| `vga_blue` | Output | 4 | `clk_vga` | Blue Color Channel (4-bit DAC) |
| `s_axi_*` | Mixed | - | `clk_sys` | Standard AXI4-Lite 32-bit slave interface |

---

## 3. Register Memory Map (`0x8000_5000`)

| Offset | Name | Type | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x00` | `VGA_CTRL` | R/W | `0x0000_0005` | Control Register<br>• Bit 0: `EN` (1 = Enable video generator)<br>• Bit 1: `FREEZE` (1 = Hold current buffer display)<br>• Bit 2: `GRID_EN` (1 = Draw 50x50 graticule grid)<br>• Bit 3: `TRIG_EN` (1 = Enable hardware trigger alignment) |
| `0x04` | `VGA_STATUS` | RO | `0x0000_0000` | Status Register<br>• Bit 0: `VSYNC_ACTIVE` (1 during vertical blank) |
| `0x08` | `VGA_VDIV` | R/W | `0x0000_0100` | Vertical scaling gain multiplier ($1.0 = \texttt{0x0100}$) |
| `0x0C` | `VGA_TDIV` | R/W | `0x0000_0001` | Horizontal decimation factor |
| `0x10` | `VGA_OFFSET` | R/W | `0x0000_0000` | Signed vertical screen center offset ($\pm 240$ pixels) |
| `0x14` | `VGA_TRIG_LEVEL`| R/W | `0x0000_0000` | 16-bit signed trigger comparator threshold |
| `0x18` | `VGA_TRIG_EDGE` | R/W | `0x0000_0001` | Trigger Edge (`1` = Rising, `0` = Falling) |

---

## 4. Video Timing & Screen Composition

### Standard 640x480 @ 60 Hz Timing Parameters
- **Horizontal**: Active = 640 px, Front Porch = 16 px, Sync Pulse = 96 px, Back Porch = 48 px (Total = 800 px)
- **Vertical**: Active = 480 lines, Front Porch = 10 lines, Sync Pulse = 2 lines, Back Porch = 33 lines (Total = 525 lines)
- **Polarity**: Both `vga_hsync` and `vga_vsync` are active-low.

### Screen Layer Compositing
1. **Background**: Deep Navy Blue (`RGB = 4'h0, 4'h0, 4'h2`).
2. **Graticule Grid**: 50x50 pixel major divisions and center dotted crosshair (`RGB = 4'h3, 4'h4, 4'h5`).
3. **Waveform Trace**: 2-pixel anti-aliased bright phosphor green trace (`RGB = 4'h0, 4'hF, 4'h2`).
4. **Trigger Marker**: Amber trigger line indicator when active (`RGB = 4'hD, 4'h8, 4'h0`).

---

## 5. Verification & Simulation
The unit testbench [`tb/tb_vga_controller.sv`](../../tb/tb_vga_controller.sv) verifies:
- Horizontal timing: Exactly 96-pixel active `vga_hsync` duration.
- Total line period: 800 pixel clocks per scanline.
- Screen rendering: Active trace and graticule pixel color generation during active display window.
- Blanking interval deassertion of RGB outputs during porch and sync phases.

### Running with Synopsys VCS
```bash
# Compile and run unit test
make vga

# Debug waveforms in Synopsys Verdi
make verdi TEST=vga
```

---

## 6. Design Provenance & Attribution
- **Origin**: Custom Developed IP Core for this Honours Project.
- **Specification Source**: Built to conform strictly with `doc/ArchitectureDocument.md` Section 8.9 & 10.4, based on standard VESA 640x480 @ 60 Hz video timing specifications.
- **Verification Status**: Fully verified in Synopsys VCS with clean pass on `make vga`.
