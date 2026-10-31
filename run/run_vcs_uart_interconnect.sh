#!/bin/bash
set -e

# Synopsys Tool Environment Setup
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

echo "=========================================================="
echo " Compiling AXI Interconnect + UART with Synopsys VCS..."
echo "=========================================================="
vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb \
    -f filelist_uart_interconnect.f \
    -l compile_uart.log

echo "=========================================================="
echo " Running Simulation..."
echo "=========================================================="
./simv -l sim_uart.log

echo "=========================================================="
echo " Simulation Finished."
echo "=========================================================="
