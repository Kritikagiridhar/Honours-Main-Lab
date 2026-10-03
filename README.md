<<<<<<< HEAD
# RISC-V Based Smart Control SoC with PWM, SPI and Seven-Segment Display

A compact, programmable System-on-Chip built around a RISC-V processor core, connected through a
memory-mapped bus interconnect to instruction/data memory, mandatory peripherals (UART, Timer, GPIO),
and three additional hardware IPs: a PWM Generator, an SPI Controller, and a Seven-Segment Display
Controller.

> **Start here:** [`doc/ARCHITECTURE.md`](doc/ARCHITECTURE.md) is the full architecture and register
> specification — block diagram, memory map, signal list, register description, control/data paths,
> interrupts, error handling, and the full application walkthrough. Feed that file to your AI coding
> agent (Kiro CLI / Antigravity CLI) as the primary spec before generating any RTL.

## Repository Layout

| Folder | Contents |
|---|---|
| `doc/` | Architecture specification and reference docs |
| `scripts/` | Build, simulation, lint, and FPGA flash scripts |
| `rtl/` | Synthesizable design source files, one subfolder per IP |
| `tb/` | Testbenches, mirroring `rtl/` structure |
| `lib/` | Shared reusable RTL components (sync FIFO, synchronizer, BCD decoder, etc.) |
| `reg/` | Machine-readable register definitions (source of truth for Section 5 of the spec) |
| `run/` | Simulation/synthesis run outputs (git-ignored, see `.gitignore`) |

## Status

- [ ] Architecture spec drafted (`doc/ARCHITECTURE.md`)
- [ ] Register definitions authored (`reg/`)
- [ ] RTL implementation (`rtl/`)
- [ ] Testbenches (`tb/`)
- [ ] RTL simulation passing
- [ ] FPGA bring-up

## Getting Started

```bash
# Clone
git clone <your-repo-url>
cd proj-dir

# (once scripts exist)
./scripts/run_sim.sh <ip_name>      # run a single IP's testbench
./scripts/run_sim.sh all            # run full regression
./scripts/build_fpga.sh             # synthesize + generate bitstream
```

## License

Add your chosen license here (e.g. MIT, Apache-2.0) before making the repository public.
=======
# Honours-lab
tasks done in honours lab
>>>>>>> a5a4083360672ccf31bd5b393c932ae5290afcd2
