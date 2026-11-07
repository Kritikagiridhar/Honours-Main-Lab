class cpu_trace_debug_monitor extends uvm_monitor;
  virtual cpu_trace_debug_if vif;
  uvm_analysis_port #(cpu_trace_debug_item) ap;
  `uvm_component_utils(cpu_trace_debug_monitor)
  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cpu_trace_debug_if)::get(this, "", "cpu_trace_debug_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface cpu_trace_debug_vif not found in uvm_config_db")
    end
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
    end
  endtask
endclass
