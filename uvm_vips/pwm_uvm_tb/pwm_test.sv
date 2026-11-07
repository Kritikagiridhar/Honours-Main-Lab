class pwm_test extends uvm_test;
  pwm_env env;
  `uvm_component_utils(pwm_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pwm_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("PWM_TEST", "Running pwm test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
