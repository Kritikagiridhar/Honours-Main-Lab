# RTL Architecture & Subsystem Integration Hub

[![Hardware](https://img.shields.io/badge/Hardware-Verilog%20%7C%20SystemVerilog-blue.svg)](#3-rtl-directory-organization)
[![Bus](https://img.shields.io/badge/Bus-AXI4%20Crossbar-brightgreen.svg)](#2-top-level-integration-axi_interconnect_uart_top)
[![Parent System](https://img.shields.io/badge/SoC-Root%20README-orange.svg](../README.md)
[![Verification](https://img.shields.io/badge/Verification-VCS%20%26%20Verdi-purple.svg)](#5-verification-and-simulation-suite)

> **Navigation:** [Root README](../README.md) &nbsp;|&nbsp; [VeeR EL2 Core](veer_el2/README.md) &nbsp;|&nbsp; [AXI Interconnect](interconnect/README.md) &nbsp;|&nbsp; [AXI UART](axi_uart/README.md) &nbsp;|&nbsp; [Acquisition Timer](timer/README.md) &nbsp;|&nbsp; [GPIO](gpio/README.md) &nbsp;|&nbsp; [FIR Filter](fir_filter/README.md) &nbsp;|&nbsp; [DMA Controller](dma_controller/README.md) &nbsp;|&nbsp; [Sample Buffer](sample_buffer/README.md) &nbsp;|&nbsp; [VGA Controller](vga_controller/README.md) &nbsp;|&nbsp; [Watchdog](watchdog/README.md) &nbsp;|&nbsp; [AES Core (Experimental)](aes_core-master/README.md)

---

## 1. Overview

The `rtl/` directory contains all synthesizable SystemVerilog and Verilog IP cores, bus interconnect logic, and subsystem integration wrappers comprising the **RISC-V Real-Time Signal Acquisition, FIR Filtering, and VGA Oscilloscope SoC**.

The system combines high-performance multi-master AXI4 crossbar switching with dedicated hardware streaming datapaths, ensuring that heavy real-time sample processing (ADC acquisition, FIR digital filtering, and pixel-by-pixel VGA waveform rendering) proceeds autonomously without stalling the host RISC-V processor.

```
+----------------------------------------------------------------------------------------------------+
|                                    RISC-V Oscilloscope SoC                                         |
|                                                                                                    |
|   +--------------------+         +-----------------------+         +---------------------------+   |
|   |   VeeR EL2 Core    |         |    DMA Controller     |         |     Acquisition Timer     |   |
|   |  (RV32IMC 100MHz)  |         | (SPI Master & Stream) |         |     (Pacing Generator)    |   |
|   +---------+----------+         +-----------+-----------+         +-------------+-------------+   |
|             | Master 0                       | Master 1                          | sample_tick     |
|             v                                v                                   v                 |
|   =============================================================================================    |
|                                 AXI4 Crossbar Interconnect Fabric                                  |
|   =============================================================================================    |
|        |           |            |             |              |             |            |          |
|        v           v            v             v              v             v            v          |
|     +-----+     +------+     +-----+     +----------+     +------+     +-------+     +------+      |
|     |UART |     | GPIO |     | FIR |     |  Sample  |     | VGA  |     | WDT   |     | AES* |      |
|     |16550|     |16-bit|     |16-T |     |  Buffer  |     |640x  |     |Safety |     |Exper.|      |
|     |Port0|     |Port8 |     |Port9|     | 4096x16  |     | 480  |     |Port12 |     |Port1 |      |
|     +-----+     +------+     +-----+     +----+-----+     +---+--+     +-------+     +------+      |
|                                               ^               ^                                    |
|                                               | (Dual-Port)   | (clk_vga 25MHz)                    |
|                                               +---------------+                                    |
+----------------------------------------------------------------------------------------------------+
```
*\*Note: AES core is included purely as an experimental peripheral for learning AXI CSR interfacing.*

---

## 2. Top-Level Integration (`axi_interconnect_uart_top.v`)

The module `axi_interconnect_uart_top.v` provides a validated subsystem uniting the **5-Master x 20-Slave AXI Interconnect** with the **AXI4-Lite UART IP core**:

- **Slave Ports (`s00`..`s04`):** Exposed to connect bus masters:
  - `s00`: VeeR EL2 RISC-V Core Load/Store Unit (LSU) port.
  - `s01`: VeeR EL2 Instruction Fetch Unit (IFU) port.
  - `s02`: VeeR EL2 System Bus / Debug (SB) port.
  - `s03`: DMA Controller Master for streaming sample data.
  - `s04`: Accelerator / co-processor master (reserved for expansion).
- **Master Port 00 (`m00`):** Connected internally to `axi_uart_top`, providing instant serial communication out-of-the-box.
- **Master Ports 01..19 (`m01..m19`):** Exported to the module boundary for peripheral and memory attachment (AES core, memories, accelerators, etc.).
- **Physical Pins:** Serial lines `uart_rx` and `uart_tx` along with interrupt `uart_irq` are routed to the top-level boundary.

---

## 3. RTL Directory Organization

| Subsystem / IP Core | Source Location | Provenance / Origin | Description | Documentation |
| :--- | :--- | :---: | :--- | :---: |
| **VeeR EL2 Core** | [`veer_el2/`](veer_el2/) | **Open-Source**<br/>(CHIPS Alliance / WD, Apache 2.0) | Western Digital RV32IMC RISC-V 4-stage pipelined core with ICCM/DCCM and PIC | [**README**](veer_el2/README.md) |
| **AXI Interconnect** | [`interconnect/`](interconnect/) | **Open-Source**<br/>(Alex Forencich, BSD 2-Clause) | Multi-master parameterized AXI4 crossbar with round-robin arbitration (**5x20**) | [**README**](interconnect/README.md) |
| **AXI UART** | [`axi_uart/`](axi_uart/) | **Open-Source**<br/>(BSC / Abraham J. Ruiz R., GPL-3.0) | 16550-compatible AXI4-Lite UART with 16-byte FIFOs, programmable baud, and interrupts | [**README**](axi_uart/README.md) |
| **Acquisition Timer** | [`timer/`](timer/) | **Custom Developed**<br/>(Honours Spec §8.5) | High-resolution 24-bit down-counter with auto-reload generating periodic `sample_tick` strobes | [**README**](timer/README.md) |
| **GPIO Controller** | [`gpio/`](gpio/) | **Custom Developed**<br/>(Honours Spec §8.8) | 16-bit GPIO with double-flop synchronizers, edge interrupt detection, and LED drive registers | [**README**](gpio/README.md) |
| **FIR Filter** | [`fir_filter/`](fir_filter/) | **Custom Developed**<br/>(Honours Spec §8.7) | 16-tap Q1.15 fixed-point DSP digital filter with configurable tap bank and single-cycle bypass | [**README**](fir_filter/README.md) |
| **DMA Controller** | [`dma_controller/`](dma_controller/) | **Custom Developed**<br/>(Honours Spec §8.6) | Autonomous acquisition engine sequencing SPI ADC transactions and streaming to FIR & RAM | [**README**](dma_controller/README.md) |
| **Sample Buffer** | [`sample_buffer/`](sample_buffer/) | **Custom Developed**<br/>(Honours Spec §8.4) | 4096-entry x 16-bit True Dual-Port asynchronous RAM bridging acquisition, CPU math, and VGA display | [**README**](sample_buffer/README.md) |
| **VGA Controller** | [`vga_controller/`](vga_controller/) | **Custom Developed**<br/>(Honours Spec §8.9) | 640x480 @ 60 Hz oscilloscope display generator with 50px graticule, trace rendering, and triggers | [**README**](vga_controller/README.md) |
| **Watchdog Timer** | [`watchdog/`](watchdog/) | **Custom Developed**<br/>(Honours Spec §8.10) | Safety monitor with security-keyed kick, NMI pre-warning, and hardware system reset trip | [**README**](watchdog/README.md) |
| **Subsystem Top** | [`axi_interconnect_uart_top.v`](axi_interconnect_uart_top.v) | **Custom Integrated** | Pre-integrated subsystem connecting 5 masters to UART and 19 external slave ports | [**Section 2**](#2-top-level-integration-axi_interconnect_uart_top) |
| **AES Core (Experimental)** | [`aes_core-master/`](aes_core-master/) | **Open-Source**<br/>(Secworks, BSD 2-Clause) | NIST FIPS-197 AES-128/256 accelerator for learning AXI memory-mapped CSR interfacing | [**README**](aes_core-master/README.md) |
| **Shared Libraries** | [`../lib/`](../lib/) | **Custom Developed** | Clock-domain-crossing synchronizers (`cdc_sync.sv`) and synchronous FIFOs (`sync_fifo.sv`) | — |

---

## 4. Hardware Modules Defined in Architecture Specification

Per [`doc/ArchitectureDocument.md`](../doc/ArchitectureDocument.md), the complete SoC integrates the following dedicated hardware accelerators and peripherals:

### 4.1 System Timer ([`rtl/timer/timer.sv`](timer/timer.sv))
- **Function:** Programmable countdown timer generating the precise `sample_tick` pulse stream governing ADC acquisition frequency.
- **Base Address:** `0x8000_1000` (Slave Port 7).
- **Documentation:** [Acquisition Timer README](timer/README.md).

### 4.2 General Purpose I/O ([`rtl/gpio/gpio.sv`](gpio/gpio.sv))
- **Function:** Captures user button inputs (oscilloscope scale, trigger level, freeze/hold toggling) with internal double-flop synchronization and drives status LEDs.
- **Base Address:** `0x8000_2000` (Slave Port 8).
- **Documentation:** [GPIO README](gpio/README.md).

### 4.3 Hardware FIR Filter Engine ([`rtl/fir_filter/fir_filter.sv`](fir_filter/fir_filter.sv))
- **Function:** Multi-tap digital filtering pipeline operating directly on streaming ADC sample words.
- **Pipeline:** Fixed-point Q1.15 multiply-accumulate (MAC) architecture with 16 programmable coefficient registers (`FIR_COEFF_0` to `FIR_COEFF_15`).
- **Modes:** Active filtering mode or single-cycle hardware bypass (`FIR_CTRL.BYPASS = 1`) to enable real-time A/B signal comparison.
- **Base Address:** `0x8000_3000` (Slave Port 9).
- **Documentation:** [FIR Filter README](fir_filter/README.md).

### 4.4 Autonomous DMA Controller ([`rtl/dma_controller/dma_controller.sv`](dma_controller/dma_controller.sv))
- **Function:** Transfers streaming sample data between external ADC, data memory staging buffers, FIR filter, and the VGA sample buffer without CPU intervention.
- **Base Address:** `0x8000_4000` (Slave Port 10).
- **Documentation:** [DMA Controller README](dma_controller/README.md).

### 4.5 Dual-Port Sample Buffer ([`rtl/sample_buffer/sample_buffer.sv`](sample_buffer/sample_buffer.sv))
- **Function:** 4096-entry x 16-bit True Dual-Port asynchronous RAM.
- **Write Port:** Clocked to `clk_sys` (100 MHz), driven by the DMA controller.
- **Read Port AXI:** Clocked to `clk_sys`, accessible by RISC-V CPU at `0x0002_0000` for $V_{\text{pp}}$, $V_{\text{rms}}$, and frequency measurement math.
- **Read Port VGA:** Clocked to `clk_vga` (25.175 MHz), read continuously by the VGA controller pixel pipeline.
- **Base Address:** `0x0002_0000` (Slave Port 5, 8 KB aperture).
- **Documentation:** [Sample Buffer README](sample_buffer/README.md).

### 4.6 VGA Oscilloscope Controller ([`rtl/vga_controller/vga_controller.sv`](vga_controller/vga_controller.sv))
- **Function:** Renders real-time oscilloscope waveform traces and a reference grid overlay directly to standard 640x480 @ 60 Hz VGA displays.
- **Controls:** Programmable Volts/Division (`VGA_VDIV`), Time/Division (`VGA_TDIV`), vertical trace offset (`VGA_OFFSET`), and hardware trigger level (`VGA_TRIG_LEVEL`).
- **Base Address:** `0x8000_5000` (Slave Port 11).
- **Documentation:** [VGA Controller README](vga_controller/README.md).

### 4.7 Watchdog Timer ([`rtl/watchdog/watchdog.sv`](watchdog/watchdog.sv))
- **Function:** Fail-safe hardware monitor tapping pipeline liveness flags from Timer, DMA, FIR, and VGA controllers.
- **Safety Sequence:** Issues Non-Maskable Interrupt pre-warning (`wdt_nmi`) 1 tick before asserting hard system reset (`wdt_reset`).
- **Base Address:** `0x8000_6000` (Slave Port 12).
- **Documentation:** [Watchdog README](watchdog/README.md).

---

## 5. Verification and Simulation Suite

All RTL IP cores are verified with unit and integration testbenches using **Synopsys VCS** and debugged using **Synopsys Verdi**.

| Test Target | Makefile Command | Testbench File | Status | Description |
| :--- | :--- | :--- | :---: | :--- |
| **Timer** | `make timer` | [`tb/tb_timer.sv`](../tb/tb_timer.sv) | **PASSED** | Counter reload, `sample_tick`, IRQ, W1C |
| **GPIO** | `make gpio` | [`tb/tb_gpio.sv`](../tb/tb_gpio.sv) | **PASSED** | Double-flop sync, edge IRQ, LED drive, W1C |
| **FIR Filter** | `make fir` | [`tb/tb_fir_filter.sv`](../tb/tb_fir_filter.sv) | **PASSED** | Bypass mode, coefficient load, 4-tap MAC step response |
| **Sample Buffer**| `make sample_buffer`| [`tb/tb_sample_buffer.sv`](../tb/tb_sample_buffer.sv)| **PASSED** | Dual-clock asynchronous write & AXI DP5 readback |
| **DMA** | `make dma` | [`tb/tb_dma_controller.sv`](../tb/tb_dma_controller.sv)| **PASSED** | SPI transfer with ADC model, FIR routing, SBUF write |
| **VGA** | `make vga` | [`tb/tb_vga_controller.sv`](../tb/tb_vga_controller.sv)| **PASSED** | 640x480 timing, 96px HSYNC, graticule & trace pixels |
| **Watchdog** | `make watchdog` | [`tb/tb_watchdog.sv`](../tb/tb_watchdog.sv) | **PASSED** | Counter kick, reload, NMI pre-warn, hard reset trip |
| **Pipeline** | `make pipeline` | [`tb/tb_soc_pipeline.sv`](../tb/tb_soc_pipeline.sv) | **PASSED** | End-to-end acquire $\rightarrow$ filter $\rightarrow$ buffer $\rightarrow$ VGA $\rightarrow$ CPU math |
| **Regression** | `make test-all` | *(All above)* | **PASSED** | Runs complete test suite cleanly in sequence |

---

## 6. Related Documentation

- [Root README](../README.md) — Main Project README & Architecture Specification
- [Architecture Document](../doc/ArchitectureDocument.md) — Full Register & Signal Blueprint
- [Acquisition Timer README](timer/README.md)
- [GPIO Controller README](gpio/README.md)
- [FIR Filter README](fir_filter/README.md)
- [DMA Controller README](dma_controller/README.md)
- [Sample Buffer README](sample_buffer/README.md)
- [VGA Display Controller README](vga_controller/README.md)
- [Watchdog Monitor README](watchdog/README.md)
- [VeeR EL2 Core README](veer_el2/README.md)
- [AXI Interconnect README](interconnect/README.md)
- [AXI UART README](axi_uart/README.md)
- [AES Core README](aes_core-master/README.md)
