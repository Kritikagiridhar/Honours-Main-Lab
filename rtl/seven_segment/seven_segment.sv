// =============================================================================
// Module      : seven_segment.sv
// Description : 4-Digit Multiplexed Seven-Segment Display Controller with
//               AXI4-Lite Slave Interface
// Project     : RISC-V Based Smart Control SoC with PWM, SPI and Seven-Segment Display
//
// Memory Map  : Base 0x4000_4000 (4 KB aperture)
// Registers   :
//     0x00: SSD_CTRL    [0] EN     (display enable)
//                        [1] MODE  (0 = hex decode, 1 = raw segment data)
//     0x04: SSD_DATA    [15:0] Display value
//                        Hex mode : nibble per digit (digit3=d[15:12]..digit0=d[3:0])
//                        Raw mode : 2 segments per byte (seg[6:0] + dp) per digit
//     0x08: SSD_BRIGHT  [7:0] Refresh prescaler (controls multiplexing rate)
//     0x0C: SSD_STATUS [0]  RUNNING (RO)
//
// Outputs     :
//     seg[7:0]     : Segment cathodes {dp,g,f,e,d,c,b,a}, active low
//     digit_sel[3:0]: Digit anode select, active low (one-hot asserted)
//     irq_ssd      : (reserved) tied low
// =============================================================================

`resetall
`timescale 1ns / 1ps
`default_nettype none

module seven_segment #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // AXI4-Lite Slave Interface
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // Seven-Segment Physical Outputs
    output reg  [7:0]            seg,        // active-low cathodes
    output reg  [3:0]            digit_sel,  // active-low anode select
    output wire                  irq_ssd
);

    // -------------------------------------------------------------------------
    // Control / Status Registers
    // -------------------------------------------------------------------------
    reg        reg_en;
    reg        reg_mode;      // 0 = hex, 1 = raw
    reg [15:0] reg_data;      // display value
    reg [7:0]  reg_bright;    // refresh prescaler
    reg [1:0]  digit_idx;     // active digit 0..3
    reg [7:0]  refresh_cnt;   // multiplex prescaler counter

    assign irq_ssd = 1'b0;

    // -------------------------------------------------------------------------
    // Hex-to-7-Segment Decoder (common anode, active-low cathodes)
    //   seg[7:0] = {dp, g, f, e, d, c, b, a}
    // -------------------------------------------------------------------------
    function [7:0] hex_to_seg(input [3:0] hex);
        case (hex)
            4'h0: hex_to_seg = 8'b1100_0000; // 0
            4'h1: hex_to_seg = 8'b1111_1001; // 1
            4'h2: hex_to_seg = 8'b1010_0100; // 2
            4'h3: hex_to_seg = 8'b1011_0000; // 3
            4'h4: hex_to_seg = 8'b1001_1001; // 4
            4'h5: hex_to_seg = 8'b1001_0010; // 5
            4'h6: hex_to_seg = 8'b1000_0010; // 6
            4'h7: hex_to_seg = 8'b1111_1000; // 7
            4'h8: hex_to_seg = 8'b1000_0000; // 8
            4'h9: hex_to_seg = 8'b1001_0000; // 9
            4'hA: hex_to_seg = 8'b1000_1000; // A
            4'hB: hex_to_seg = 8'b1000_0011; // b
            4'hC: hex_to_seg = 8'b1100_0110; // C
            4'hD: hex_to_seg = 8'b1010_0001; // d
            4'hE: hex_to_seg = 8'b1000_0110; // E
            4'hF: hex_to_seg = 8'b1000_1110; // F
        endcase
    endfunction

    // Extract per-digit nibble from display value
    wire [3:0] digit_nibble [0:3];
    assign digit_nibble[0] = reg_data[3:0];
    assign digit_nibble[1] = reg_data[7:4];
    assign digit_nibble[2] = reg_data[11:8];
    assign digit_nibble[3] = reg_data[15:12];

    // Raw segment extraction (8 bits per digit packed into reg_data)
    wire [7:0] raw_seg [0:3];
    assign raw_seg[0] = {1'b1, reg_data[6:0]};       // dp off + 7 segs
    assign raw_seg[1] = {1'b1, reg_data[14:8]};
    // Only 2 raw digits fit in 16 bits; remaining reuse hex of zero nibble
    assign raw_seg[2] = hex_to_seg(digit_nibble[2]);
    assign raw_seg[3] = hex_to_seg(digit_nibble[3]);

    // -------------------------------------------------------------------------
    // Multiplexing State Machine
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_en      <= 1'b0;
            reg_mode    <= 1'b0;
            reg_data    <= 16'd0;
            reg_bright  <= 8'd0;
            digit_idx   <= 2'd0;
            refresh_cnt <= 8'd0;
            seg         <= 8'b1111_1111;
            digit_sel   <= 4'b1111;
        end else begin
            if (reg_en) begin
                // Refresh prescaler
                if (refresh_cnt >= reg_bright) begin
                    refresh_cnt <= 8'd0;
                    // Advance to next digit
                    digit_idx <= digit_idx + 2'd1;

                    // Drive segments for the active digit
                    if (reg_mode == 1'b0) begin
                        // Hex decode mode
                        seg <= hex_to_seg(digit_nibble[digit_idx]);
                    end else begin
                        // Raw segment mode
                        seg <= raw_seg[digit_idx];
                    end

                    // Assert only the active digit (active low)
                    digit_sel <= ~(4'b0001 << digit_idx);
                end else begin
                    refresh_cnt <= refresh_cnt + 8'd1;
                end
            end else begin
                seg       <= 8'b1111_1111; // all off
                digit_sel <= 4'b1111;       // all digits off
                refresh_cnt <= 8'd0;
                digit_idx  <= 2'd0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Channel
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            aw_done        <= 1'b0;
            w_done         <= 1'b0;
            awaddr_latched <= {ADDR_WIDTH{1'b0}};
        end else begin
            // Address Write Channel
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            // Write Data Channel
            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Register write execution
            if (aw_done && w_done && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
                case (awaddr_latched[4:0])
                    5'h00: begin
                        reg_en   <= s_axi_wdata[0];
                        reg_mode <= s_axi_wdata[1];
                    end
                    5'h04: reg_data   <= s_axi_wdata[15:0];
                    5'h08: reg_bright <= s_axi_wdata[7:0];
                    default: ;
                endcase
            end

            // Complete Write Response Handshake
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_done      <= 1'b0;
                w_done       <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Read Channel
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr[4:0])
                    5'h00: s_axi_rdata <= {30'd0, reg_mode, reg_en};
                    5'h04: s_axi_rdata <= {16'd0, reg_data};
                    5'h08: s_axi_rdata <= {24'd0, reg_bright};
                    5'h0C: s_axi_rdata <= {31'd0, reg_en};
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule

`resetall
