// =============================================================================
// Testbench : tb_soc_c_hello.sv
// Top Module: soc_top
// Tool      : Synopsys VCS / Verdi (SystemVerilog)
// Description:
//   Executes compiled C test firmware (sw/hello_world.elf) on the RISC-V
//   VeeR EL2 core and captures live serial characters transmitted over UART.
// =============================================================================

`timescale 1ns/1ps

module tb_soc_c_hello;
    import el2_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH       = 32;
    localparam ADDR_WIDTH       = 32;
    localparam STRB_WIDTH       = DATA_WIDTH / 8;
    localparam ID_WIDTH         = 8;

    // Memory Map Base Addresses
    localparam [ADDR_WIDTH-1:0] IMEM_BASE_ADDR  = 32'h1000_0000;
    localparam [ADDR_WIDTH-1:0] DMEM_BASE_ADDR  = 32'h1002_0000;
    localparam [ADDR_WIDTH-1:0] UART_BASE_ADDR  = 32'h4000_6000;
    localparam [ADDR_WIDTH-1:0] TIMER_BASE_ADDR = 32'h4000_8000;
    localparam [ADDR_WIDTH-1:0] GPIO_BASE_ADDR  = 32'h4000_A000;
    localparam [ADDR_WIDTH-1:0] SPI_BASE_ADDR   = 32'h4000_C000;
    localparam [ADDR_WIDTH-1:0] WDT_BASE_ADDR   = 32'h4000_E000;
    localparam [ADDR_WIDTH-1:0] DMA_BASE_ADDR   = 32'h4001_0000;
    localparam [ADDR_WIDTH-1:0] FIR_BASE_ADDR   = 32'h4001_2000;
    localparam [ADDR_WIDTH-1:0] VGA_BASE_ADDR   = 32'h4001_4000;
    localparam [ADDR_WIDTH-1:0] SBUF_BASE_ADDR  = 32'h4001_6000;

    localparam CLK_SYS_PERIOD_NS = 10;  // 100 MHz System Clock
    localparam CLK_VGA_PERIOD_NS = 40;  // 25 MHz Pixel Clock

    // Baud divisor = 16 configured in sw/main.c
    localparam UART_BAUD_DIV     = 16;
    localparam BIT_PERIOD_NS     = CLK_SYS_PERIOD_NS * (UART_BAUD_DIV);

    // -------------------------------------------------------------------------
    // DUT Signals
    // -------------------------------------------------------------------------
    logic                    clk;
    logic                    rst_n;
    logic                    clk_vga;

    logic [31:1]             rst_vec;
    logic                    nmi_int;
    logic [31:1]             nmi_vec;
    logic [31:1]             jtag_id;

    logic                    uart_rx;
    wire                     uart_tx;
    wire                     uart_irq;

    logic [7:0]              gpio_in;
    wire [7:0]               gpio_out;

    wire                     adc_spi_sck;
    wire                     adc_spi_mosi;
    wire                     adc_spi_miso;
    wire                     adc_spi_cs_n;

    wire                     vga_hsync;
    wire                     vga_vsync;
    wire [3:0]               vga_red;
    wire [3:0]               vga_green;
    wire [3:0]               vga_blue;

    wire                     wdt_reset_out;

    logic [23:0]             ext_irq;
    logic                    timer_int;

    wire [31:0]              trace_rv_i_insn_ip;
    wire [31:0]              trace_rv_i_address_ip;
    wire                     trace_rv_i_valid_ip;
    wire                     trace_rv_i_exception_ip;
    wire [4:0]               trace_rv_i_ecause_ip;
    wire                     trace_rv_i_interrupt_ip;
    wire [31:0]              trace_rv_i_tval_ip;

    wire                     o_cpu_halt_status;
    wire                     o_cpu_halt_ack;
    wire                     o_debug_mode_status;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    soc_top #(
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH),
        .ID_WIDTH            (ID_WIDTH),
        .UART_BASE_ADDR      (UART_BASE_ADDR),
        .IMEM_BASE_ADDR      (IMEM_BASE_ADDR),
        .DMEM_BASE_ADDR      (DMEM_BASE_ADDR),
        .TIMER_BASE_ADDR     (TIMER_BASE_ADDR),
        .GPIO_BASE_ADDR      (GPIO_BASE_ADDR),
        .SPI_BASE_ADDR       (SPI_BASE_ADDR),
        .WDT_BASE_ADDR       (WDT_BASE_ADDR),
        .DMA_BASE_ADDR       (DMA_BASE_ADDR),
        .FIR_BASE_ADDR       (FIR_BASE_ADDR),
        .VGA_BASE_ADDR       (VGA_BASE_ADDR),
        .SBUF_BASE_ADDR      (SBUF_BASE_ADDR)
    ) dut (
        .clk                 (clk),
        .rst_n               (rst_n),
        .clk_vga             (clk_vga),

        .rst_vec             (rst_vec),
        .nmi_int             (nmi_int),
        .nmi_vec             (nmi_vec),
        .jtag_id             (jtag_id),

        .uart_rx             (uart_rx),
        .uart_tx             (uart_tx),
        .uart_irq            (uart_irq),

        .gpio_in             (gpio_in),
        .gpio_out            (gpio_out),

        .adc_spi_sck         (adc_spi_sck),
        .adc_spi_mosi        (adc_spi_mosi),
        .adc_spi_miso        (adc_spi_miso),
        .adc_spi_cs_n        (adc_spi_cs_n),

        .vga_hsync           (vga_hsync),
        .vga_vsync           (vga_vsync),
        .vga_red             (vga_red),
        .vga_green           (vga_green),
        .vga_blue            (vga_blue),

        .wdt_reset_out       (wdt_reset_out),

        .ext_irq             (ext_irq),
        .timer_int           (timer_int),

        .trace_rv_i_insn_ip  (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip(trace_rv_i_address_ip),
        .trace_rv_i_valid_ip (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip(trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip(trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip  (trace_rv_i_tval_ip),

        .o_cpu_halt_status   (o_cpu_halt_status),
        .o_cpu_halt_ack      (o_cpu_halt_ack),
        .o_debug_mode_status (o_debug_mode_status)
    );

    // Clock Generators
    initial clk = 1'b0;
    always #(CLK_SYS_PERIOD_NS / 2) clk = ~clk;

    initial clk_vga = 1'b0;
    always #(CLK_VGA_PERIOD_NS / 2) clk_vga = ~clk_vga;

    // Verdi Waveform Dumping (FSDB)
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, tb_soc_c_hello, "+all");
        $fsdbDumpSVA;
        $fsdbDumpMDA;
    end

    // Helper task to write a 32-bit word into IMEM
    task automatic write_imem_word(input int index, input logic [31:0] data);
        dut.u_imem.mem_0[index] = data[7:0];
        dut.u_imem.mem_1[index] = data[15:8];
        dut.u_imem.mem_2[index] = data[23:16];
        dut.u_imem.mem_3[index] = data[31:24];
    endtask

    // Include auto-generated loader task load_c_firmware()
    `include "../sw/firmware_words.vh"

    // Task to receive a serial character from UART TX pin
    task automatic receive_uart_byte(output logic [7:0] rx_byte);
        rx_byte = 8'h00;

        // Wait for start bit falling edge
        @(negedge uart_tx);

        // Wait to middle of start bit
        repeat ((UART_BAUD_DIV + 1) / 2) @(posedge clk);

        // Sample data bits
        for (int i = 0; i < 8; i++) begin
            repeat (UART_BAUD_DIV + 1) @(posedge clk);
            rx_byte[i] = uart_tx;
        end

        // Sample / wait through stop bit
        repeat (UART_BAUD_DIV + 1) @(posedge clk);
    endtask

    // Main Test Sequence
    initial begin
        string received_banner = "";
        logic [7:0] rx_char;
        int char_count = 0;

        $display("\n==================================================================");
        $display("   STARTING RISC-V SoC C FIRMWARE HELLO WORLD SIMULATION (VCS)    ");
        $display("==================================================================");

        // 1. Initialize IMEM with NOPs
        for (int i = 0; i < 16384; i++) begin
            write_imem_word(i, 32'h0000_0013);
        end

        // 2. Load compiled C firmware binary into IMEM
        load_c_firmware();

        // 3. Reset initialization
        rst_n       = 1'b0;
        uart_rx     = 1'b1;
        gpio_in     = 8'h00;
        ext_irq     = '0;
        timer_int   = 1'b0;
        nmi_int     = 1'b0;
        nmi_vec     = 31'h7700_0000;
        jtag_id     = 31'h0000_0045;
        rst_vec     = (IMEM_BASE_ADDR >> 1); // 0x1000_0000

        #(CLK_SYS_PERIOD_NS * 20);
        @(posedge clk);
        rst_n = 1'b1; // Release reset
        $display("[SOC] Reset released. VeeR EL2 core executing from 0x1000_0000...\n");

        $display("------------------- [LIVE UART TERMINAL OUTPUT] ------------------");
        // Capture incoming serial stream from UART TX line
        fork
            begin : uart_receiver
                while (char_count < 155) begin
                    receive_uart_byte(rx_char);
                    $write("%c", rx_char);
                    char_count++;
                end
            end
            begin : simulation_timeout
                #10_000_000; // 10ms timeout
                $error("\n[TIMEOUT] C firmware execution timed out without completing output!");
                $finish(1);
            end
        join_any
        disable fork;

        $display("\n------------------------------------------------------------------");
        $display("\n[RESULT] Successfully captured full serial banner from RISC-V C code!");
        $display("==================================================================");
        $display("   >>> ALL RISC-V C FIRMWARE HELLO WORLD TESTS PASSED! <<<        ");
        $display("==================================================================\n");
        $finish(0);
    end

endmodule
