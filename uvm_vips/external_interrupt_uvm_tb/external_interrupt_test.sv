class external_interrupt_test extends uvm_test;
  external_interrupt_env env;
  `uvm_component_utils(external_interrupt_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = external_interrupt_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("EXTERNAL_INTERRUPT_TEST", "Running external_interrupt test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
