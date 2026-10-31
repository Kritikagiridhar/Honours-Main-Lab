# Test Plan
## Peripheral Management SoC — RISC-V VeeR EL2

**Project :** Peripheral Management SoC  
**IPs Under Test :** PWM · Seven-Segment Display (SSD) · UART · Timer · GPIO · Watchdog  
**Processor :** Western Digital VeeR EL2 (RV32IMC)  
**Interconnect :** AXI4 Crossbar + AXI4-Lite bridges  
**Simulator :** Synopsys VCS U-2023.03 / Verdi U-2023.03-SP1  
**Language :** SystemVerilog (IEEE 1800-2017)  
**Top-level DUT :** `soc_top` (all IPs + processor in one module)  
**Top-level Testbench :** `tb/tb_soc_top.sv`  
**Filelist :** `run/filelist_soc.f`  
**Run command :** `cd run && ./run_vcs_soc.sh`  

Reference documents:
- `doc/ArchitectureDocument.md`
- `doc/SOC_ARCHITECTURE_AND_TEST_PLAN.md`
- `doc/SOC_INTEGRATION_REPORT.md`

---

## 1. Scope

This test plan covers **functional simulation-based verification** of the
Peripheral Management SoC. All peripherals and the RISC-V core are tested
together through the integrated top-level module `soc_top`. There is one
testbench (`tb_soc_top.sv`) and one filelist (`filelist_soc.f`).

Out of scope: SPI, DMA, FIR, VGA — these IPs are **not** part of this project
and have been removed from `soc_top`.

---

## 2. Test Environment

```
run/filelist_soc.f
    |-- VeeR EL2 RTL (rtl/veer_el2/design/...)
    |-- lib/axi_ram.sv          (IMEM / DMEM)
    |-- lib/axi4_to_axil_lite.sv
    |-- lib/cdc_sync.sv
    |-- lib/sync_fifo.sv
    |-- rtl/axi_uart/...        (UART)
    |-- rtl/pwm/pwm.sv
    |-- rtl/seven_segment/seven_segment.sv
    |-- rtl/timer/timer.sv
    |-- rtl/gpio/gpio.sv
    |-- rtl/watchdog/watchdog.sv
    |-- rtl/interconnect/...    (AXI crossbar)
    |-- rtl/axi_interconnect_uart_top.v
    |-- rtl/interconnect/axi_adapter_64_to_32.sv
    |-- rtl/soc_top.sv          (DUT top)
    |-- tb/tb_soc_top.sv        (Testbench)
```

The testbench drives each peripheral's internal AXI-Lite register wires
directly via SystemVerilog `force`/`release` (hierarchical path access)
so that IP registers can be tested without needing firmware running on the
RISC-V core. Output pins (`pwm_out`, `ssd_digit_sel`, `gpio_out`,
`wdt_reset_out`, `uart_tx`) are monitored for correctness.

---

## 3. Memory Map Under Test

| Address        | Peripheral       | Tested? |
|----------------|------------------|---------|
| `0x1000_0000`  | IMEM (64 KB)     | Yes     |
| `0x1002_0000`  | DMEM (64 KB)     | Yes     |
| `0x4000_2000`  | PWM Controller   | Yes     |
| `0x4000_4000`  | SSD Controller   | Yes     |
| `0x4000_6000`  | AXI UART         | Yes     |
| `0x4000_8000`  | System Timer     | Yes     |
| `0x4000_A000`  | GPIO Controller  | Yes     |
| `0x4000_E000`  | Watchdog Monitor | Yes     |
| `0x4000_C000`  | SPI stub (DECERR)| Yes (stub check) |

---

## 4. Test Cases

---

### TC-01 — Reset Release & Clock Sanity

| Field       | Value |
|-------------|-------|
| **ID**      | TC-01 |
| **IP**      | SoC-level |
| **Category**| Reset |
| **Priority**| P0 (must-pass) |

**Objective:** Verify the SoC exits reset cleanly with no X-propagation on primary outputs.

**Stimulus:**
1. Assert `rst_n = 0` for 20 clock cycles.
2. De-assert `rst_n = 1`.
3. Wait 10 clock cycles.

**Pass Criteria:**
- `rst_n` de-asserted without glitch.
- `pwm_out`, `ssd_seg`, `ssd_digit_sel`, `gpio_out`, `wdt_reset_out` all non-X.
- `uart_tx` idles at logic 1 (UART idle state).

---

### TC-02 — PWM: Register Write, Duty Cycle, Output Toggle

| Field       | Value |
|-------------|-------|
| **ID**      | TC-02 |
| **IP**      | PWM (`0x4000_2000`) |
| **Category**| Register access + functional |
| **Priority**| P0 |

**Objective:** Configure PWM channel-0, verify register readback and output activity.

**Stimulus:**
1. Write `PWM_PERIOD = 999` (offset `0x04`).
2. Write `PWM_DUTY0 = 499` (offset `0x08`) → 50% duty.
3. Write `PWM_CTRL = 0x1` (offset `0x00`) → enable CH0.
4. Wait 2 100 clock cycles (> 2 full periods).

**Pass Criteria:**
- `PWM_CTRL` readback: `rdata[0] == 1`.
- `pwm_out[0]` is not X and has toggled at least once.
- No AXI protocol error (BRESP == `2'b00`).

**Register Reference:** `ArchitectureDocument.md` §5.1

---

### TC-03 — SSD: Register Write, Display Enable, Digit Select

| Field       | Value |
|-------------|-------|
| **ID**      | TC-03 |
| **IP**      | SSD (`0x4000_4000`) |
| **Category**| Register access + functional |
| **Priority**| P0 |

**Objective:** Write a display value, enable the SSD, and verify the multiplexing output.

**Stimulus:**
1. Write `SSD_DATA = 0x1234` (offset `0x04`).
2. Write `SSD_CTRL = 0x1` (offset `0x00`) → enable.
3. Wait 200 clock cycles for at least one multiplex refresh cycle.

**Pass Criteria:**
- `SSD_CTRL` readback: `rdata[0] == 1`.
- `ssd_digit_sel` is not all-ones (`4'hF`) — at least one digit is being driven.
- `ssd_seg` is not X.

**Register Reference:** `ArchitectureDocument.md` §5.2

---

### TC-04 — Timer: Reload, Enable, sample_tick Pulse

| Field       | Value |
|-------------|-------|
| **ID**      | TC-04 |
| **IP**      | Timer (`0x4000_8000`) |
| **Category**| Register access + functional |
| **Priority**| P0 |

**Objective:** Set a short reload value, enable the timer, and observe `sample_tick` within the expected cycle count.

**Stimulus:**
1. Write `TIMER_RELOAD = 100` (offset `0x04`).
2. Write `TIMER_CTRL = 0x1` (offset `0x00`) → enable.
3. Poll for `sample_tick == 1` with a 2 000-cycle timeout.

**Pass Criteria:**
- `sample_tick` observed high within 200 cycles after enable.
- `TIMER_STATUS` readback (offset `0x0C`): `rdata[0] == 1` (TICK flag set).
- `irq_timer` wire goes high.

**Register Reference:** `ArchitectureDocument.md` §5.3

---

### TC-05 — GPIO: Input Sampling and Output Drive

| Field       | Value |
|-------------|-------|
| **ID**      | TC-05 |
| **IP**      | GPIO (`0x4000_A000`) |
| **Category**| Register access + functional |
| **Priority**| P0 |

**Objective:** Verify GPIO input synchronization and output drive.

**Stimulus — Input:**
1. Drive `gpio_in = 8'hA5`.
2. Wait 5 clock cycles (allow 2-stage synchronizer).
3. Read `GPIO_IN` register (offset `0x00`).

**Stimulus — Output:**
1. Write `GPIO_OUT = 0x5A` (offset `0x04`).
2. Wait 3 clock cycles.
3. Sample `gpio_out` pin.

**Pass Criteria:**
- `GPIO_IN` register reads `8'hA5`.
- `gpio_out == 8'h5A`.

**Register Reference:** `ArchitectureDocument.md` §5.4

---

### TC-06 — Watchdog: Enable, Kick, No Spurious Reset

| Field       | Value |
|-------------|-------|
| **ID**      | TC-06 |
| **IP**      | Watchdog (`0x4000_E000`) |
| **Category**| Register access + safety |
| **Priority**| P0 |

**Objective:** Arm the watchdog with a long timeout, service it with a kick, and confirm no NMI/reset is generated.

**Stimulus:**
1. Write `WDT_RELOAD = 0xFFFF` (offset `0x04`).
2. Write `WDT_CTRL = 0x1` (offset `0x00`) → enable.
3. Wait 10 clock cycles.
4. Write any value to `WDT_KICK` (offset `0x08`) → reload counter.
5. Wait 20 clock cycles.

**Pass Criteria:**
- `WDT_STATUS` (offset `0x0C`): `rdata[0] == 0` (PREWARN not set).
- `wdt_reset_out == 0`.
- `wdt_nmi_prewarn` internal signal == 0.

**Register Reference:** `ArchitectureDocument.md` §5.5

---

### TC-07 — Watchdog: Timeout → NMI Pre-Warning

| Field       | Value |
|-------------|-------|
| **ID**      | TC-07 |
| **IP**      | Watchdog (`0x4000_E000`) |
| **Category**| Safety / fault injection |
| **Priority**| P0 |

**Objective:** Deliberately starve the watchdog (no kick) and verify NMI pre-warning fires.

**Stimulus:**
1. Disable WDT (`WDT_CTRL = 0`).
2. Write `WDT_RELOAD = 20` (short timeout).
3. Enable WDT (`WDT_CTRL = 1`). Do NOT kick.
4. Poll `wdt_nmi_prewarn` for up to 200 cycles.

**Pass Criteria:**
- `wdt_nmi_prewarn` asserts within 30 cycles after enable.
- After detection, disable WDT to prevent hard reset affecting remaining tests.

---

### TC-08 — UART: TX Idle High

| Field       | Value |
|-------------|-------|
| **ID**      | TC-08 |
| **IP**      | UART (`0x4000_6000`) |
| **Category**| Basic sanity |
| **Priority**| P1 |

**Objective:** Verify UART TX line idles at logic 1 after reset (RS-232 idle state).

**Stimulus:** No additional stimulus; check at end of TC-01.

**Pass Criteria:**
- `uart_tx == 1'b1` while no TX operation is in progress.

---

### TC-09 — SoC Integration: No X on Outputs After Reset

| Field       | Value |
|-------------|-------|
| **ID**      | TC-09 |
| **IP**      | SoC-level |
| **Category**| Integration / X-propagation |
| **Priority**| P0 |

**Objective:** Confirm that all top-level DUT output ports are driven to known logic values after reset de-assertion (no uninitialized/X values reaching outputs).

**Stimulus:** Run after TC-01 reset sequence.

**Pass Criteria:**
- `^pwm_out !== 1'bx`
- `^ssd_seg !== 1'bx`
- `^ssd_digit_sel !== 1'bx`
- `^gpio_out !== 1'bx`
- `wdt_reset_out !== 1'bx`
- `uart_tx !== 1'bx`

---

### TC-10 — Removed IP Slot: SPI DECERR Stub

| Field       | Value |
|-------------|-------|
| **ID**      | TC-10 |
| **IP**      | SoC-level / Interconnect |
| **Category**| Negative / architectural |
| **Priority**| P1 |

**Objective:** Confirm that the SPI address slot (`0x4000_C000`) — removed from this project — is properly stubbed in `soc_top` with a DECERR responder so no bus hang occurs.

**Verification method:** Code review of `soc_top.sv` confirms M08 interconnect port is tied with `awready=0`, `arready=0`, `bresp=2'b11`, `rresp=2'b11`. Simulation confirms compile passes without SPI RTL in filelist.

**Pass Criteria:**
- `soc_top.sv` M08 stub lines verified by grep (no `spi_controller` instance).
- VCS compile succeeds without `spi_controller.sv` in `filelist_soc.f`.

---

## 5. Interrupt Integration Tests

### TC-11 — Timer IRQ Routing to VeeR EL2 PIC

| Field       | Value |
|-------------|-------|
| **ID**      | TC-11 |
| **IP**      | Timer + VeeR EL2 PIC |
| **Priority**| P1 |

**Objective:** Verify `irq_timer` is connected to PIC index `[1]` and the core sees the interrupt.

**Pass Criteria:**
- `irq_timer` observed on `core_extintsrc_req[1]` (hierarchical check).
- `trace_rv_i_interrupt_ip` goes high if core is executing firmware.

---

### TC-12 — GPIO IRQ on Input Change

| Field       | Value |
|-------------|-------|
| **ID**      | TC-12 |
| **IP**      | GPIO + PIC |
| **Priority**| P1 |

**Stimulus:**
1. Write `GPIO_IRQ_EN = 0xFF` (offset `0x08`).
2. Toggle `gpio_in` from `8'h00` to `8'h01`.

**Pass Criteria:**
- `irq_gpio` asserts.
- `GPIO_STATUS[0]` (CHANGED) is set.

---

### TC-13 — Watchdog NMI Routes to Core

| Field       | Value |
|-------------|-------|
| **ID**      | TC-13 |
| **IP**      | Watchdog + VeeR EL2 |
| **Priority**| P1 |

**Objective:** Confirm `wdt_nmi_prewarn` is ORed into `core_nmi_int` inside `soc_top`.

**Pass Criteria:**
- Hierarchical check: `tb_soc_top.u_dut.core_nmi_int == wdt_nmi_prewarn | nmi_int`.

---

## 6. Regression Suite

| Test ID | Description                          | Priority | Expected Result |
|---------|--------------------------------------|----------|-----------------|
| TC-01   | Reset release & clock sanity         | P0       | PASS            |
| TC-02   | PWM register write + output toggle   | P0       | PASS            |
| TC-03   | SSD register write + digit select    | P0       | PASS            |
| TC-04   | Timer reload + sample_tick           | P0       | PASS            |
| TC-05   | GPIO input read + output drive       | P0       | PASS            |
| TC-06   | Watchdog kick — no spurious reset    | P0       | PASS            |
| TC-07   | Watchdog timeout → NMI prewarn       | P0       | PASS            |
| TC-08   | UART TX idle high                    | P1       | PASS            |
| TC-09   | SoC output X-check                   | P0       | PASS            |
| TC-10   | SPI stub DECERR verification         | P1       | PASS            |
| TC-11   | Timer IRQ routing to PIC             | P1       | PASS            |
| TC-12   | GPIO IRQ on input change             | P1       | PASS            |
| TC-13   | Watchdog NMI routing to core         | P1       | PASS            |

---

## 7. How to Run

```bash
cd /home/student/Documents/honours/lab_codes/run
./run_vcs_soc.sh           # compile + simulate
./run_vcs_soc.sh verdi     # compile + simulate + open Verdi waveform viewer
```

Logs produced:
- `run/compile_soc.log` — VCS elaboration/compile output
- `run/sim_soc.log`     — simulation output with PASS/FAIL per test case
- `run/dump.fsdb`       — waveform database for Verdi

Pass criterion for the full regression: **0 FAILED** lines in `sim_soc.log`.

---

## 8. Coverage Goals

| Coverage Type     | Target | Notes                                   |
|-------------------|--------|-----------------------------------------|
| Line coverage     | 90 %   | All IP RTL files in `filelist_soc.f`    |
| Toggle coverage   | 80 %   | All peripheral output ports             |
| Branch coverage   | 85 %   | Register decode, IRQ logic, WDT states  |
| Functional        | 100 %  | All TC-01 through TC-13 must pass       |

---

## 9. Known Limitations

1. RISC-V firmware is not loaded in the testbench; peripheral registers are driven directly via `force`/`release` on internal AXI-Lite wires using hierarchical path references.
2. UART TX byte transmission (full frame) is tested in `tb/tb_axi_interconnect_uart_top.sv` (existing standalone testbench).
3. PWM frequency accuracy (timing precision) is verified by counting `pwm_out` toggle cycles — not by analog measurement.
4. Watchdog hard reset (`wdt_reset` → `rst_n`) feedback loop is not closed in the testbench to keep simulation deterministic; `wdt_reset_out` is monitored as a proxy.
