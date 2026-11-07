// ==============================================================================
// Top-Level UVM Testbench Module: tb_top
// Description: Integrates UVM VIP Interfaces with the RISC-V SoC Design (soc_top)
// Architecture: UVM Cookbook Format (Page 28 config_db::set & Page 219 format)
// ==============================================================================

`timescale 1ns / 1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import soc_uvm_pkg::*;

    // ==========================================================================
    // 1. CLOCK AND RESET GENERATION
    //    Clock driven using an ALWAYS block as required
    // ==========================================================================
    logic clk;
    logic rst_n;

    // 100 MHz System Clock (10ns period) driven via ALWAYS block
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Reset Sequence
    initial begin
        rst_n = 1'b0;
        #100;
        @(posedge clk);
        rst_n = 1'b1;
    end

    // ==========================================================================
    // 2. INTERFACE INSTANTIATIONS (Bound to clk & rst_n)
    // ==========================================================================
    uart_if          uart_vif (.clk(clk), .rst_n(rst_n));
    gpio_if          gpio_vif (.clk(clk), .rst_n(rst_n));
    pwm_if           pwm_vif  (.clk(clk), .rst_n(rst_n));
    seven_segment_if ssd_vif  (.clk(clk), .rst_n(rst_n));
    watchdog_if      wdt_vif  (.clk(clk), .rst_n(rst_n));

    // Core Control tie-offs / Vectors
    logic [31:1] rst_vec   = 31'h1000_0000 >> 1;
    logic        nmi_int   = 1'b0;
    logic [31:1] nmi_vec   = 31'h1000_0000 >> 1;
    logic [31:1] jtag_id   = 31'h0000_0001;
    logic [23:0] ext_irq   = '0;
    logic        timer_int = 1'b0;

    // ==========================================================================
    // 3. DESIGN UNDER TEST (DUT) INSTANTIATION
    //    soc_top ports connected to the physical interfaces
    // ==========================================================================
    soc_top u_dut (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .rst_vec                (rst_vec),
        .nmi_int                (nmi_int),
        .nmi_vec                (nmi_vec),
        .jtag_id                (jtag_id),

        // UART External Interface
        .uart_rx                (uart_vif.uart_rx),
        .uart_tx                (uart_vif.uart_tx),
        .uart_irq               (uart_vif.uart_irq),

        // GPIO External Interface
        .gpio_in                (gpio_vif.gpio_in),
        .gpio_out               (gpio_vif.gpio_out),

        // PWM External Outputs (4 channels)
        .pwm_out                (pwm_vif.pwm_out),

        // Seven-Segment Display Outputs (active-low cathodes & anodes)
        .ssd_seg                (ssd_vif.ssd_seg),
        .ssd_digit_sel          (ssd_vif.ssd_digit_sel),

        // Watchdog Reset Indicator
        .wdt_reset_out          (wdt_vif.wdt_reset_out),

        // External Interrupt Expansion
        .ext_irq                (ext_irq),
        .timer_int              (timer_int),

        // Trace and Status (Unconnected for functional test)
        .trace_rv_i_insn_ip     (),
        .trace_rv_i_address_ip  (),
        .trace_rv_i_valid_ip    (),
        .trace_rv_i_exception_ip(),
        .trace_rv_i_ecause_ip   (),
        .trace_rv_i_interrupt_ip(),
        .trace_rv_i_tval_ip     (),
        .o_cpu_halt_status      (),
        .o_cpu_halt_ack         (),
        .o_debug_mode_status    ()
    );

    // ==========================================================================
    // 4. UVM CONFIG_DB SET & RUN_TEST (UVM Cookbook Page 28 format)
    // ==========================================================================
    initial begin
        // Set virtual interfaces into configuration database (Page 28 format)
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top*", "uart_vif", uart_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "uvm_test_top*", "gpio_vif", gpio_vif);
        uvm_config_db#(virtual pwm_if)::set(null, "uvm_test_top*", "pwm_vif", pwm_vif);
        uvm_config_db#(virtual seven_segment_if)::set(null, "uvm_test_top*", "ssd_vif", ssd_vif);
        uvm_config_db#(virtual watchdog_if)::set(null, "uvm_test_top*", "wdt_vif", wdt_vif);

        // Waveform dump for Verdi
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, tb_top, "+all");

        // Kick off UVM test
        run_test("soc_test");
    end

endmodule
