class seven_segment_test extends uvm_test;
  seven_segment_env env;
  `uvm_component_utils(seven_segment_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = seven_segment_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("SEVEN_SEGMENT_TEST", "Running seven_segment test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
