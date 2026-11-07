class sample_bus_test extends uvm_test;
  sample_bus_env env;
  `uvm_component_utils(sample_bus_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sample_bus_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("SAMPLE_BUS_TEST", "Running sample_bus test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
