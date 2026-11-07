class spi_agent extends uvm_agent;
  spi_driver drv;
  spi_monitor mon;
  spi_sequencer seqr;
  `uvm_component_utils(spi_agent)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = spi_driver::type_id::create("drv", this);
    mon  = spi_monitor::type_id::create("mon", this);
    seqr = spi_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
