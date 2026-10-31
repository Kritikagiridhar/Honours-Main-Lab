#!/bin/bash
set -e

# ==============================================================================
# Run Script: RISC-V Peripheral Management SoC
#             IPs: PWM, SSD, UART, Timer, GPIO, Watchdog
# Tool       : Synopsys VCS + Verdi
# ==============================================================================
# Usage:
#   cd run
#   ./run_vcs_soc.sh          # compile + simulate
#   ./run_vcs_soc.sh verdi    # compile + simulate + open Verdi
# ==============================================================================

# Synopsys Tool Environment Setup
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

echo "=========================================================="
echo " Compiling Peripheral Management SoC with VCS..."
echo "=========================================================="
vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb \
    -f filelist_soc.f \
    -l compile_soc.log

echo "=========================================================="
echo " Running Simulation..."
echo "=========================================================="
./simv -l sim_soc.log

echo "=========================================================="
echo " Simulation Finished. Logs: compile_soc.log, sim_soc.log"
echo "=========================================================="

# Optionally launch Verdi for waveform viewing
if [ "$1" == "verdi" ]; then
    echo "=========================================================="
    echo " Launching Verdi GUI..."
    echo "=========================================================="
    $VERDI_HOME/bin/verdi -dbdir simv.daidir -ssf dump.fsdb &
fi
