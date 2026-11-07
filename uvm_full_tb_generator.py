#!/usr/bin/env python3
"""
UVM Testbench Generator
Usage:
  python uvm_full_tb_generator.py <vip_name> <signals.csv>

CSV format:
signal_name,direction,width
clk,input,1
rst_n,input,1
addr,input,32
rdata,output,32
"""

import csv
import os
import sys

if len(sys.argv) != 3:
    print('Usage: python uvm_full_tb_generator.py <vip_name> <signals.csv>')
    sys.exit(1)

VIP = sys.argv[1].lower()
CSV_FILE = sys.argv[2]

CLK_NAMES = ['clk', 'clock']
RST_NAMES = ['rst', 'rst_n', 'reset', 'reset_n']


def read_signals(csv_file):
    sigs = []
    with open(csv_file) as f:
        for row in csv.reader(f):
            if len(row) < 3:
                continue
            try:
                width = int(row[2].strip())
            except ValueError:
                continue
            sigs.append({
                'name': row[0].strip(),
                'dir': row[1].strip().lower(),
                'width': width
            })
    return sigs


def sv_type(width):
    return 'bit' if width == 1 else f'bit [{width-1}:0]'


def transaction(signals):
    s = f'class {VIP}_item extends uvm_sequence_item;\n\n'
    for sig in signals:
        if sig['name'] not in CLK_NAMES + RST_NAMES:
            rand = 'rand ' if sig['dir'] == 'input' else ''
            s += f'  {rand}{sv_type(sig["width"])} {sig["name"]};\n'
    s += f"\n  `uvm_object_utils({VIP}_item)\n\n"
    s += f"  function new(string name=\"{VIP}_item\"); super.new(name); endfunction\n"
    s += 'endclass\n'
    return s


def sequencer():
    return f'class {VIP}_sequencer extends uvm_sequencer #({VIP}_item);\n`uvm_component_utils({VIP}_sequencer)\nfunction new(string n,uvm_component p);super.new(n,p);endfunction\nendclass\n'


def driver():
    return f'''class {VIP}_driver extends uvm_driver #({VIP}_item);
  virtual {VIP}_if vif;
  `uvm_component_utils({VIP}_driver)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual {VIP}_if)::get(this, "", "{VIP}_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface {VIP}_vif not found in uvm_config_db")
    end
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass
'''


def monitor():
    return f'''class {VIP}_monitor extends uvm_monitor;
  virtual {VIP}_if vif;
  uvm_analysis_port #({VIP}_item) ap;
  `uvm_component_utils({VIP}_monitor)
  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual {VIP}_if)::get(this, "", "{VIP}_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface {VIP}_vif not found in uvm_config_db")
    end
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
    end
  endtask
endclass
'''


def agent():
    return f'''class {VIP}_agent extends uvm_agent;
  {VIP}_driver drv;
  {VIP}_monitor mon;
  {VIP}_sequencer seqr;
  `uvm_component_utils({VIP}_agent)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = {VIP}_driver::type_id::create("drv", this);
    mon  = {VIP}_monitor::type_id::create("mon", this);
    seqr = {VIP}_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
'''


def scoreboard():
    return f'''class {VIP}_scoreboard extends uvm_scoreboard;
  `uvm_component_utils({VIP}_scoreboard)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
'''


def env():
    return f'''class {VIP}_env extends uvm_env;
  {VIP}_agent agent;
  {VIP}_scoreboard sb;
  `uvm_component_utils({VIP}_env)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = {VIP}_agent::type_id::create("agent", this);
    sb    = {VIP}_scoreboard::type_id::create("sb", this);
  endfunction
endclass
'''


def test():
    return f'''class {VIP}_test extends uvm_test;
  {VIP}_env env;
  `uvm_component_utils({VIP}_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = {VIP}_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("{VIP.upper()}_TEST", "Running {VIP} test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
'''


def interface(signals):
    s = f'interface {VIP}_if;\n'
    for sig in signals:
        if sig['width'] == 1:
            s += f'  logic {sig["name"]};\n'
        else:
            s += f'  logic [{sig["width"]-1}:0] {sig["name"]};\n'
    s += 'endinterface\n'
    return s


def package():
    return f'''package {VIP}_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "{VIP}_item.sv"
  `include "{VIP}_sequencer.sv"
  `include "{VIP}_driver.sv"
  `include "{VIP}_monitor.sv"
  `include "{VIP}_agent.sv"
  `include "{VIP}_scoreboard.sv"
  `include "{VIP}_env.sv"
  `include "{VIP}_test.sv"
endpackage
'''


def tb_top():
    return f'''module tb_top;
  import uvm_pkg::*;
  import {VIP}_pkg::*;

  logic clk;
  logic rst_n;

  // Clock generation using always block
  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 1'b0;
    #20 rst_n = 1'b1;
  end

  {VIP}_if vif();
  assign vif.clk   = clk;
  assign vif.rst_n = rst_n;

  initial begin
    uvm_config_db#(virtual {VIP}_if)::set(null, "uvm_test_top*", "{VIP}_vif", vif);
    run_test("{VIP}_test");
  end
endmodule
'''

signals = read_signals(CSV_FILE)
outdir = f'{VIP}_uvm_tb'
os.makedirs(outdir, exist_ok=True)
files = {
f'{VIP}_if.sv': interface(signals),
f'{VIP}_item.sv': transaction(signals),
f'{VIP}_sequencer.sv': sequencer(),
f'{VIP}_driver.sv': driver(),
f'{VIP}_monitor.sv': monitor(),
f'{VIP}_agent.sv': agent(),
f'{VIP}_scoreboard.sv': scoreboard(),
f'{VIP}_env.sv': env(),
f'{VIP}_test.sv': test(),
f'{VIP}_pkg.sv': package(),
'tb_top.sv': tb_top()
}
for n,c in files.items():
    open(os.path.join(outdir,n),'w').write(c)
print('Generated:', outdir)
