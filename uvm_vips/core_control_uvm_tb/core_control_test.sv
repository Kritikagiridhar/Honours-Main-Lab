class core_control_test extends uvm_test;
  core_control_env env;
  `uvm_component_utils(core_control_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = core_control_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("CORE_CONTROL_TEST", "Running core_control test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
