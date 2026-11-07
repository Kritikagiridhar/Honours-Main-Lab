class uart_test extends uvm_test;
  uart_env env;
  `uvm_component_utils(uart_test)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("UART_TEST", "Running uart test sequence...", UVM_LOW)
    #200;
    phase.drop_objection(this);
  endtask
endclass
