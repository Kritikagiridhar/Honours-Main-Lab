#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

if [ ! -f "dump.fsdb" ]; then
  echo "Error: dump.fsdb not found. Running simulation first..."
  ./run_vcs.sh
fi

echo "========================================================"
echo "Launching Synopsys Verdi GUI with dump.fsdb and signals"
echo "========================================================"

if [ -f "verdi_signals.rc" ]; then
  verdi -dbdir simv.daidir -ssf dump.fsdb -sswr verdi_signals.rc &
else
  verdi -dbdir simv.daidir -ssf dump.fsdb &
fi
