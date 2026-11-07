class external_interrupt_monitor extends uvm_monitor;
  virtual external_interrupt_if vif;
  uvm_analysis_port #(external_interrupt_item) ap;
  `uvm_component_utils(external_interrupt_monitor)
  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual external_interrupt_if)::get(this, "", "external_interrupt_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface external_interrupt_vif not found in uvm_config_db")
    end
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
    end
  endtask
endclass
