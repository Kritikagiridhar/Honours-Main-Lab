class vga_monitor extends uvm_monitor;
  virtual vga_if vif;
  uvm_analysis_port #(vga_item) ap;
  `uvm_component_utils(vga_monitor)
  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual vga_if)::get(this, "", "vga_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface vga_vif not found in uvm_config_db")
    end
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
    end
  endtask
endclass
