#!/bin/bash
set -e

# ==============================================================================
# Run Script: RISC-V SoC Integrated UVM Testbench Simulation
# Tool       : Synopsys VCS + Verdi
# Methodology: UVM 1.2 / IEEE 1800.2
# ==============================================================================
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================================="
echo " Compiling Integrated SoC UVM Testbench with VCS..."
echo "=========================================================="
vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps -debug_access+all -kdb \
    -f filelist_soc_uvm.f \
    -l compile_soc_uvm.log

echo "=========================================================="
echo " Running Integrated SoC UVM Simulation..."
echo "=========================================================="
./simv +UVM_TESTNAME=soc_test +UVM_VERBOSITY=UVM_MEDIUM -l sim_soc_uvm.log

echo "=========================================================="
echo " UVM Simulation Finished. Logs: compile_soc_uvm.log, sim_soc_uvm.log"
echo "=========================================================="

if [ "$1" == "verdi" ]; then
    echo "=========================================================="
    echo " Launching Verdi GUI..."
    echo "=========================================================="
    $VERDI_HOME/bin/verdi -dbdir simv.daidir -ssf dump.fsdb &
fi
