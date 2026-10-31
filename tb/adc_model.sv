// =============================================================================
// Module      : adc_model.sv
// Description : Behavioral SPI/ADC Stimulus Model for Simulation Verification
// Specification: Architecture Document Section 2.1.2 & 9.5
//   - Functions as an SPI slave ADC
//   - When adc_spi_cs_n is low, shifts out 16-bit signed sample words on falling sck edges
//   - Generates simulated analog waveform patterns:
//       0: Sine wave
//       1: Square wave
//       2: Triangle wave
//       3: DC test level
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module adc_model #(
    parameter DEFAULT_PATTERN = 0, // 0=Sine, 1=Square, 2=Triangle, 3=DC
    parameter SAMPLE_AMPLITUDE = 16'sd16000
)(
    input  wire adc_spi_sck,
    output wire adc_spi_miso,
    input  wire adc_spi_mosi,
    input  wire adc_spi_cs_n
);

    reg signed [15:0] current_sample;
    reg [15:0]        shift_reg;
    reg [4:0]         bit_count;
    integer           sample_index = 0;
    reg [1:0]         pattern_sel = DEFAULT_PATTERN;

    // 16-point discrete sine lookup table (scaled to Q1.15)
    reg signed [15:0] sine_lut [0:15];
    initial begin
        sine_lut[0]  = 16'sd0;
        sine_lut[1]  = 16'sd6123;
        sine_lut[2]  = 16'sd11314;
        sine_lut[3]  = 16'sd14782;
        sine_lut[4]  = 16'sd16000;
        sine_lut[5]  = 16'sd14782;
        sine_lut[6]  = 16'sd11314;
        sine_lut[7]  = 16'sd6123;
        sine_lut[8]  = 16'sd0;
        sine_lut[9]  = -16'sd6123;
        sine_lut[10] = -16'sd11314;
        sine_lut[11] = -16'sd14782;
        sine_lut[12] = -16'sd16000;
        sine_lut[13] = -16'sd14782;
        sine_lut[14] = -16'sd11314;
        sine_lut[15] = -16'sd6123;
    end

    // Function to calculate sample based on pattern
    function signed [15:0] get_sample(input integer idx, input [1:0] pat);
        case (pat)
            2'd0: get_sample = sine_lut[idx % 16];
            2'd1: get_sample = ((idx % 16) < 8) ? SAMPLE_AMPLITUDE : -SAMPLE_AMPLITUDE;
            2'd2: get_sample = -SAMPLE_AMPLITUDE + ((idx % 16) * 16'sd2000);
            2'd3: get_sample = 16'sd8000; // DC level
        endcase
    endfunction

    // Continuous drive of MISO when CS is asserted
    assign adc_spi_miso = (!adc_spi_cs_n) ? shift_reg[15] : 1'b0;

    // Latch sample on CS active edge
    always @(negedge adc_spi_cs_n) begin
        current_sample = get_sample(sample_index, pattern_sel);
        shift_reg      = current_sample;
        bit_count      = 5'd16;
        sample_index   = sample_index + 1;
    end

    // Shift data out on SPI falling SCK
    always @(negedge adc_spi_sck) begin
        if (!adc_spi_cs_n && bit_count > 0) begin
            shift_reg = {shift_reg[14:0], 1'b0};
            bit_count = bit_count - 1'b1;
        end
    end

    // Task to switch waveform pattern during simulation
    task set_pattern(input [1:0] new_pattern);
        pattern_sel = new_pattern;
    endtask

endmodule
