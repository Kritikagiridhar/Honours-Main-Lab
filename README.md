# RISC-V VeeR EL2 Based SoC for PWM-Controlled Peripheral Management

A complete RISC-V System-on-Chip (SoC) integrating the open-source Western Digital **VeeR EL2** RISC-V processor core (RV32IMC) with an AXI crossbar interconnect and dedicated peripheral hardware: a 4-channel **PWM Generator**, an autonomous **Watchdog Timer**, a 4-digit **Seven-Segment Display Controller**, plus standard peripherals (**UART**, **Timer**, **GPIO**, **SPI**).

Verified end-to-end in **Synopsys VCS** and **Verdi** (26/26 self-checking assertions pass).

---

## Project Abstract

### 1. Problem Statement
Embedded systems that drive analog-equivalent loads such as motors, LEDs, heaters, and actuators require a precise,
programmable, and continuously running control signal that a general-purpose processor cannot generate efficiently
on its own through direct pin toggling. At the same time, such systems must remain reliable and observable: they
need a mechanism to detect and recover from software or logic faults, and a simple way to display live system status
without depending on an external computer connection. Implementing pulse-width control, fault recovery, and status
display as separate, loosely-integrated modules increases system complexity and makes verification difficult.
Therefore, there is a need for a compact, programmable System-on-Chip (SoC) that combines a processor core with
dedicated, memory-mapped hardware for duty-cycle-controlled signal generation, autonomous fault detection, and
local visual feedback, all coordinated through a single, well-defined architecture.

This project proposes the design and verification of a RISC-V VeeR EL2 based SoC centered on a PWM (Pulse
Width Modulation) Generator for programmable duty-cycle signal control. The SoC integrates the VeeR EL2
processor with core-local instruction and data memories, standard peripherals, and three additional IPs: a PWM
Generator for hardware-accurate duty-cycle waveform generation, a Watchdog Timer for autonomous system-fault
detection and recovery, and a Seven Segment Display Controller for direct, human-readable status feedback. The
processor manages these peripherals through a shared bus interconnect and executes an application that configures
the PWM duty cycle, periodically services the watchdog, and displays the current operating status on the seven-segment display.

### 2. Proposed SoC Architecture
The SoC is organized around the VeeR EL2 RISC-V processor as the central control unit, connected to instruction
memory (ICCM), data memory (DCCM), and peripheral IP blocks through a shared bus interconnect. The processor
is responsible for configuring each peripheral through memory-mapped control and status registers, sequencing the
overall flow of operations, and responding to peripheral status without needing to generate any timing-critical
waveform directly in software. All additional IPs are implemented as simple memory-mapped slave peripherals on
the same interconnect as the required UART, Timer, and GPIO blocks, so no additional bus-mastering logic or
arbitration is required. The system follows this operational flow:

* **Duty-Cycle Control** — The processor writes a target duty-cycle value and period into the PWM Generator's control registers. The PWM hardware then free-runs independently, continuously generating the output waveform without further CPU intervention until the processor updates the registers again.
* **Fault Monitoring** — The Watchdog Timer runs a hardware down-counter that the processor must periodically reload ("kick") through a status-register write. If the processor fails to do so within the configured timeout, due to a software hang or logic fault, the Watchdog Timer autonomously asserts a system reset, allowing the SoC to recover without external intervention.
* **Status Display** — The processor writes the current PWM duty-cycle value or system status code to the Seven Segment Display Controller, which decodes the value and drives the display digits directly, giving a simple local visual readout without requiring a host computer connection.
* **Monitoring and Support** — UART provides communication between the SoC and a host computer for observing register values, watchdog events, and system status during debug, while the required GPIO and Timer support general-purpose control and independent system timing functions.

---

## Architecture Overview

```
                    +---------------------------------------------------+
                    |                     soc_top                       |
                    |                                                   |
  +----------+      |  +-----------+   AXI 64-to-32   +----------------+  |
  |  VeeR    |  AXI4 |  | Width Adp |  (LSU/IFU/SB)  |  5x20 AXI     |  |
  |  EL2     |------>|  +-----------+---------------->|  Crossbar     |  |
  | RV32IMC  | 64-bit|                               |  Interconnect |  |
  |  Core    |      |  +------------+                +-------+-------+  |
  +----------+      |  |  axi_ram   |  IMEM/DMEM   |    |   |   |   |  |
                    |  +------------+               v    v   v   v   v  |
                    |                          +----+--+--+---+---+--+ |
                    |  Peripherals (AXI4-Lite):  |PWM|SSD|TMR|GPIO|WDT| |
                    |  + SPI + UART              +---+---+---+---+---+  |
                    +---------------------------------------------------+
```

### Memory Map & SoC Components

| # | Component | Base Address | Bus | Description |
|---|-----------|-------------|-----|-------------|
| M00 | AXI UART | `0x4000_6000` | AXI4 | Serial debug (115200 baud) |
| M01 | IMEM | `0x1000_0000` | AXI4 | 64 KB instruction memory |
| M02 | DMEM | `0x1002_0000` | AXI4 | 64 KB data memory |
| M03 | (reserved) | `0x4000_0000` | — | Stubbed (DECERR) |
| **M04** | **PWM Controller** | **`0x4000_2000`** | **AXI4-Lite** | **4-channel PWM — Project IP** |
| **M05** | **Seven-Segment Display** | **`0x4000_4000`** | **AXI4-Lite** | **4-digit mux'd SSD — Project IP** |
| M06 | Timer | `0x4000_8000` | AXI4-Lite | Acquisition timer w/ sample_tick |
| M07 | GPIO | `0x4000_A000` | AXI4-Lite | 8-bit I/O with edge IRQ |
| M08 | SPI Master | `0x4000_C000` | AXI4-Lite | Auxiliary SPI peripheral |
| **M09** | **Watchdog Timer** | **`0x4000_E000`** | **AXI4-Lite** | **Safety monitor w/ NMI & reset trip — Project IP** |

---

## Project IPs (Custom Hardware Details)

### 1. PWM Controller (`rtl/pwm/pwm.sv`)
4-channel pulse-width modulation generator with shared period register.

| Offset | Register | Description |
|--------|----------|-------------|
| `0x00` | `PWM_CTRL` | [3:0] per-channel enable |
| `0x04` | `PWM_PERIOD` | [15:0] common period (clk cycles) |
| `0x08` | `PWM_DUTY0` | [15:0] channel-0 duty |
| `0x0C` | `PWM_DUTY1` | [15:0] channel-1 duty |
| `0x10` | `PWM_DUTY2` | [15:0] channel-2 duty |
| `0x14` | `PWM_DUTY3` | [15:0] channel-3 duty |
| `0x18` | `PWM_STATUS` | [3:0] running (RO) |
| `0x1C` | `PWM_IRQ_CTRL` | [0] period-rollover IRQ enable |

Outputs: `pwm_out[3:0]`

### 2. Seven-Segment Display Controller (`rtl/seven_segment/seven_segment.sv`)
4-digit multiplexed 7-segment display with built-in hex decoder.

| Offset | Register | Description |
|--------|----------|-------------|
| `0x00` | `SSD_CTRL` | [0] EN, [1] MODE (0=hex, 1=raw) |
| `0x04` | `SSD_DATA` | [15:0] display value (nibble per digit) |
| `0x08` | `SSD_BRIGHT` | [7:0] refresh prescaler |
| `0x0C` | `SSD_STATUS` | [0] running (RO) |

Outputs: `ssd_seg[7:0]` (active-low cathodes), `ssd_digit_sel[3:0]` (active-low anodes)

### 3. Watchdog Timer (`rtl/watchdog/watchdog.sv`)
Safety monitor and fault recovery timer with two-stage timeout (NMI warning and hard system reset).

| Offset | Register | Description |
|--------|----------|-------------|
| `0x00` | `WDT_CTRL` | [0] ENABLE, [1] NMI_EN |
| `0x04` | `WDT_RELOAD` | [31:0] reload duration in clock cycles |
| `0x08` | `WDT_COUNT` | [31:0] instantaneous countdown value (RO) |
| `0x0C` | `WDT_KICK` | Write `0x55AA_1234` to service/kick counter |
| `0x10` | `WDT_STATUS` | [0] TRIPPED sticky flag (W1C) |

Outputs: `wdt_nmi`, `wdt_reset`

---

## How to Run (VCS + Verdi)

### Prerequisites
Set up the Synopsys tool environment:
```bash
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
```

### Quick Start
```bash
# Compile and simulate the full SoC
make soc

# Open waveforms in Verdi
make soc-verdi
```

### Manual (without Make)
```bash
cd run
./run_vcs_soc.sh           # compile + simulate
./run_vcs_soc.sh verdi     # compile + simulate + open Verdi
```

---

## File Structure

```
├── doc/                               # Documentation, architecture specs, and abstract
├── lib/                               # AXI RAM, CDC synchronizer, FIFO, AXI bridges
├── rtl/
│   ├── pwm/pwm.sv                     # 4-channel PWM controller (AXI4-Lite)
│   ├── seven_segment/seven_segment.sv # 4-digit SSD controller (AXI4-Lite)
│   ├── watchdog/watchdog.sv           # Watchdog Timer safety monitor (AXI4-Lite)
│   ├── timer/timer.sv                 # Hardware Timer IP
│   ├── gpio/gpio.sv                   # 8-bit GPIO Controller
│   ├── spi_controller/                # SPI Master Controller
│   ├── axi_uart/                      # AXI UART 16550 IP
│   ├── interconnect/                  # 5x20 AXI4 Crossbar Interconnect & adapters
│   ├── veer_el2/                      # Western Digital VeeR EL2 RISC-V Core (RV32IMC)
│   └── soc_top.sv                     # Top-level SoC integration
├── run/                               # Simulation scripts, filelists, and waveform configs
├── scripts/                           # Helper scripts
├── sw/                                # Bare-metal C test firmware
├── tb/                                # Testbenches and RISC-V hex images
│   ├── tb_soc_top.sv                  # Full SoC self-checking testbench
│   └── adc_model.sv                   # Behavioral peripheral model
├── Makefile                           # Unified build and simulation targets
└── README.md                          # Project documentation
```

---

## Test Results

All 26 self-checking assertions pass in VCS simulation:

```
Total Assertions Checked : 26
Total Passed             : 26
Total Failed             : 0
Total Instructions Retired: 3671
>>> ALL RISC-V SoC TESTS PASSED! <<<
```

Tests covered:
- Power-on reset & initialization
- VeeR EL2 instruction fetch/retire from on-chip IMEM
- UART serial transmission (Tx 'A')
- GPIO software control (0xA5)
- **PWM** — 4 channels configured, outputs toggling
- **Seven-Segment Display** — data, multiplexing, segment drive
- **Watchdog Timer** — safety monitor w/ NMI & reset trip, timeout countdown & kick reload
- DMEM read/write
- UART RX interrupt
- SPI peripheral communication
- PIC interrupt routing
