class gpio_test extends uvm_test;
  gpio_env env;
  `uvm_component_utils(gpio_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = gpio_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("GPIO_TEST", "Running gpio test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
