class sample_bus_driver extends uvm_driver #(sample_bus_item);
  virtual sample_bus_if vif;
  `uvm_component_utils(sample_bus_driver)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sample_bus_if)::get(this, "", "sample_bus_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface sample_bus_vif not found in uvm_config_db")
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
