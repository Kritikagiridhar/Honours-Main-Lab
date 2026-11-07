# SoC Instance Classification & External Interface Specification for VIP Creation

**Project:** RISC-V Based Peripheral Management SoC (`soc_top.sv`)  
**Core:** Western Digital VeeR EL2 (RV32IMC Dual-Issue Superscalar)  
**Target:** UVM Verification IP (VIP) Development & Interface Characterization  

---

## 1. Executive Summary

To build a modular, standard Universal Verification Methodology (UVM) testbench with Verification IPs (VIPs), the design components instantiated in the SoC must be categorized based on their physical and architectural boundary:

1. **Internal Instances:** Subsystems and IP blocks that reside entirely within the chip boundary. Their ports only connect to on-chip buses (AXI4 / AXI4-Lite) or internal control/interrupt wires. For these blocks, verification is performed either through firmware running on the CPU core, via an **Internal AXI Master VIP** acting as a bus injector, or via internal white-box assertions.
2. **External Instances / Interfaces:** Peripherals and system-level controllers that drive or receive primary I/O boundary pins of the SoC (`soc_top.sv`). For these interfaces, dedicated **External VIPs (UVM Agents)** must be developed (each consisting of Driver, Monitor, Sequencer, Coverage Collector, and Protocol Checker) to stimulate and monitor the chip from the outside world.

All external interfaces have been extracted into individual, machine-readable `.csv` files stored in:
- `external_interfaces_csv/` (root workspace)
- `lab_codes/external_interfaces_csv/`

---

## 2. Complete Instance Classification Matrix

The table below lists every instance present in the top-level design (`soc_top.sv`) and throughout the repository, classifying each as **Internal** or **External**, detailing its role, and specifying its VIP requirements.

| Instance Name | Module Type | Hierarchy / Location | Classification | External Pins on `soc_top`? | Verification IP (VIP) Requirement |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`u_veer_core`** | `veer_wrapper` | `soc_top.u_veer_core` | **Internal Engine** | Yes (Debug/Trace & Control vectors) | **CPU Firmware Stimulus** or optional **Trace Monitor VIP** |
| **`u_adapter_lsu`** | `axi_adapter_64_to_32` | `soc_top.u_adapter_lsu` | **Internal** | None (Bus adapter) | Internal bus monitor / SVA protocol checker |
| **`u_adapter_ifu`** | `axi_adapter_64_to_32` | `soc_top.u_adapter_ifu` | **Internal** | None (Bus adapter) | Internal bus monitor / SVA protocol checker |
| **`u_adapter_sb`** | `axi_adapter_64_to_32` | `soc_top.u_adapter_sb` | **Internal** | None (Bus adapter) | Internal bus monitor / SVA protocol checker |
| **`u_interconnect`** | `axi_interconnect_wrap_5x20` | `u_interconnect_uart.u_interconnect` | **Internal Fabric** | None (Crossbar switch) | **AXI4 Bus Protocol VIP / Scoreboard** |
| **`u_imem`** | `axi_ram` (64 KB) | `soc_top.u_imem` | **Internal** | None (On-chip SRAM) | Preload model / Backdoor memory access |
| **`u_dmem`** | `axi_ram` (64 KB) | `soc_top.u_dmem` | **Internal** | None (On-chip SRAM) | Preload model / Backdoor memory access |
| **`u_bridge_timer`** | `axi4_to_axil_lite` | `soc_top.u_bridge_timer` | **Internal** | None (Protocol bridge) | SVA Bridge Checker |
| **`u_timer`** | `timer` | `soc_top.u_timer` | **Internal Peripheral** | None (Tick & IRQ routed internally) | Verified via AXI register reads & internal IRQ check |
| **`u_bridge_gpio`** | `axi4_to_axil_lite` | `soc_top.u_bridge_gpio` | **Internal** | None (Protocol bridge) | SVA Bridge Checker |
| **`u_gpio`** | `gpio` | `soc_top.u_gpio` | **External Peripheral** | **Yes (`gpio_in`, `gpio_out`)** | **GPIO VIP (UVM Agent)** |
| **`u_bridge_pwm`** | `axi4_to_axil_lite` | `soc_top.u_bridge_pwm` | **Internal** | None (Protocol bridge) | SVA Bridge Checker |
| **`u_pwm`** | `pwm` | `soc_top.u_pwm` | **External Peripheral** | **Yes (`pwm_out[3:0]`)** | **PWM VIP / Timing Monitor** |
| **`u_bridge_ssd`** | `axi4_to_axil_lite` | `soc_top.u_bridge_ssd` | **Internal** | None (Protocol bridge) | SVA Bridge Checker |
| **`u_ssd`** | `seven_segment` | `soc_top.u_ssd` | **External Peripheral** | **Yes (`ssd_seg`, `ssd_digit_sel`)** | **Seven-Segment Display VIP / Monitor** |
| **`u_bridge_wdt`** | `axi4_to_axil_lite` | `soc_top.u_bridge_wdt` | **Internal** | None (Protocol bridge) | SVA Bridge Checker |
| **`u_wdt`** | `watchdog` | `soc_top.u_wdt` | **External Peripheral** | **Yes (`wdt_reset_out`)** | **Watchdog / Reset VIP** |
| **`u_axi_uart`** | `axi_uart_top` | `u_interconnect_uart.u_axi_uart` | **External Peripheral** | **Yes (`uart_rx`, `uart_tx`, `uart_irq`)** | **UART VIP (UVM Agent)** |
| *Standalone IP* | `spi_controller` | `lab_codes/rtl/spi_controller/` | **External (Standalone)** | Not in active top (stubbed M08) | **SPI ADC VIP (UVM Agent)** |
| *Standalone IP* | `vga_controller` | `lab_codes/rtl/vga_controller/` | **External (Standalone)** | Not in active top (stubbed M12) | **VGA Display VIP (UVM Agent)** |

---

## 3. External Interfaces Breakdown & CSV Files

Each external interface has been exported into its own independent `.csv` file with the exact signal name, direction, width, bit range, and operational description.

### 3.1 UART Interface (`uart_interface.csv`)
- **Associated Instance:** `u_axi_uart` (inside `u_interconnect_uart`)
- **Role:** Full-duplex asynchronous serial communication and interrupt telemetry.

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `uart_rx` | Input | 1 | `[0:0]` | UART Serial Receive Line (Stimulus from External Terminal/VIP) |
| `uart_tx` | Output | 1 | `[0:0]` | UART Serial Transmit Line (Monitored by External Terminal/VIP) |
| `uart_irq` | Output | 1 | `[0:0]` | UART Interrupt Request Line (External Telemetry / PIC Monitor) |

### 3.2 GPIO Interface (`gpio_interface.csv`)
- **Associated Instance:** `u_gpio`
- **Role:** 8-bit bidirectional general-purpose parallel input/output.

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `gpio_in` | Input | 8 | `[7:0]` | General Purpose Parallel Input Pins (External Switches/Sensors Stimulus) |
| `gpio_out` | Output | 8 | `[7:0]` | General Purpose Parallel Output Pins (External LEDs/Actuators Monitor) |

### 3.3 PWM Interface (`pwm_interface.csv`)
- **Associated Instance:** `u_pwm`
- **Role:** 4-channel independent pulse width modulation output for motor/LED control.

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `pwm_out` | Output | 4 | `[3:0]` | 4-Channel Pulse Width Modulated Outputs (Channels 0..3) |

### 3.4 Seven-Segment Display Interface (`seven_segment_interface.csv`)
- **Associated Instance:** `u_ssd`
- **Role:** 4-digit multiplexed seven-segment display controller (cathodes and digit anodes).

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `ssd_seg` | Output | 8 | `[7:0]` | 7-Segment Cathodes + Decimal Point [a b c d e f g dp] (Active-Low) |
| `ssd_digit_sel` | Output | 4 | `[3:0]` | 4-Digit Common Anode Select Lines (Active-Low One-Hot) |

### 3.5 Watchdog Interface (`watchdog_interface.csv`)
- **Associated Instance:** `u_wdt`
- **Role:** Hardware safety monitor asserting hard reset upon heartbeat failure.

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `wdt_reset_out` | Output | 1 | `[0:0]` | Watchdog Hardware Reset Out Indicator (Fires on System Watchdog Trip) |

### 3.6 Clock and Reset Interface (`clock_and_reset_interface.csv`)
- **Associated Instance:** SoC Top-Level System Infrastructure
- **Role:** Master reference clock and global asynchronous active-low reset.

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `clk` | Input | 1 | `[0:0]` | Primary System Clock (100 MHz) |
| `rst_n` | Input | 1 | `[0:0]` | Asynchronous Active-Low Master System Reset |

### 3.7 Core Control Interface (`core_control_interface.csv`)
- **Associated Instance:** `u_veer_core`
- **Role:** Boot vector configuration, NMI exception injection, and JTAG ID binding.

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `rst_vec` | Input | 31 | `[31:1]` | CPU Reset Vector Address Base |
| `nmi_int` | Input | 1 | `[0:0]` | External Non-Maskable Interrupt Request (Active-High) |
| `nmi_vec` | Input | 31 | `[31:1]` | CPU Non-Maskable Interrupt Vector Base Address |
| `jtag_id` | Input | 31 | `[31:1]` | Core JTAG Identification Code |

### 3.8 External Interrupt Interface (`external_interrupt_interface.csv`)
- **Associated Instance:** `u_veer_core` (Programmable Interrupt Controller)
- **Role:** Off-chip interrupt line expansion directly feeding the core PIC.

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `ext_irq` | Input | 24 | `[23:0]` | External Interrupt Expansion Sources for Core PIC (Indices 8..31) |
| `timer_int` | Input | 1 | `[0:0]` | External Timer Interrupt Input to RISC-V Core |

### 3.9 CPU Trace & Debug Interface (`cpu_trace_debug_interface.csv`)
- **Associated Instance:** `u_veer_core`
- **Role:** Real-time instruction retirement trace, trap reporting, and execution status.

| Signal Name | Direction | Width | Bit Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `trace_rv_i_insn_ip` | Output | 32 | `[31:0]` | Retired Instruction Machine Code (32-bit RISC-V Instruction) |
| `trace_rv_i_address_ip` | Output | 32 | `[31:0]` | Program Counter (PC) Address of Retired Instruction |
| `trace_rv_i_valid_ip` | Output | 1 | `[0:0]` | Instruction Trace Valid Strobe (Asserted when Instruction Retires) |
| `trace_rv_i_exception_ip` | Output | 1 | `[0:0]` | Exception Flag for Current Instruction Retirement |
| `trace_rv_i_ecause_ip` | Output | 5 | `[4:0]` | Exception / Trap Cause Code |
| `trace_rv_i_interrupt_ip` | Output | 1 | `[0:0]` | Interrupt Trap Indicator |
| `trace_rv_i_tval_ip` | Output | 32 | `[31:0]` | Trap Value Register (MTVAL Content) |
| `o_cpu_halt_status` | Output | 1 | `[0:0]` | CPU Halted Execution Status |
| `o_cpu_halt_ack` | Output | 1 | `[0:0]` | CPU Halt Request Acknowledged |
| `o_debug_mode_status` | Output | 1 | `[0:0]` | CPU Debug Mode Status Indicator |

### 3.10 Standalone Reference IP Interfaces
In the event your test plan or lab curriculum requires standalone VIP verification for the reference IPs:
- **SPI Interface (`spi_interface.csv`):** `adc_spi_sck` (Out, 1b), `adc_spi_mosi` (Out, 1b), `adc_spi_miso` (In, 1b), `adc_spi_cs_n` (Out, 1b).
- **VGA Interface (`vga_interface.csv`):** `vga_hsync` (Out, 1b), `vga_vsync` (Out, 1b), `vga_red` (Out, 4b), `vga_green` (Out, 4b), `vga_blue` (Out, 4b).

---

## 4. Master Interface CSV File

A unified master file compiling all signals across all external interfaces is provided at:
`external_interfaces_csv/all_external_interfaces_master.csv`
