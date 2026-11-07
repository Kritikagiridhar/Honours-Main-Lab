class cpu_trace_debug_driver extends uvm_driver #(cpu_trace_debug_item);
  virtual cpu_trace_debug_if vif;
  `uvm_component_utils(cpu_trace_debug_driver)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cpu_trace_debug_if)::get(this, "", "cpu_trace_debug_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface cpu_trace_debug_vif not found in uvm_config_db")
    end
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass
