# Autonomous Signal Acquisition DMA Controller (`dma_controller.sv`)

## 1. Overview & Architecture Reference
- **Module Name**: `dma_controller`
- **Source File**: [`rtl/dma_controller/dma_controller.sv`](dma_controller.sv)
- **Testbench**: [`tb/tb_dma_controller.sv`](../../tb/tb_dma_controller.sv)
- **Specification Reference**: `doc/ArchitectureDocument.md` (Section 8.6 & 9.4)
- **System Memory Base**: `0x8000_4000` (Slave Port 10 on AXI Interconnect)

The **DMA Controller** offloads the RISC-V host processor by orchestrating autonomous, real-time sample acquisitions. Upon receiving periodic `sample_tick` strobes from the Timer IP, the DMA controller executes a dedicated 16-bit SPI transaction to extract the latest sample from the external ADC, pipes the sample through the FIR filter coprocessor, and streams the filtered result directly into the dual-port Sample Buffer RAM.

```
                  +-------------------------------------------------------------+
                  |                     DMA Controller                          |
                  |                                                             |
   s_axi_* ------>| [AXI4-Lite CSR Engine]                                      |
                  |   - 0x00: DMA_CTRL (START, ABORT)                           |
                  |   - 0x04: DMA_SRC_ADDR                                      |
                  |   - 0x08: DMA_DST_ADDR                                      |
                  |   - 0x0C: DMA_LEN                                           |
                  |   - 0x10: DMA_TIMEOUT                                       |
                  |   - 0x14: DMA_STATUS (BUSY, DONE, OVF, TIMEOUT, ERR)        |
                  |                                                             |
   sample_tick -->| [Acquisition Sequencer FSM]                                 |
                  |    |                                                        |
                  |    +---> [SPI Master Engine] --------> adc_spi_* (to ADC)   |
                  |    |                                                        |
                  |    +---> [FIR Streaming Port] -------> fir_* (to Filter)    |
                  |    |                                                        |
                  |    +---> [Buffer Write Master] ------> sbuf_* (to RAM)      |
                  +-------------------------------------------------------------+
                               |
                               +---> irq_dma_done (to RISC-V PIC)
                               +---> irq_dma_err  (to RISC-V PIC)
```

---

## 2. Port Interface

| Port Signal | Direction | Width | Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | `clk_sys` | System Clock (100 MHz) |
| `rst_n` | Input | 1 | `clk_sys` | Active-Low Asynchronous Reset |
| `sample_tick` | Input | 1 | `clk_sys` | Acquisition trigger pulse from Timer IP |
| `adc_spi_sck` | Output | 1 | `clk_sys` | Generated SPI Serial Clock (25 MHz nominal) |
| `adc_spi_cs_n` | Output | 1 | `clk_sys` | Active-Low Chip Select to ADC frontend |
| `adc_spi_mosi` | Output | 1 | `clk_sys` | Master-Out-Slave-In serial data |
| `adc_spi_miso` | Input | 1 | `clk_sys` | Master-In-Slave-Out serial data from ADC |
| `fir_sample_in`| Output | 16 | `clk_sys` | Unfiltered raw sample to FIR filter |
| `fir_sample_valid_in` | Output | 1 | `clk_sys` | Valid strobe to FIR filter |
| `fir_sample_out` | Input | 16 | `clk_sys` | Filtered sample returned from FIR filter |
| `fir_sample_valid_out`| Input | 1 | `clk_sys` | Valid strobe from FIR filter |
| `sbuf_waddr` | Output | 12 | `clk_sys` | Write address pointer to Sample Buffer |
| `sbuf_wdata` | Output | 16 | `clk_sys` | Write sample data to Sample Buffer |
| `sbuf_we` | Output | 1 | `clk_sys` | Write enable strobe to Sample Buffer |
| `irq_dma_done` | Output | 1 | `clk_sys` | Asserted upon completion of programmed sample count |
| `irq_dma_err` | Output | 1 | `clk_sys` | Asserted on transfer timeout or pipeline fault |
| `s_axi_*` | Mixed | - | `clk_sys` | Standard AXI4-Lite 32-bit slave interface |

---

## 3. Register Memory Map (`0x8000_4000`)

| Offset | Name | Type | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x00` | `DMA_CTRL` | R/W | `0x0000_0000` | Control Register<br>• Bit 0: `START` (Write 1 to arm DMA acquisition)<br>• Bit 1: `ABORT` (Write 1 to abort active acquisition) |
| `0x04` | `DMA_SRC_ADDR` | R/W | `0x0000_0000` | Source Address (`0` = ADC SPI port, `>0` = System memory) |
| `0x08` | `DMA_DST_ADDR` | R/W | `0x0000_0000` | Target write address base pointer in Sample Buffer |
| `0x0C` | `DMA_LEN` | R/W | `0x0000_0000` | Number of 16-bit samples to transfer ($1 \dots 4096$) |
| `0x10` | `DMA_TIMEOUT` | R/W | `0x0000_FFFF` | Watchdog timeout cycle threshold |
| `0x14` | `DMA_STATUS` | R/W1C | `0x0000_0000` | Status Register<br>• Bit 0: `BUSY` (RO)<br>• Bit 1: `DONE` (Asserted on completion, W1C)<br>• Bit 2: `OVF` (Buffer overflow error, W1C)<br>• Bit 3: `UNDERRUN` (Data underrun error, W1C)<br>• Bit 4: `TIMEOUT` (Acquisition timed out, W1C)<br>• Bit 5: `ERR` (General error flag, W1C) |

---

## 4. Finite State Machine (FSM)

```
           +----------+
           |   IDLE   |<-------------------------------+
           +----+-----+                                |
                | START == 1                           |
                v                                      |
         +------+------+                               |
   +---->|  WAIT_TICK  |                               |
   |     +------+------+                               |
   |            | sample_tick == 1                     |
   |            v                                      |
   |     +------+------+                               |
   |     |  SPI_XFER   | (16-bit SPI Shift over MISO)  |
   |     +------+------+                               |
   |            | 16 bits shifted                      |
   |            v                                      |
   |     +------+------+                               |
   |     |   TO_FIR    | (Push sample to filter)       |
   |     +------+------+                               |
   |            v                                      |
   |     +------+------+                               |
   |     |  FROM_FIR   | (Await fir_sample_valid_out)  |
   |     +------+------+                               |
   |            v                                      |
   |     +------+------+                               |
   |     |  WRITE_BUF  |                               |
   |     +------+------+                               |
   |            |                                      |
   |   [Count < LEN]   [Count == LEN]                  |
   +------------+              v                       |
                        +------+------+                |
                        |  COMPLETE   |----------------+
                        +-------------+
```

---

## 5. Verification & Simulation
The unit testbench [`tb/tb_dma_controller.sv`](../../tb/tb_dma_controller.sv) couples the DMA controller with [`tb/adc_model.sv`](../../tb/adc_model.sv):
- Configures transfer length (`DMA_LEN = 8`) and arms the core.
- Emulates periodic `sample_tick` pacing.
- Verifies 16-bit serial SPI clock generation and MISO reception.
- Verifies streaming FIR handshake and RAM write pulses (`sbuf_we`).
- Asserts `irq_dma_done` and tests Write-1-to-Clear (W1C) status register behavior.

### Running with Synopsys VCS
```bash
# Compile and run unit test
make dma

# Debug waveforms in Synopsys Verdi
make verdi TEST=dma
```

---

## 6. Design Provenance & Attribution
- **Origin**: Custom Developed IP Core for this Honours Project.
- **Specification Source**: Built to conform strictly with `doc/ArchitectureDocument.md` Section 8.6 & 9.4.
- **Verification Status**: Fully verified in Synopsys VCS with clean pass on `make dma`.
