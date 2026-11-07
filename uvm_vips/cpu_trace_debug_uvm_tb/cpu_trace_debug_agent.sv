class cpu_trace_debug_agent extends uvm_agent;
  cpu_trace_debug_driver drv;
  cpu_trace_debug_monitor mon;
  cpu_trace_debug_sequencer seqr;
  `uvm_component_utils(cpu_trace_debug_agent)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = cpu_trace_debug_driver::type_id::create("drv", this);
    mon  = cpu_trace_debug_monitor::type_id::create("mon", this);
    seqr = cpu_trace_debug_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
