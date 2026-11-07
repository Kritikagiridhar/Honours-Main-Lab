class external_interrupt_agent extends uvm_agent;
  external_interrupt_driver drv;
  external_interrupt_monitor mon;
  external_interrupt_sequencer seqr;
  `uvm_component_utils(external_interrupt_agent)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = external_interrupt_driver::type_id::create("drv", this);
    mon  = external_interrupt_monitor::type_id::create("mon", this);
    seqr = external_interrupt_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
