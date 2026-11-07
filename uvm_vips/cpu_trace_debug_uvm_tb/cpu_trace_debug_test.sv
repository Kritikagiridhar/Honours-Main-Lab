class cpu_trace_debug_test extends uvm_test;
  cpu_trace_debug_env env;
  `uvm_component_utils(cpu_trace_debug_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = cpu_trace_debug_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("CPU_TRACE_DEBUG_TEST", "Running cpu_trace_debug test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
