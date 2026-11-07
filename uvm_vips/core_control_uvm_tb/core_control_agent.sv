class core_control_agent extends uvm_agent;
  core_control_driver drv;
  core_control_monitor mon;
  core_control_sequencer seqr;
  `uvm_component_utils(core_control_agent)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = core_control_driver::type_id::create("drv", this);
    mon  = core_control_monitor::type_id::create("mon", this);
    seqr = core_control_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
