#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

rm -rf \
  csrc \
  simv \
  simv.daidir \
  ucli.key \
  vc_hdrs.h \
  vcs.log \
  sim.log \
  dump.vcd \
  dump.fsdb \
  novas.conf \
  novas_dump.log \
  novas.rc \
  verdiLog \
  work \
  uvm \
  transcript \
  vsim.wlf \
  modelsim.ini

echo "Clean done."
