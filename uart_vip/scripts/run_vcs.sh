#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Running from: $SCRIPT_DIR"

export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

./clean.sh

echo "========================================="
echo "Compiling UART VIP with Synopsys VCS & Verdi KDB"
echo "========================================="

vcs -full64 \
    -sverilog \
    -ntb_opts uvm \
    -kdb \
    -debug_access+all \
    -timescale=1ns/1ps \
    -f files.f \
    -l vcs.log \
    -o simv

echo "========================================="
echo "Running UVM Simulation: uart_loopback_test"
echo "========================================="

./simv +UVM_TESTNAME=uart_loopback_test -l sim.log

echo "========================================="
echo "Waveform Files Generated:"
ls -lh dump.fsdb dump.vcd 2>/dev/null || true
echo "========================================="
