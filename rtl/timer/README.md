# Acquisition Rate Timer IP Core (`timer.sv`)

## 1. Overview & Architecture Reference
- **Module Name**: `timer`
- **Source File**: [`rtl/timer/timer.sv`](timer.sv)
- **Testbench**: [`tb/tb_timer.sv`](../../tb/tb_timer.sv)
- **Specification Reference**: `doc/ArchitectureDocument.md` (Section 8.5)
- **System Memory Base**: `0x8000_1000` (Slave Port 7 on AXI Interconnect)

The **Acquisition Rate Timer** core provides high-resolution, programmable pacing for analog-to-digital signal sampling across the SoC. It generates single-cycle acquisition strobes (`sample_tick`) that trigger the autonomous DMA Controller to fetch sample words over SPI from the ADC frontend.

```
                      +---------------------------------------+
                      |         Acquisition Timer             |
                      |                                       |
    s_axi_* --------->| [AXI4-Lite CSR Engine]                |
                      |   - 0x00: TIMER_CTRL                  |
                      |   - 0x04: TIMER_RELOAD                |
                      |   - 0x08: TIMER_COUNT                 |
                      |   - 0x0C: TIMER_STATUS                |
                      |                                       |
                      | [24-bit Down Counter & Auto-Reload]   |
                      |                                       |
                      +-------------------+-------------------+
                                          |
                                          +---> sample_tick (to DMA Controller)
                                          +---> irq_timer   (to RISC-V PIC)
```

---

## 2. Port Interface

| Port Signal | Direction | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | `clk_sys` | System Clock (100 MHz nominal) |
| `rst_n` | Input | 1 | `clk_sys` | Asynchronous Active-Low System Reset |
| `sample_tick` | Output | 1 | `clk_sys` | Single-cycle strobe asserted on timer terminal count |
| `irq_timer` | Output | 1 | `clk_sys` | Level interrupt request line routed to core PIC |
| `s_axi_awaddr` | Input | 32 | `clk_sys` | AXI4-Lite Write Address |
| `s_axi_awvalid`| Input | 1 | `clk_sys` | AXI4-Lite Write Address Valid |
| `s_axi_awready`| Output| 1 | `clk_sys` | AXI4-Lite Write Address Ready |
| `s_axi_wdata`  | Input | 32 | `clk_sys` | AXI4-Lite Write Data |
| `s_axi_wstrb`  | Input | 4 | `clk_sys` | AXI4-Lite Write Byte Strobes |
| `s_axi_wvalid` | Input | 1 | `clk_sys` | AXI4-Lite Write Data Valid |
| `s_axi_wready` | Output| 1 | `clk_sys` | AXI4-Lite Write Data Ready |
| `s_axi_bresp`  | Output| 2 | `clk_sys` | AXI4-Lite Write Response (`2'b00` OKAY) |
| `s_axi_bvalid` | Output| 1 | `clk_sys` | AXI4-Lite Write Response Valid |
| `s_axi_bready` | Input | 1 | `clk_sys` | AXI4-Lite Write Response Ready |
| `s_axi_araddr` | Input | 32 | `clk_sys` | AXI4-Lite Read Address |
| `s_axi_arvalid`| Input | 1 | `clk_sys` | AXI4-Lite Read Address Valid |
| `s_axi_arready`| Output| 1 | `clk_sys` | AXI4-Lite Read Address Ready |
| `s_axi_rdata`  | Output| 32 | `clk_sys` | AXI4-Lite Read Data |
| `s_axi_rresp`  | Output| 2 | `clk_sys` | AXI4-Lite Read Response (`2'b00` OKAY) |
| `s_axi_rvalid` | Output| 1 | `clk_sys` | AXI4-Lite Read Data Valid |
| `s_axi_rready` | Input | 1 | `clk_sys` | AXI4-Lite Read Data Ready |

---

## 3. Register Memory Map (`0x8000_1000`)

| Offset | Name | Type | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x00` | `TIMER_CTRL` | R/W | `0x0000_0000` | Control Register<br>• Bit 0: `TIMER_EN` (1 = Enable counter countdown)<br>• Bit 1: `IRQ_EN` (1 = Enable interrupt generation on timeout) |
| `0x04` | `TIMER_RELOAD` | R/W | `0x0000_0000` | 24-bit Countdown Reload Value ($N$ cycles) |
| `0x08` | `TIMER_COUNT` | RO | `0x0000_0000` | Current down-counter instantaneous value |
| `0x0C` | `TIMER_STATUS` | R/W1C | `0x0000_0000` | Status Register<br>• Bit 0: `TICK` (Asserted on underflow, cleared by writing `1`) |

### Sampling Frequency Formula
With a $100\text{ MHz}$ system clock, the sampling rate $f_s$ is determined by:
$$f_s = \frac{100\text{ MHz}}{\text{TIMER\_RELOAD} + 1}$$
*Example*: To achieve a $1\text{ MSa/s}$ acquisition rate:
$$\text{TIMER\_RELOAD} = \frac{100\times 10^6}{1\times 10^6} - 1 = 99 \quad (\texttt{0x0000\_0063})$$

---

## 4. Theory of Operation
1. **Disabled State**: When `TIMER_CTRL[0] == 0`, the counter holds its current value and `sample_tick` stays low.
2. **Reload & Down-Counting**: When enabled, the down-counter decrements by 1 every system clock cycle until reaching 0.
3. **Strobe Generation**: At terminal count (`count == 0`), `sample_tick` pulses high for exactly 1 system clock cycle, the counter reloads from `TIMER_RELOAD`, and `TIMER_STATUS[0]` is asserted.
4. **Interrupt Handling**: If `TIMER_CTRL[1] == 1`, `irq_timer` is driven high continuously until software performs a Write-1-to-Clear (W1C) write of `32'h01` to `TIMER_STATUS` (`0x0C`).

---

## 5. Verification & Simulation
The unit testbench [`tb/tb_timer.sv`](../../tb/tb_timer.sv) verifies:
- AXI4-Lite register access and reset defaults.
- Counter countdown and continuous auto-reload behavior.
- Precise 1-cycle `sample_tick` pulse generation.
- Interrupt assertion and Write-1-to-Clear (W1C) deassertion.

### Running with Synopsys VCS
```bash
# Compile and run unit test
make timer

# Debug waveforms in Synopsys Verdi
make verdi TEST=timer
```

---

## 6. Design Provenance & Attribution
- **Origin**: Custom Developed IP Core for this Honours Project.
- **Specification Source**: Built to conform strictly with `doc/ArchitectureDocument.md` Section 8.5.
- **Verification Status**: Fully verified in Synopsys VCS with clean pass on `make timer`.
