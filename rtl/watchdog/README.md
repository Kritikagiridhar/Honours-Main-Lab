# System Watchdog Timer IP Core (`watchdog.sv`)

## 1. Overview & Architecture Reference
- **Module Name**: `watchdog`
- **Source File**: [`rtl/watchdog/watchdog.sv`](watchdog.sv)
- **Testbench**: [`tb/tb_watchdog.sv`](../../tb/tb_watchdog.sv)
- **Specification Reference**: `doc/ArchitectureDocument.md` (Section 8.10)
- **System Memory Base**: `0x8000_6000` (Slave Port 12 on AXI Interconnect)

The **Watchdog Timer** ensures system stability and fault recovery across the SoC acquisition pipeline. If software deadlocks, an interrupt hangs, or DMA locks up due to missing hardware triggers, the watchdog counts down to zero, generates an early Non-Maskable Interrupt (NMI) warning to save crash diagnostics, and finally asserts a hard system reset.

```
                      +---------------------------------------------------+
                      |                 Watchdog IP Core                  |
                      |                                                   |
    s_axi_* --------->| [AXI4-Lite CSR Engine]                            |
                      |   - 0x00: WDT_CTRL (EN, NMI_EN)                   |
                      |   - 0x04: WDT_RELOAD                              |
                      |   - 0x08: WDT_COUNT                               |
                      |   - 0x0C: WDT_KICK (Magic Key 0x55AA_1234)        |
                      |   - 0x10: WDT_STATUS (TRIPPED)                    |
                      |                                                   |
                      | [32-bit Down Counter & Underflow Logic]           |
                      +-------------------------+-------------------------+
                                                |
                                                +---> wdt_nmi   (Count == 1)
                                                +---> wdt_reset (Count == 0)
```

---

## 2. Port Interface

| Port Signal | Direction | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | `clk_sys` | System Clock (100 MHz) |
| `rst_n` | Input | 1 | `clk_sys` | Active-Low Asynchronous Reset |
| `wdt_reset` | Output | 1 | `clk_sys` | Active-High System Hard Reset strobe |
| `wdt_nmi` | Output | 1 | `clk_sys` | Pre-warning Non-Maskable Interrupt pulse |
| `s_axi_*` | Mixed | - | `clk_sys` | Standard AXI4-Lite 32-bit slave interface |

---

## 3. Register Memory Map (`0x8000_6000`)

| Offset | Name | Type | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x00` | `WDT_CTRL` | R/W | `0x0000_0000` | Control Register<br>• Bit 0: `ENABLE` (1 = Enable countdown)<br>• Bit 1: `NMI_EN` (1 = Enable NMI pre-warning) |
| `0x04` | `WDT_RELOAD` | R/W | `0x000F_4240` | Reload duration in clock cycles (Default: 1,000,000 = 10 ms) |
| `0x08` | `WDT_COUNT` | RO | `0x000F_4240` | Instantaneous 32-bit countdown value |
| `0x0C` | `WDT_KICK` | WO | `0x0000_0000` | Key Register: Write `0x55AA_1234` to reload counter |
| `0x10` | `WDT_STATUS` | R/W1C | `0x0000_0000` | Status Register<br>• Bit 0: `TRIPPED` (Sticky flag set on reset trip, W1C) |

---

## 4. Theory of Operation
1. **Safety Key Reload**: To prevent accidental writes or runaway pointers from refreshing the watchdog, only writes with the exact key code `0x55AA_1234` to `WDT_KICK` will reload `WDT_COUNT` with `WDT_RELOAD`.
2. **Two-Stage Timeout Protection**:
   - **Stage 1 (NMI Warning)**: When the counter reaches `count == 1` and `NMI_EN == 1`, `wdt_nmi` is pulsed high for 1 cycle. The RISC-V CPU can execute a critical exception handler to dump registers, log fault traces to UART, or initiate emergency shutdown.
   - **Stage 2 (Hard Reset)**: When the counter reaches `count == 0`, `wdt_reset` is pulsed high for 1 cycle, and `WDT_STATUS[0]` is latched. The reset line resets the SoC pipeline.
3. **Post-Mortem Analysis**: The `TRIPPED` flag survives subsequent warm boots, enabling firmware to inspect whether the reset was caused by a power-on reset or a watchdog hardware trip.

---

## 5. Verification & Simulation
The unit testbench [`tb/tb_watchdog.sv`](../../tb/tb_watchdog.sv) verifies:
- Programming `WDT_RELOAD` and arming the counter.
- Periodic watchdog kicks using the security key `0x55AA_1234` proving no underflow occurs during normal operation.
- NMI assertion exactly 1 cycle prior to underflow.
- Reset pulse generation (`wdt_reset`) on underflow.
- Sticky persistence of the `WDT_STATUS.TRIPPED` flag.

### Running with Synopsys VCS
```bash
# Compile and run unit test
make watchdog

# Debug waveforms in Synopsys Verdi
make verdi TEST=watchdog
```

---

## 6. Design Provenance & Attribution
- **Origin**: Custom Developed IP Core for this Honours Project.
- **Specification Source**: Built to conform strictly with `doc/ArchitectureDocument.md` Section 8.10.
- **Verification Status**: Fully verified in Synopsys VCS with clean pass on `make watchdog`.
