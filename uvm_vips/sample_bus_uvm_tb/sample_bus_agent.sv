class sample_bus_agent extends uvm_agent;
  sample_bus_driver drv;
  sample_bus_monitor mon;
  sample_bus_sequencer seqr;
  `uvm_component_utils(sample_bus_agent)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = sample_bus_driver::type_id::create("drv", this);
    mon  = sample_bus_monitor::type_id::create("mon", this);
    seqr = sample_bus_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
