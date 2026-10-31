# Architecture Document
## Peripheral Management SoC — RISC-V VeeR EL2

**Status:** Release v3.0 — Peripheral Management SoC  
**Scope:** RTL Design + Simulation-Based Verification (Synopsys VCS U-2023.03 / Verdi)  
**Target Core:** Western Digital RISC-V VeeR EL2 (RV32IMC Dual-Issue Superscalar)  
**Bus Interconnect:** AXI4 / AXI4-Lite Crossbar (`axi_interconnect_uart_top`)  

---

## 1. Executive Summary

This document specifies the hardware architecture of the **Peripheral Management SoC**.

The SoC integrates a **32-bit RISC-V VeeR EL2** processor core with six AXI4-Lite
peripheral IPs — PWM, Seven-Segment Display (SSD), UART, Timer, GPIO, and Watchdog —
plus on-chip Instruction and Data memories (IMEM/DMEM). The CPU configures all
peripherals over memory-mapped AXI/AXI4-Lite registers. A Watchdog Safety Monitor
ensures system liveness and can assert an NMI pre-warning and hard reset if the
system stalls.

### What is NOT in this project
The following IPs exist in the repository as standalone RTL but are **not**
instantiated in `soc_top` and are **not** part of the Peripheral Management SoC:

| Removed IP        | Reason |
|-------------------|--------|
| SPI Master Controller | Not a project peripheral |
| DMA Controller        | Not a project peripheral |
| FIR Filter            | Not a project peripheral |
| VGA Controller        | Not a project peripheral |
| Sample Buffer         | Not a project peripheral |

The M08 address slot (`0x4000_C000`) that was previously used by SPI is stubbed
with an AXI DECERR responder inside `soc_top`.

---

## 2. System Block Diagram

```
+-----------------------------------------------------------------------+
|                     Peripheral Management SoC                         |
|                           soc_top.sv                                  |
|                                                                       |
|  +---------------------+  64-bit AXI4  +---------------------------+ |
|  |   VeeR EL2 RV32IMC  |<=============>|  3x AXI 64-to-32 Adapters | |
|  |  LSU / IFU / SB     |               |  (LSU, IFU, SB)           | |
|  |  Integrated PIC     |               +-------------+-------------+ |
|  +---------------------+                             |               |
|                                                      | 32-bit AXI4   |
|                          +---------------------------+               |
|                          |   axi_interconnect_uart_top               |
|                          |   (AXI4 Crossbar Fabric)                  |
|     +--------------------+----+----+----+----+----+--+              |
|     |        |      |    |    |    |    |    |    |                  |
|  +--+--+  +--+--+  PWM  SSD  UART TMR GPIO  WDT  |                 |
|  |IMEM |  |DMEM |  M04  M05  built M06  M07  M09  stub              |
|  |64KB |  |64KB |  2000 4000 -in   8000 A000 E000 (DECERR)          |
|  |1000_|  |1002_|       4000 6000                                    |
|  |0000 |  |0000 |                                                    |
|  +-----+  +-----+                                                    |
+-----------------------------------------------------------------------+

External Pins:
  uart_rx/tx     — serial debug
  gpio_in[7:0]   — switches/buttons
  gpio_out[7:0]  — LEDs
  pwm_out[3:0]   — 4-channel PWM signals
  ssd_seg[7:0]   — segment cathodes
  ssd_digit_sel  — digit anodes
  wdt_reset_out  — watchdog reset indicator
```

---

## 3. Top-Level Port List (`soc_top.sv`)

| Port                | Dir    | Width | Description                            |
|---------------------|--------|-------|----------------------------------------|
| `clk`               | Input  | 1     | 100 MHz system clock                   |
| `rst_n`             | Input  | 1     | Active-low asynchronous reset          |
| `rst_vec[31:1]`     | Input  | 31    | VeeR EL2 reset vector                 |
| `nmi_int`           | Input  | 1     | External NMI input                     |
| `nmi_vec[31:1]`     | Input  | 31    | NMI handler address                    |
| `jtag_id[31:1]`     | Input  | 31    | Core JTAG identifier                   |
| `uart_rx`           | Input  | 1     | UART serial receive                    |
| `uart_tx`           | Output | 1     | UART serial transmit                   |
| `uart_irq`          | Output | 1     | UART interrupt to PIC                  |
| `gpio_in[7:0]`      | Input  | 8     | External GPIO input pins               |
| `gpio_out[7:0]`     | Output | 8     | External GPIO output pins              |
| `pwm_out[3:0]`      | Output | 4     | 4-channel PWM outputs                  |
| `ssd_seg[7:0]`      | Output | 8     | SSD segment cathodes (active-low)      |
| `ssd_digit_sel[3:0]`| Output | 4     | SSD digit anodes (active-low one-hot)  |
| `wdt_reset_out`     | Output | 1     | Watchdog hard reset indicator          |
| `ext_irq`           | Input  | varies| External interrupt expansion           |
| `timer_int`         | Input  | 1     | External timer interrupt input         |

---

## 4. Memory Map & Address Decode

| Slot | Peripheral              | Base Address   | Size  | Protocol  |
|------|-------------------------|---------------|-------|-----------|
| M01  | IMEM (Instruction RAM)  | `0x1000_0000` | 64 KB | AXI4      |
| M02  | DMEM (Data RAM)         | `0x1002_0000` | 64 KB | AXI4      |
| M03  | Reserved (DECERR)       | `0x4000_0000` | 4 KB  | DECERR    |
| M04  | PWM Controller          | `0x4000_2000` | 4 KB  | AXI4-Lite |
| M05  | SSD Controller          | `0x4000_4000` | 4 KB  | AXI4-Lite |
| UART | AXI UART 16550          | `0x4000_6000` | 4 KB  | AXI4      |
| M06  | System Timer            | `0x4000_8000` | 4 KB  | AXI4-Lite |
| M07  | GPIO Controller         | `0x4000_A000` | 4 KB  | AXI4-Lite |
| M08  | Reserved (DECERR)       | `0x4000_C000` | 4 KB  | DECERR    |
| M09  | Watchdog Monitor        | `0x4000_E000` | 4 KB  | AXI4-Lite |

---

## 5. Peripheral Register Maps

### 5.1 PWM Controller — Base `0x4000_2000`

| Offset | Register     | Bits    | Description                          |
|--------|--------------|---------|--------------------------------------|
| `0x00` | PWM_CTRL     | [3:0]   | CH_EN — per-channel enable           |
| `0x04` | PWM_PERIOD   | [15:0]  | Common period in clock cycles        |
| `0x08` | PWM_DUTY0    | [15:0]  | CH0 high-time count                  |
| `0x0C` | PWM_DUTY1    | [15:0]  | CH1 high-time count                  |
| `0x10` | PWM_DUTY2    | [15:0]  | CH2 high-time count                  |
| `0x14` | PWM_DUTY3    | [15:0]  | CH3 high-time count                  |
| `0x18` | PWM_STATUS   | [3:0]   | RUNNING — per-channel active (RO)    |
| `0x1C` | PWM_IRQ_CTRL | [0]     | IRQ_EN — period rollover interrupt   |

Output: `pwm_out[3:0]`, `irq_pwm`

### 5.2 Seven-Segment Display — Base `0x4000_4000`

| Offset | Register   | Bits   | Description                             |
|--------|------------|--------|-----------------------------------------|
| `0x00` | SSD_CTRL   | [0]    | EN — display enable                     |
|        |            | [1]    | MODE — 0=hex decode, 1=raw segment data |
| `0x04` | SSD_DATA   | [15:0] | Display value (nibble per digit)        |
| `0x08` | SSD_BRIGHT | [7:0]  | Multiplex refresh prescaler             |
| `0x0C` | SSD_STATUS | [0]    | RUNNING (RO)                            |

Outputs: `ssd_seg[7:0]` (cathodes, active-low), `ssd_digit_sel[3:0]` (anodes, one-hot)

### 5.3 System Timer — Base `0x4000_8000`

| Offset | Register     | Bits   | Description                    |
|--------|--------------|--------|--------------------------------|
| `0x00` | TIMER_CTRL   | [0]    | EN — timer enable              |
| `0x04` | TIMER_RELOAD | [31:0] | Reload value (clock cycles)    |
| `0x08` | TIMER_COUNT  | [31:0] | Current count (RO)             |
| `0x0C` | TIMER_STATUS | [0]    | TICK (W1C) — period elapsed    |

Outputs: `sample_tick` (1-cycle pulse), `irq_timer`

### 5.4 GPIO Controller — Base `0x4000_A000`

| Offset | Register    | Bits  | Description                           |
|--------|-------------|-------|---------------------------------------|
| `0x00` | GPIO_IN     | [7:0] | Synchronized input values (RO)        |
| `0x04` | GPIO_OUT    | [7:0] | Output drive register                 |
| `0x08` | GPIO_IRQ_EN | [7:0] | Per-bit change interrupt enable       |
| `0x0C` | GPIO_STATUS | [0]   | CHANGED — edge detected (W1C)         |

Ports: `gpio_in[7:0]` (input), `gpio_out[7:0]` (output), `irq_gpio`

### 5.5 Watchdog Monitor — Base `0x4000_E000`

| Offset | Register   | Bits   | Description                            |
|--------|------------|--------|----------------------------------------|
| `0x00` | WDT_CTRL   | [0]    | EN — watchdog enable                   |
| `0x04` | WDT_RELOAD | [31:0] | Timeout countdown reload value         |
| `0x08` | WDT_KICK   | —      | Any write reloads counter              |
| `0x0C` | WDT_STATUS | [0]    | PREWARN — NMI fired (RO)              |
|        |            | [1]    | TRIPPED — hard reset fired (RO)       |

Outputs: `nmi_prewarn` → `core_nmi_int`, `wdt_reset`, `wdt_reset_out`

Heartbeat taps wired to `pipeline_alive[3:0]`:
- `[0]` = `uart_irq`
- `[1]` = `sample_tick`
- `[2]` = `irq_pwm`
- `[3]` = `irq_gpio`

---

## 6. Interrupt Architecture (VeeR EL2 PIC)

| PIC Index | Signal       | Source       | Trigger Condition               |
|-----------|--------------|--------------|---------------------------------|
| `[0]`     | `uart_irq`   | AXI UART     | RX threshold / TX empty         |
| `[1]`     | `irq_timer`  | Timer IP     | TIMER_RELOAD reached            |
| `[2]`     | `irq_gpio`   | GPIO IP      | Input edge change               |
| `[3]`     | `irq_pwm`    | PWM IP       | Period rollover (if IRQ_EN=1)   |
| `[7:4]`   | —            | Reserved     | Tied 0                          |

**NMI path:** `core_nmi_int = nmi_int | wdt_nmi_prewarn`

---

## 7. AXI Protocol Bridge

Every AXI4-Lite peripheral (PWM, SSD, Timer, GPIO, Watchdog) connects through
an `axi4_to_axil_lite` bridge that converts the AXI4 full-featured interface
from the crossbar master port into the simpler AXI4-Lite single-beat interface
required by the IP. IMEM and DMEM connect directly as AXI4 RAM slaves.

---

## 8. Firmware Bring-Up Sequence

```
1. Write MRAC CSR 0x7C0 = 0xAAAAAAA6
   (Region 0x1000_0000 = cacheable memory,
    Region 0x4000_0000 = non-cacheable device I/O)
2. Configure UART baud rate (0x4000_6000)
3. Set GPIO output and IRQ enable (0x4000_A000)
4. Configure PWM period and duty cycles (0x4000_2000)
5. Configure SSD display value (0x4000_4000)
6. Set Timer reload and enable (0x4000_8000)
7. Arm Watchdog with desired timeout (0x4000_E000)
8. Main loop: service WDT kick, read GPIO, update SSD/PWM
```

---

## 9. File Structure

```
lab_codes/
├── rtl/
│   ├── soc_top.sv                  ← SoC top (DUT)
│   ├── pwm/pwm.sv
│   ├── seven_segment/seven_segment.sv
│   ├── timer/timer.sv
│   ├── gpio/gpio.sv
│   ├── watchdog/watchdog.sv
│   ├── axi_uart/...
│   ├── interconnect/...
│   ├── veer_el2/...
│   └── axi_interconnect_uart_top.v
├── lib/
│   ├── axi_ram.sv
│   ├── axi4_to_axil_lite.sv
│   ├── cdc_sync.sv
│   └── sync_fifo.sv
├── tb/
│   └── tb_soc_top.sv               ← Single testbench for all IPs
├── run/
│   ├── filelist_soc.f              ← VCS filelist (no SPI/DMA/FIR/VGA)
│   └── run_vcs_soc.sh              ← Compile + simulate script
└── doc/
    ├── ArchitectureDocument.md     ← This document
    └── TEST_PLAN.md                ← Test plan (all 13 test cases)
```
