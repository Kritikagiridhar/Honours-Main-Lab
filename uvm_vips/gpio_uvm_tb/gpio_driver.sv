class gpio_driver extends uvm_driver #(gpio_item);
  virtual gpio_if vif;
  `uvm_component_utils(gpio_driver)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface gpio_vif not found in uvm_config_db")
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
