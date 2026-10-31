#!/bin/bash
# ==============================================================================
# Script to launch Verdi with pre-categorized signal groups for UART verification
# ==============================================================================

# Synopsys Environment Setup
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

if [ ! -f "dump.fsdb" ]; then
    echo "[ERROR] dump.fsdb not found in $SCRIPT_DIR!"
    echo "Please run simulation first: make uart-sim or ./simv"
    exit 1
fi

echo "=========================================================="
echo " Launching Verdi with categorized signal layout..."
echo " Waveform : dump.fsdb"
echo " Signals  : uart_signals.rc"
echo " Database : simv.daidir"
echo "=========================================================="

verdi -dbdir simv.daidir -ssf dump.fsdb -sswr uart_signals.rc &
