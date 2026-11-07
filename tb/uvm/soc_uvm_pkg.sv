// ==============================================================================
// Package: soc_uvm_pkg
// Description: UVM Verification Components for Peripheral Management SoC
// Architecture: UVM Cookbook (Page 28 config_db pattern, Page 219 Sequence format)
// ==============================================================================

`ifndef SOC_UVM_PKG_SV
`define SOC_UVM_PKG_SV

package soc_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ==========================================================================
    // 1. SEQUENCE ITEMS
    // ==========================================================================

    // GPIO Sequence Item
    class gpio_item extends uvm_sequence_item;
        rand bit [7:0] gpio_in;
        bit [7:0]      gpio_out;

        `uvm_object_utils_begin(gpio_item)
            `uvm_field_int(gpio_in, UVM_ALL_ON)
            `uvm_field_int(gpio_out, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name = "gpio_item");
            super.new(name);
        endfunction
    endclass

    // UART Sequence Item
    class uart_item extends uvm_sequence_item;
        rand bit uart_rx;
        bit      uart_tx;
        bit      uart_irq;

        `uvm_object_utils_begin(uart_item)
            `uvm_field_int(uart_rx, UVM_ALL_ON)
            `uvm_field_int(uart_tx, UVM_ALL_ON)
            `uvm_field_int(uart_irq, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name = "uart_item");
            super.new(name);
        endfunction
    endclass

    // PWM Sequence Item
    class pwm_item extends uvm_sequence_item;
        bit [3:0] pwm_out;

        `uvm_object_utils_begin(pwm_item)
            `uvm_field_int(pwm_out, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name = "pwm_item");
            super.new(name);
        endfunction
    endclass

    // Seven Segment Display Sequence Item
    class seven_segment_item extends uvm_sequence_item;
        bit [7:0] ssd_seg;
        bit [3:0] ssd_digit_sel;

        `uvm_object_utils_begin(seven_segment_item)
            `uvm_field_int(ssd_seg, UVM_ALL_ON)
            `uvm_field_int(ssd_digit_sel, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name = "seven_segment_item");
            super.new(name);
        endfunction
    endclass

    // Watchdog Sequence Item
    class watchdog_item extends uvm_sequence_item;
        bit wdt_reset_out;

        `uvm_object_utils_begin(watchdog_item)
            `uvm_field_int(wdt_reset_out, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name = "watchdog_item");
            super.new(name);
        endfunction
    endclass

    // ==========================================================================
    // 2. SEQUENCERS
    // ==========================================================================
    typedef uvm_sequencer #(gpio_item) gpio_sequencer;
    typedef uvm_sequencer #(uart_item) uart_sequencer;

    // ==========================================================================
    // 3. DRIVERS (UVM Cookbook Pages 28-29 & 219 format)
    //    - Uses virtual interface handle
    //    - Retrieves vif via uvm_config_db#(virtual <if>)::get in build_phase
    //    - Drives transactions synchronized to clock edge in run_phase
    // ==========================================================================

    // GPIO Driver
    class gpio_driver extends uvm_driver #(gpio_item);
        `uvm_component_utils(gpio_driver)

        // Define as virtual interface
        virtual gpio_if vif;

        function new(string name = "gpio_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // uvm_config_db get inside driver (UVM Cookbook Page 28-29 format)
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif)) begin
                `uvm_fatal("NO_VIF", "Virtual interface 'gpio_vif' not found in uvm_config_db")
            end
        endfunction

        task run_phase(uvm_phase phase);
            vif.gpio_in <= 8'h00;
            forever begin
                seq_item_port.get_next_item(req);
                @(posedge vif.clk);
                vif.gpio_in <= req.gpio_in;
                `uvm_info("GPIO_DRV", $sformatf("Driving gpio_in = 0x%02h", req.gpio_in), UVM_HIGH)
                seq_item_port.item_done();
            end
        endtask
    endclass

    // UART Driver
    class uart_driver extends uvm_driver #(uart_item);
        `uvm_component_utils(uart_driver)

        // Define as virtual interface
        virtual uart_if vif;

        function new(string name = "uart_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // uvm_config_db get inside driver (UVM Cookbook Page 28-29 format)
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
                `uvm_fatal("NO_VIF", "Virtual interface 'uart_vif' not found in uvm_config_db")
            end
        endfunction

        task run_phase(uvm_phase phase);
            vif.uart_rx <= 1'b1; // UART idle line is high
            forever begin
                seq_item_port.get_next_item(req);
                @(posedge vif.clk);
                vif.uart_rx <= req.uart_rx;
                seq_item_port.item_done();
            end
        endtask
    endclass

    // ==========================================================================
    // 4. MONITORS (Virtual interface + config_db get + analysis port)
    // ==========================================================================

    // GPIO Monitor
    class gpio_monitor extends uvm_monitor;
        `uvm_component_utils(gpio_monitor)

        virtual gpio_if vif;
        uvm_analysis_port #(gpio_item) ap;

        function new(string name = "gpio_monitor", uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif)) begin
                `uvm_fatal("NO_VIF", "Virtual interface 'gpio_vif' not found in uvm_config_db")
            end
        endfunction

        task run_phase(uvm_phase phase);
            gpio_item item;
            logic [7:0] prev_out = 8'h00;
            forever begin
                @(posedge vif.clk);
                if (vif.rst_n) begin
                    if (vif.gpio_out !== prev_out) begin
                        item = gpio_item::type_id::create("item");
                        item.gpio_in  = vif.gpio_in;
                        item.gpio_out = vif.gpio_out;
                        ap.write(item);
                        prev_out = vif.gpio_out;
                        `uvm_info("GPIO_MON", $sformatf("Observed gpio_out changed to 0x%02h", item.gpio_out), UVM_MEDIUM)
                    end
                end
            end
        endtask
    endclass

    // PWM Monitor
    class pwm_monitor extends uvm_monitor;
        `uvm_component_utils(pwm_monitor)

        virtual pwm_if vif;
        uvm_analysis_port #(pwm_item) ap;

        function new(string name = "pwm_monitor", uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual pwm_if)::get(this, "", "pwm_vif", vif)) begin
                `uvm_fatal("NO_VIF", "Virtual interface 'pwm_vif' not found in uvm_config_db")
            end
        endfunction

        task run_phase(uvm_phase phase);
            pwm_item item;
            logic [3:0] prev_pwm = 4'h0;
            forever begin
                @(posedge vif.clk);
                if (vif.rst_n) begin
                    if (vif.pwm_out !== prev_pwm) begin
                        item = pwm_item::type_id::create("item");
                        item.pwm_out = vif.pwm_out;
                        ap.write(item);
                        prev_pwm = vif.pwm_out;
                        `uvm_info("PWM_MON", $sformatf("PWM output transition: 4'b%04b", item.pwm_out), UVM_HIGH)
                    end
                end
            end
        endtask
    endclass

    // Seven Segment Display Monitor
    class seven_segment_monitor extends uvm_monitor;
        `uvm_component_utils(seven_segment_monitor)

        virtual seven_segment_if vif;
        uvm_analysis_port #(seven_segment_item) ap;

        function new(string name = "seven_segment_monitor", uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual seven_segment_if)::get(this, "", "ssd_vif", vif)) begin
                `uvm_fatal("NO_VIF", "Virtual interface 'ssd_vif' not found in uvm_config_db")
            end
        endfunction

        task run_phase(uvm_phase phase);
            seven_segment_item item;
            logic [3:0] prev_digit = 4'hF;
            forever begin
                @(posedge vif.clk);
                if (vif.rst_n) begin
                    if (vif.ssd_digit_sel !== prev_digit) begin
                        item = seven_segment_item::type_id::create("item");
                        item.ssd_seg       = vif.ssd_seg;
                        item.ssd_digit_sel = vif.ssd_digit_sel;
                        ap.write(item);
                        prev_digit = vif.ssd_digit_sel;
                        `uvm_info("SSD_MON", $sformatf("SSD scanned digit_sel=4'b%04b, seg=8'h%02h", item.ssd_digit_sel, item.ssd_seg), UVM_HIGH)
                    end
                end
            end
        endtask
    endclass

    // Watchdog Monitor
    class watchdog_monitor extends uvm_monitor;
        `uvm_component_utils(watchdog_monitor)

        virtual watchdog_if vif;
        uvm_analysis_port #(watchdog_item) ap;

        function new(string name = "watchdog_monitor", uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual watchdog_if)::get(this, "", "wdt_vif", vif)) begin
                `uvm_fatal("NO_VIF", "Virtual interface 'wdt_vif' not found in uvm_config_db")
            end
        endfunction

        task run_phase(uvm_phase phase);
            watchdog_item item;
            forever begin
                @(posedge vif.clk);
                if (vif.wdt_reset_out) begin
                    item = watchdog_item::type_id::create("item");
                    item.wdt_reset_out = vif.wdt_reset_out;
                    ap.write(item);
                    `uvm_warning("WDT_MON", "Watchdog hardware reset indicator asserted!")
                end
            end
        endtask
    endclass

    // UART Monitor
    class uart_monitor extends uvm_monitor;
        `uvm_component_utils(uart_monitor)

        virtual uart_if vif;
        uvm_analysis_port #(uart_item) ap;

        function new(string name = "uart_monitor", uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
                `uvm_fatal("NO_VIF", "Virtual interface 'uart_vif' not found in uvm_config_db")
            end
        endfunction

        task run_phase(uvm_phase phase);
            uart_item item;
            forever begin
                @(posedge vif.clk);
                if (vif.rst_n) begin
                    item = uart_item::type_id::create("item");
                    item.uart_rx  = vif.uart_rx;
                    item.uart_tx  = vif.uart_tx;
                    item.uart_irq = vif.uart_irq;
                    ap.write(item);
                end
            end
        endtask
    endclass

    // ==========================================================================
    // 5. AGENTS
    // ==========================================================================

    // GPIO Agent (Active)
    class gpio_agent extends uvm_agent;
        `uvm_component_utils(gpio_agent)

        gpio_driver    drv;
        gpio_monitor   mon;
        gpio_sequencer seqr;

        function new(string name = "gpio_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon = gpio_monitor::type_id::create("mon", this);
            if (get_is_active() == UVM_ACTIVE) begin
                drv  = gpio_driver::type_id::create("drv", this);
                seqr = gpio_sequencer::type_id::create("seqr", this);
            end
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            if (get_is_active() == UVM_ACTIVE) begin
                drv.seq_item_port.connect(seqr.seq_item_export);
            end
        endfunction
    endclass

    // UART Agent (Active)
    class uart_agent extends uvm_agent;
        `uvm_component_utils(uart_agent)

        uart_driver    drv;
        uart_monitor   mon;
        uart_sequencer seqr;

        function new(string name = "uart_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon = uart_monitor::type_id::create("mon", this);
            if (get_is_active() == UVM_ACTIVE) begin
                drv  = uart_driver::type_id::create("drv", this);
                seqr = uart_sequencer::type_id::create("seqr", this);
            end
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            if (get_is_active() == UVM_ACTIVE) begin
                drv.seq_item_port.connect(seqr.seq_item_export);
            end
        endfunction
    endclass

    // PWM Agent (Passive monitor)
    class pwm_agent extends uvm_agent;
        `uvm_component_utils(pwm_agent)
        pwm_monitor mon;

        function new(string name = "pwm_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon = pwm_monitor::type_id::create("mon", this);
        endfunction
    endclass

    // Seven Segment Display Agent (Passive monitor)
    class seven_segment_agent extends uvm_agent;
        `uvm_component_utils(seven_segment_agent)
        seven_segment_monitor mon;

        function new(string name = "seven_segment_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon = seven_segment_monitor::type_id::create("mon", this);
        endfunction
    endclass

    // Watchdog Agent (Passive monitor)
    class watchdog_agent extends uvm_agent;
        `uvm_component_utils(watchdog_agent)
        watchdog_monitor mon;

        function new(string name = "watchdog_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon = watchdog_monitor::type_id::create("mon", this);
        endfunction
    endclass

    // ==========================================================================
    // 6. SCOREBOARD
    // ==========================================================================
    class soc_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(soc_scoreboard)

        uvm_analysis_imp #(gpio_item, soc_scoreboard) gpio_export;

        function new(string name = "soc_scoreboard", uvm_component parent = null);
            super.new(name, parent);
            gpio_export = new("gpio_export", this);
        endfunction

        virtual function void write(gpio_item item);
            `uvm_info("SCBD", $sformatf("Scoreboard received GPIO transaction: in=0x%02h out=0x%02h", item.gpio_in, item.gpio_out), UVM_HIGH)
        endfunction
    endclass

    // ==========================================================================
    // 7. ENVIRONMENT
    // ==========================================================================
    class soc_env extends uvm_env;
        `uvm_component_utils(soc_env)

        gpio_agent          gpio_ag;
        uart_agent          uart_ag;
        pwm_agent           pwm_ag;
        seven_segment_agent ssd_ag;
        watchdog_agent      wdt_ag;
        soc_scoreboard      sb;

        function new(string name = "soc_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            gpio_ag = gpio_agent::type_id::create("gpio_ag", this);
            uart_ag = uart_agent::type_id::create("uart_ag", this);
            pwm_ag  = pwm_agent::type_id::create("pwm_ag", this);
            ssd_ag  = seven_segment_agent::type_id::create("ssd_ag", this);
            wdt_ag  = watchdog_agent::type_id::create("wdt_ag", this);
            sb      = soc_scoreboard::type_id::create("sb", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            gpio_ag.mon.ap.connect(sb.gpio_export);
        endfunction
    endclass

    // ==========================================================================
    // 8. SEQUENCES (UVM Cookbook Page 219 format: start_item / finish_item)
    // ==========================================================================
    class gpio_stimulus_seq extends uvm_sequence #(gpio_item);
        `uvm_object_utils(gpio_stimulus_seq)

        function new(string name = "gpio_stimulus_seq");
            super.new(name);
        endfunction

        task body();
            gpio_item req;
            logic [7:0] test_patterns[4] = '{8'hA5, 8'h5A, 8'hFF, 8'h00};

            `uvm_info("SEQ", "Executing GPIO sequence via start_item/finish_item (Cookbook pg 219)...", UVM_LOW)

            foreach (test_patterns[i]) begin
                req = gpio_item::type_id::create("req");
                start_item(req);
                req.gpio_in = test_patterns[i];
                finish_item(req);
                #100;
            end
        endtask
    endclass

    // ==========================================================================
    // 9. TESTS
    // ==========================================================================
    class soc_test extends uvm_test;
        `uvm_component_utils(soc_test)

        soc_env env;

        function new(string name = "soc_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = soc_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            gpio_stimulus_seq seq;
            phase.raise_objection(this, "Starting SoC UVM Test");

            `uvm_info("TEST", "==================================================", UVM_LOW)
            `uvm_info("TEST", " Running UVM Testbench Integrated to SoC Design   ", UVM_LOW)
            `uvm_info("TEST", "==================================================", UVM_LOW)

            seq = gpio_stimulus_seq::type_id::create("seq");
            seq.start(env.gpio_ag.seqr);

            #500;
            `uvm_info("TEST", "==================================================", UVM_LOW)
            `uvm_info("TEST", " SoC UVM Testbench Completed Successfully!        ", UVM_LOW)
            `uvm_info("TEST", "==================================================", UVM_LOW)

            phase.drop_objection(this, "Finishing SoC UVM Test");
        endtask
    endclass

endpackage: soc_uvm_pkg

`endif
