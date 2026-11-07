# UART VIP

UVM-based UART VIP with full Transmit (Driver), Receive (Monitor), Scoreboard, and an Echo/Loopback DUT with interrupt support. Follows standard UVM 1.2 conventions and reference repository architecture.

---

## What it does

- **Transmit (TX):** VIP Driver serializes 8-N-1 UART frame (Start bit, 8 data bits LSB-first, Stop bit) to `uart_rx` synchronized to clock.
- **Receive (RX):** VIP Monitor samples `uart_tx` at the center of each bit period, reconstructs the byte, validates frame/stop bit, and broadcasts transaction to analysis port.
- **Scoreboard:** Subscriber pattern verifying framing integrity, counting valid packets, and matching expected vs actual byte values.
- **DUT Loopback:** Synthesizable UART loopback DUT receives bytes, asserts `irq`, buffers in FIFO, and echoes data back on `tx`.

---

## How to run

```bash
cd scripts
chmod +x run_vcs.sh clean.sh

./run_vcs.sh                     # Compiles with VCS and runs uart_rw_test
./simv +UVM_TESTNAME=uart_loopback_test  # Runs deterministic pattern test
./clean.sh                       # Removes simulation artifacts
```

---

## Folder structure

```
uart_vip/
├── if/
│   └── uart_if.sv              UART interface (clk, rst_n, uart_rx, uart_tx, uart_irq, debug probes)
│
├── common/
│   ├── uart_seq_item.sv        One item = one UART byte frame (UART_TX, UART_RX, UART_LOOPBACK)
│   └── uart_cfg.sv             Config: clocks_per_bit, baud_rate, frame parameters, mode
│
├── agent/
│   ├── uart_sequencer.sv       Standard UVM sequencer
│   ├── uart_driver.sv          UART transmitter driver (8-N-1 serial bitstream)
│   ├── uart_monitor.sv         UART receiver monitor (bit-center sampling, framing check)
│   └── uart_agent.sv           Standard UVM agent instantiating driver, monitor, sequencer
│
├── seq/
│   ├── uart_tx_seq.sv          Generates and sends N randomized byte transactions
│   └── uart_loopback_seq.sv    Sends deterministic test patterns (0xA5, 0x5A, 0x33, 0xCC, 0xF0)
│
├── env/
│   ├── uart_scoreboard.sv      Subscriber pattern scoreboard verifying data and frame integrity
│   └── uart_env.sv             UVM environment connecting agent monitor to scoreboard
│
├── tests/
│   ├── uart_rw_test.sv         UVM test running random write/read verification
│   └── uart_loopback_test.sv   UVM test running loopback pattern verification
│
├── example_dut/
│   └── uart_dut.sv             Synthesizable UART echo/loopback DUT with FIFO and IRQ
│
├── tb/
│   └── example_tb_top.sv       Top-level testbench (clock, reset, interface, config_db::set, run_test)
│
├── scripts/
│   ├── files.f                 VCS file list with include directories
│   ├── run_vcs.sh              Compile and simulation script for Synopsys VCS
│   ├── clean.sh                Clean script
│   └── how_to_run.txt          Execution guide
│
├── uart_vip_pkg.sv             Package compiling all VIP classes in order
└── README.md                   VIP documentation
```

---

## Verification Results

Simulated on Synopsys VCS U-2023.03 with UVM 1.2:
- **`uart_rw_test`:** 5/5 transactions passed, 0 framing errors, 0 errors, 0 warnings, 0 fatals.
- **`uart_loopback_test`:** 5/5 pattern matches passed, 0 errors, 0 warnings, 0 fatals.
