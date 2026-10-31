# PROJECT CONTEXT
# Project: RISC-V VeeR EL2 Based SoC for PWM-Controlled Peripheral Management
# ============================================================================

## WHAT THIS PROJECT IS

A complete RISC-V System-on-Chip (SoC) built around the open-source Western Digital
VeeR EL2 RISC-V core (RV32IMC), connected via a 5-master x 20-slave AXI4 crossbar
interconnect to on-chip memory and custom peripheral IPs.

The three PROJECT IPs are:
  1. **4-Channel PWM Generator** (M04 @ 0x4000_2000) — programmable duty-cycle waveform generation
  2. **Watchdog Timer** (M09 @ 0x4000_E000) — autonomous system-fault detection and recovery
  3. **4-Digit Seven-Segment Display Controller** (M05 @ 0x4000_4000) — direct visual feedback

Supporting peripherals: UART, Timer, GPIO, SPI.

## REFERENCE REPOSITORY (NOT to be modified)

This project was derived from the reference repo:
  https://github.com/Sasmonk/honours_project_soc

The reference repo's DSP/visualization pipeline (DMA, FIR filter, VGA controller,
sample buffer) was REMOVED and replaced with the Smart Control IPs (PWM, SSD).
The reference repo itself was NEVER modified — it was only used as a template.

## VERIFICATION STATUS

Fully verified in Synopsys VCS + Verdi:
  - Compilation: 0 errors, 0 warnings
  - Simulation: 26/26 self-checking tests PASS
  - Verdi KDB database generated successfully
  - VeeR EL2 core executes 3671+ instructions from on-chip IMEM

Run with:
  make soc          (compile + simulate)
  make soc-verdi    (open waveforms)

## MEMORY MAP

| Address      | Component  | Bus       | Role                          |
|-------------|-----------|-----------|-------------------------------|
| 0x1000_0000 | IMEM      | AXI4      | 64 KB instruction memory      |
| 0x1002_0000 | DMEM      | AXI4      | 64 KB data memory             |
| 0x4000_2000 | PWM       | AXI4-Lite | 4-channel PWM controller      |
| 0x4000_4000 | SSD       | AXI4-Lite | 4-digit seven-segment display |
| 0x4000_6000 | UART      | AXI4      | Serial debug (115200 baud)    |
| 0x4000_8000 | Timer     | AXI4-Lite | Acquisition timer             |
| 0x4000_A000 | GPIO      | AXI4-Lite | 8-bit I/O with edge IRQ       |
| 0x4000_C000 | SPI       | AXI4-Lite | SPI master for ADC            |
| 0x4000_E000 | Watchdog  | AXI4-Lite | Safety monitor (NMI + reset) |

## COMPLETE FILE INVENTORY

### NEW FILES (created for this project — student's own work)

| File | Description |
|------|-------------|
| `rtl/pwm/pwm.sv` | 4-channel PWM controller. AXI4-Lite slave. Registers: CTRL (ch enable), PERIOD (shared), DUTY0-3 (per-channel), STATUS (running RO), IRQ_CTRL. Output: pwm_out[3:0]. |
| `rtl/seven_segment/seven_segment.sv` | 4-digit multiplexed 7-segment display controller. AXI4-Lite slave. Registers: CTRL (EN, MODE=hex/raw), DATA (16-bit, nibble per digit), BRIGHT (refresh prescaler), STATUS. Outputs: seg[7:0] (active-low cathodes), digit_sel[3:0] (active-low anodes). Built-in hex-to-7seg LUT. |
| `run/run_vcs_soc.sh` | VCS + Verdi run script (compile, simulate, optionally launch Verdi). |
| `README.md` | Full project documentation. |
| `PROJECT_CONTEXT.md` | This file — context for AI handoff. |

### MODIFIED FILES (changed from reference for this project)

| File | What Changed |
|------|-------------|
| `rtl/soc_top.sv` | SoC top-level. Removed DMA/FIR/VGA/SBUF. Added PWM (M04) and SSD (M05) AXI4-Lite instances via axi4_to_axil_lite bridges. Removed clk_vga and VGA output ports; added pwm_out[3:0], ssd_seg[7:0], ssd_digit_sel[3:0]. Tied off M03 (I2C), M10-M13 (removed IPs) with DECERR stubs. Tied off S03 (DMA master port). Remapped PIC interrupts: [0]=UART, [1]=Timer, [2]=GPIO, [3]=SPI, [4]=PWM. Changed watchdog pipeline_alive to {0,0,sample_tick,uart_irq}. |
| `tb/tb_soc_top.sv` | Self-checking testbench. Preloads 51 hand-assembled RISC-V instructions into IMEM (MRAC CSR config + UART + GPIO + PWM + SSD + DMEM + Timer + SPI + Watchdog). 26 assertions covering reset, CPU execution, UART Tx/Rx, GPIO, PWM (4 channels), SSD (data+multiplexing), SPI ADC acquisition, DMEM, Watchdog, PIC interrupts. Includes adc_model for SPI testing. FSDB waveform dump for Verdi. |
| `run/filelist_soc.f` | VCS file list. Added pwm.sv and seven_segment.sv. Removed fir_filter, sample_buffer, dma_controller, vga_controller. |
| `Makefile` | Updated project name and help text to reflect Smart Control SoC. The `soc` target compiles+simulates using filelist_soc.f. |

### REUSED UNCHANGED (shared infrastructure, same as reference)

| File / Dir | Role |
|-----------|------|
| `rtl/veer_el2/` | VeeR EL2 RISC-V core (RV32IMC) — entire design + configs + snapshots |
| `rtl/interconnect/` | AXI4 crossbar (arbiter, priority encoder, 5x20 wrap) + 64-to-32 adapter |
| `rtl/axi_interconnect_uart_top.v` | Top interconnect integrating UART at M00 |
| `rtl/axi_uart/` | AXI UART 16550 IP |
| `lib/axi4_to_axil_lite.sv` | AXI4-Full to AXI4-Lite bridge (used for PWM, SSD, Timer, GPIO, SPI, Watchdog) |
| `lib/axi_ram.sv` | AXI4 on-chip memory model (used for IMEM, DMEM) |
| `lib/cdc_sync.sv` | Clock-domain crossing synchronizer |
| `lib/sync_fifo.sv` | Synchronous FIFO |
| `rtl/timer/timer.sv` | Acquisition timer (sample_tick output feeds SPI) |
| `rtl/gpio/gpio.sv` | GPIO controller (8-bit I/O) |
| `rtl/spi_controller/spi_controller.sv` | SPI master (Mode 0, auto-trigger from timer) |
| `rtl/watchdog/watchdog.sv` | Watchdog safety monitor (NMI + reset) |
| `tb/adc_model.sv` | Behavioral SPI slave ADC model (sine/square/triangle/DC patterns) |

## KEY DESIGN PATTERNS

### AXI4-Lite Slave IP Pattern
All peripheral IPs (PWM, SSD, Timer, GPIO, SPI, Watchdog) follow the same pattern:
  - Separate always blocks for Write channel (AW+W -> B) and Read channel (AR -> R)
  - Latch awaddr on AW handshake, wait for W handshake, then write register and assert B
  - Read: on AR handshake, decode address, drive rdata, assert R
  - rst_n active-low reset, OKAY (2'b00) response

### Interconnect Connection
  - CPU (LSU/IFU/SB) -> 64-to-32 AXI adapters -> interconnect S00/S01/S02
  - Each peripheral: interconnect master port (mXX) -> axi4_to_axil_lite bridge -> IP
  - S03 (was DMA master) and S04 tied off
  - M03 (I2C) and M10-M13 (DMA/FIR/VGA/SBUF) stubbed with DECERR

### CPU Firmware (in testbench preload_firmware task)
  - Instruction 0-2:  Configure MRAC CSR (0x7C0) = 0xAAAAAAA6 (memory region access)
  - Instruction 3-9:   Configure UART, transmit 'A'
  - Instruction 10-13: Configure GPIO, output 0xA5
  - Instruction 14-26: Configure PWM (period=10, duty=3/5/7/2, enable all 4 channels)
  - Instruction 27-34: Configure SSD (data=0x1234, brightness=5, enable hex mode)
  - Instruction 35-38: DMEM write/read test (store 123, read back)
  - Instruction 39-43: Configure Timer (reload=200, enable)
  - Instruction 44-46: Configure SPI (prescaler=2, auto-trigger, enable)
  - Instruction 47-49: Configure Watchdog (enable)
  - Instruction 50:    Infinite loop (jal x0, 0)

## TOOL ENVIRONMENT

  VCS_HOME      = /home/student/snps_tools_target/vcs/U-2023.03
  VERDI_HOME    = /home/student/snps_tools_target/verdi/U-2023.03-SP1
  SNPSLMD_LICENSE_FILE = 27021@14.139.1.126
  Compile cmd:  vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -f filelist_soc.f
  Sim cmd:      ./simv -l sim_soc.log
  Verdi cmd:    verdi -dbdir simv.daidir -ssf dump.fsdb
