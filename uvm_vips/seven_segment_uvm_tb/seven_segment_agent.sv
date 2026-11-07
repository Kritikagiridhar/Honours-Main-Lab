class seven_segment_agent extends uvm_agent;
  seven_segment_driver drv;
  seven_segment_monitor mon;
  seven_segment_sequencer seqr;
  `uvm_component_utils(seven_segment_agent)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = seven_segment_driver::type_id::create("drv", this);
    mon  = seven_segment_monitor::type_id::create("mon", this);
    seqr = seven_segment_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
