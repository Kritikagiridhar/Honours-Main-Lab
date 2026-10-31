# General Purpose Input/Output IP Core (`gpio.sv`)

## 1. Overview & Architecture Reference
- **Module Name**: `gpio`
- **Source File**: [`rtl/gpio/gpio.sv`](gpio.sv)
- **Testbench**: [`tb/tb_gpio.sv`](../../tb/tb_gpio.sv)
- **Specification Reference**: `doc/ArchitectureDocument.md` (Section 8.8)
- **System Memory Base**: `0x8000_2000` (Slave Port 8 on AXI Interconnect)

The **GPIO** peripheral interfaces the SoC with external board peripherals (pushbuttons, switches, LEDs, and auxiliary trigger lines). It incorporates 2-stage double-flop synchronizers on all inputs to prevent metastability, programmable edge-detection interrupt generators, and dedicated output drive registers.

```
                      +------------------------------------------+
                      |                 GPIO IP                  |
                      |                                          |
    s_axi_* --------->| [AXI4-Lite CSR Engine]                   |
                      |   - 0x00: GPIO_DATA_IN                   |
                      |   - 0x04: GPIO_DATA_OUT                  |
                      |   - 0x08: GPIO_DIR                       |
                      |   - 0x0C: GPIO_IRQ_EN                    |
                      |   - 0x10: GPIO_IRQ_EDGE                  |
                      |   - 0x14: GPIO_IRQ_STATUS                |
                      |                                          |
    gpio_in  -------->| [Double-Flop Sync] ---> [Edge Detector]  |
                      |                                   |      |
                      |                                   v      |
    gpio_out <--------| [Output Driver]               irq_gpio   |
                      +------------------------------------------+
```

---

## 2. Port Interface

| Port Signal | Direction | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | `clk_sys` | System Clock (100 MHz) |
| `rst_n` | Input | 1 | `clk_sys` | Active-Low Asynchronous Reset |
| `gpio_in` | Input | 16 | External | Asynchronous digital input pins (switches, buttons) |
| `gpio_out` | Output | 16 | `clk_sys` | Driven digital output pins (LEDs, debug testpoints) |
| `gpio_oe` | Output | 16 | `clk_sys` | Output enable mask for bidirectional buffers |
| `irq_gpio` | Output | 1 | `clk_sys` | Interrupt request line routed to core PIC |
| `s_axi_*` | Mixed | - | `clk_sys` | Standard AXI4-Lite 32-bit slave interface |

---

## 3. Register Memory Map (`0x8000_2000`)

| Offset | Name | Type | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x00` | `GPIO_DATA_IN` | RO | `0x0000_0000` | Synchronized input state of all 16 `gpio_in` pins |
| `0x04` | `GPIO_DATA_OUT` | R/W | `0x0000_0000` | Output drive value for all 16 `gpio_out` pins |
| `0x08` | `GPIO_DIR` | R/W | `0x0000_0000` | Direction mask (`1` = Output enable `gpio_oe`, `0` = Input) |
| `0x0C` | `GPIO_IRQ_EN` | R/W | `0x0000_0000` | Per-pin interrupt enable mask |
| `0x10` | `GPIO_IRQ_EDGE` | R/W | `0x0000_0000` | Per-pin edge selection (`1` = Rising edge, `0` = Falling edge) |
| `0x14` | `GPIO_IRQ_STATUS`| R/W1C | `0x0000_0000` | Latched interrupt status flags (Write-1-to-Clear) |

---

## 4. Hardware Implementation Details
- **Metastability Mitigation**: All asynchronous external lines on `gpio_in` pass through a dual-stage flip-flop synchronizer prior to any internal edge sampling.
- **Edge Detection**: A third flip-flop stage holds the previous cycle value. The core computes:
  $$\text{edge\_detect} = (\text{GPIO\_IRQ\_EDGE} \ \& \ (\text{sync\_in} \ \& \ \sim\text{prev\_in})) \ | \ (\sim\text{GPIO\_IRQ\_EDGE} \ \& \ (\sim\text{sync\_in} \ \& \ \text{prev\_in}))$$
- **Interrupt Routing**: Whenever $(\text{edge\_detect} \ \& \ \text{GPIO\_IRQ\_EN}) \neq 0$, the corresponding bits in `GPIO_IRQ_STATUS` latch high. `irq_gpio` stays asserted as long as any unmasked status bit remains set.

---

## 5. Verification & Simulation
The testbench [`tb/tb_gpio.sv`](../../tb/tb_gpio.sv) validates:
- AXI4-Lite register write and readback integrity.
- Double-flop synchronization of asynchronous input transitions.
- Rising and falling edge interrupt detection.
- Interrupt masking and Write-1-to-Clear (W1C) status clearing.
- Output register drive and direction control (`gpio_oe`).

### Running with Synopsys VCS
```bash
# Compile and run unit test
make gpio

# Debug waveforms in Synopsys Verdi
make verdi TEST=gpio
```

---

## 6. Design Provenance & Attribution
- **Origin**: Custom Developed IP Core for this Honours Project.
- **Specification Source**: Built to conform strictly with `doc/ArchitectureDocument.md` Section 8.8.
- **Verification Status**: Fully verified in Synopsys VCS with clean pass on `make gpio`.
