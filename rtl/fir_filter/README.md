# 16-Tap Digital FIR Filter IP Core (`fir_filter.sv`)

## 1. Overview & Architecture Reference
- **Module Name**: `fir_filter`
- **Source File**: [`rtl/fir_filter/fir_filter.sv`](fir_filter.sv)
- **Testbench**: [`tb/tb_fir_filter.sv`](../../tb/tb_fir_filter.sv)
- **Specification Reference**: `doc/ArchitectureDocument.md` (Section 8.7 & 10.3)
- **System Memory Base**: `0x8000_3000` (Slave Port 9 on AXI Interconnect)

The **FIR Filter** is a high-speed DSP coprocessor that performs real-time digital filtering on digitized ADC samples before they are stored into the sample buffer. It implements a 16-tap Finite Impulse Response (FIR) pipeline using 16-bit signed Q1.15 fixed-point arithmetic with configurable coefficients, saturation protection, and low-latency bypass capability.

```
                      +-----------------------------------------------+
                      |           16-Tap FIR Filter Core              |
                      |                                               |
    s_axi_* --------->| [AXI4-Lite Coefficient & Control Bank]        |
                      |   - 0x00: FIR_CTRL (BYPASS, EN)               |
                      |   - 0x04: FIR_STATUS                          |
                      |   - 0x10..0x4C: FIR_COEFF_0..15 (Q1.15)       |
                      |                                               |
    sample_in ------->| [16-Sample Shift Register Delay Line]         |
    sample_valid_in ->|                      |                        |
                      |                      v                        |
                      | [Pipelined Multiply-Accumulate (MAC) Tree]    |
                      |                      |                        |
                      |                      v                        |
                      | [Q1.15 Truncation & Saturation Limiter]       |
                      |                      |                        |
                      +----------------------+------------------------+
                                             |
                                             +---> sample_out (Q1.15)
                                             +---> sample_valid_out
```

---

## 2. Port Interface

| Port Signal | Direction | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | `clk_sys` | System Clock (100 MHz) |
| `rst_n` | Input | 1 | `clk_sys` | Active-Low Asynchronous Reset |
| `sample_in` | Input | 16 (Signed) | `clk_sys` | Incoming 16-bit Q1.15 sample from DMA/ADC |
| `sample_valid_in` | Input | 1 | `clk_sys` | Valid strobe accompanying `sample_in` |
| `sample_out` | Output | 16 (Signed) | `clk_sys` | Filtered (or bypassed) 16-bit Q1.15 output sample |
| `sample_valid_out`| Output | 1 | `clk_sys` | Valid strobe accompanying `sample_out` |
| `s_axi_*` | Mixed | - | `clk_sys` | Standard AXI4-Lite 32-bit slave interface |

---

## 3. Register Memory Map (`0x8000_3000`)

| Offset | Name | Type | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x00` | `FIR_CTRL` | R/W | `0x0000_0001` | Control Register<br>• Bit 0: `BYPASS` (1 = Direct passthrough with 1 cycle latency)<br>• Bit 1: `ENABLE` (1 = Process through 16-tap MAC engine) |
| `0x04` | `FIR_STATUS` | RO | `0x0000_0000` | Status Register<br>• Bit 0: `BUSY` |
| `0x10` | `FIR_COEFF_0` | R/W | `0x0000_2000` | Coefficient 0 (Tap 0) in Q1.15 format |
| `0x14` | `FIR_COEFF_1` | R/W | `0x0000_2000` | Coefficient 1 (Tap 1) in Q1.15 format |
| ... | ... | ... | ... | Coefficients 2 to 14 |
| `0x4C` | `FIR_COEFF_15`| R/W | `0x0000_0000` | Coefficient 15 (Tap 15) in Q1.15 format |

---

## 4. Arithmetic & DSP Architecture
The filter calculates the standard convolution sum:
$$y[n] = \sum_{k=0}^{15} h[k] \cdot x[n-k]$$

### Q1.15 Fixed-Point Format
- Range: $[-1.0, +0.999969]$
- Representation: Bit 15 is the sign bit; bits $[14:0]$ represent fractional magnitude ($2^{-1}$ to $2^{-15}$).
- Multiplying two Q1.15 numbers yields a 32-bit Q2.30 intermediate product.
- The 16 individual products are summed into a 36-bit accumulator with 4 guard bits to prevent overflow during intermediate summation.
- The accumulator result is shifted right by 15 bits and saturated to the 16-bit limits (`[-32768, +32767]`).

### Bypass Mode
When `FIR_CTRL[0] == 1`, the MAC arithmetic is bypassed, and `sample_in` is registered straight to `sample_out` in exactly 1 clock cycle. This preserves phase alignment while saving dynamic switching power.

---

## 5. Verification & Simulation
The unit testbench [`tb/tb_fir_filter.sv`](../../tb/tb_fir_filter.sv) validates:
- Power-on default bypass operation ($y[n] = x[n]$ with 1-cycle latency).
- Dynamic coefficient loading over AXI4-Lite.
- 4-Tap Moving Average step response convergence:
  $$\text{Input: Step of } 16000 \quad \longrightarrow \quad \text{Output steps: } 4000 \rightarrow 8000 \rightarrow 12000 \rightarrow 16000$$
- Truncation precision and mathematical correctness.

### Running with Synopsys VCS
```bash
# Compile and run unit test
make fir

# Debug waveforms in Synopsys Verdi
make verdi TEST=fir
```

---

## 6. Design Provenance & Attribution
- **Origin**: Custom Developed IP Core for this Honours Project.
- **Specification Source**: Built to conform strictly with `doc/ArchitectureDocument.md` Section 8.7 & 10.3.
- **Verification Status**: Fully verified in Synopsys VCS with clean pass on `make fir`.
