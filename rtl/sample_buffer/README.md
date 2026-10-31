# Dual-Port Sample Buffer IP Core (`sample_buffer.sv`)

## 1. Overview & Architecture Reference
- **Module Name**: `sample_buffer`
- **Source File**: [`rtl/sample_buffer/sample_buffer.sv`](sample_buffer.sv)
- **Testbench**: [`tb/tb_sample_buffer.sv`](../../tb/tb_sample_buffer.sv)
- **Specification Reference**: `doc/ArchitectureDocument.md` (Section 8.4, 9.4 & 10.2)
- **System Memory Base**: `0x0002_0000` (Slave Port 5 on AXI Interconnect, 8 KB Address Space)

The **Sample Buffer** provides 4096 entries of 16-bit sample storage configured as a True Dual-Port Asynchronous RAM. It acts as the primary data exchange bridge between high-speed signal acquisition, CPU measurement math, and the real-time VGA video display engine across separate clock domains.

```
                  +--------------------------------------------------------+
                  |               Dual-Port Sample Buffer                  |
                  |                                                        |
   clk_sys ------>| [PORT A: Synchronous DMA Write Port]                   |
   sbuf_waddr --->|   - 12-bit Write Address                               |
   sbuf_wdata --->|   - 16-bit Sample Data                                 |
   sbuf_we ------>|   - 1-cycle Write Strobe                               |
                  |                                                        |
                  |                  [4096 x 16-bit SRAM Array]            |
                  |                                                        |
   clk_sys ------>| [PORT B1: AXI4-Lite Read Port for CPU Math (DP5)]      |
   s_axi_* ------>|   - Base 0x0002_0000 (araddr[12:1] -> word index)      |
                  |   - Single-cycle zero-wait-state RAM read              |
                  |                                                        |
   clk_vga ------>| [PORT B2: Asynchronous VGA Display Scan Port]          |
   vga_raddr ---->|   - 12-bit Raster Read Address                         |
                  |   - 16-bit Trace Sample Data Output ------------------>| vga_rdata
                  +--------------------------------------------------------+
```

---

## 2. Port Interface

| Port Signal | Direction | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk_sys` | Input | 1 | `clk_sys` | System Clock (100 MHz) |
| `rst_sys_n` | Input | 1 | `clk_sys` | Active-Low System Reset |
| `sbuf_waddr` | Input | 12 | `clk_sys` | DMA Write Address pointer ($0 \dots 4095$) |
| `sbuf_wdata` | Input | 16 | `clk_sys` | 16-bit Filtered Sample Data |
| `sbuf_we` | Input | 1 | `clk_sys` | Write Enable strobe |
| `s_axi_*` | Mixed | - | `clk_sys` | AXI4-Lite Slave Port (CPU waveform readback) |
| `clk_vga` | Input | 1 | `clk_vga` | Video Pixel Clock (25.175 MHz) |
| `rst_vga_n` | Input | 1 | `clk_vga` | Active-Low VGA Domain Reset |
| `vga_raddr` | Input | 12 | `clk_vga` | VGA Raster Scan Horizontal Sample Index |
| `vga_rdata` | Output | 16 | `clk_vga` | Sample output fed to VGA vertical comparator |

---

## 3. Memory Mapping & Address Translation
The sample buffer is mapped into the SoC physical address map at:
- **Base Address**: `0x0002_0000`
- **End Address**: `0x0002_1FFF` (8192 bytes = 4096 16-bit halfwords)
- **AXI Slave Port**: Interconnect Slave Port 5 (`DP5`)

### CPU Word Translation
Since each sample is 16 bits (2 bytes), the AXI byte address `s_axi_araddr` is translated into the 12-bit internal SRAM word address:
$$\text{ram\_word\_addr} = \text{s\_axi\_araddr}[12:1]$$
Read data is zero-extended or sign-extended onto the 32-bit AXI read data bus:
$$\text{s\_axi\_rdata} = \{16\text{'d0}, \ \text{mem}[\text{ram\_word\_addr}]\}$$

---

## 4. Clock Domain Crossing (CDC) Architecture
- **Port A (DMA Write)**: Operates completely synchronously within the $100\text{ MHz}$ system domain.
- **Port B1 (AXI Read)**: Operates synchronously within the $100\text{ MHz}$ system domain, giving the RISC-V core direct random-access read capability to compute $V_{\text{pp}}$, $V_{\text{rms}}$, and frequency without stalling the pipeline.
- **Port B2 (VGA Read)**: Operates in the $25.175\text{ MHz}$ video clock domain. Read accesses are completely non-destructive and independent of Port A writes.

---

## 5. Verification & Simulation
The unit testbench [`tb/tb_sample_buffer.sv`](../../tb/tb_sample_buffer.sv) validates:
- Simultaneous write operations on Port A and read operations on Port B.
- Independent clock-domain operation ($100\text{ MHz}$ write vs. $25\text{ MHz}$ read).
- AXI4-Lite slave address decoding and sample readback.
- Data integrity across all 4096 memory locations.

### Running with Synopsys VCS
```bash
# Compile and run unit test
make sample_buffer

# Debug waveforms in Synopsys Verdi
make verdi TEST=sample_buffer
```

---

## 6. Design Provenance & Attribution
- **Origin**: Custom Developed IP Core for this Honours Project.
- **Specification Source**: Built to conform strictly with `doc/ArchitectureDocument.md` Section 8.4, 9.4 & 10.2.
- **Verification Status**: Fully verified in Synopsys VCS with clean pass on `make sample_buffer`.
