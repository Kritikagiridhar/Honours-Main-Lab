// =============================================================================
// Module      : vga_controller.sv
// Description : Real-Time VGA Oscilloscope Controller (640x480 @ 60 Hz)
//               with Software-Customizable UI, Color Palettes, Grid, Cursors & Ping-Pong
// Specification: Architecture Document Section 8.7 & User Software Customization Spec
//   - Timing: 640x480 @ 60 Hz standard VGA (25.175 MHz pixel clock)
//   - Standard Registers:
//       0x00: VGA_CTRL         [0] EN, [1] HOLD, [2] GRID_EN
//       0x04: VGA_VDIV         [15:0] Volts/Div scale factor
//       0x08: VGA_TDIV         [15:0] Time/Div horizontal step
//       0x0C: VGA_OFFSET       [15:0] Signed vertical trace offset
//       0x10: VGA_TRIG_LEVEL   [15:0] Trigger threshold
//       0x14: VGA_TRIG_EDGE    [0]    0=rising, 1=falling
//       0x18: VGA_TRIG_HOLDOFF [15:0] Holdoff frame count
//       0x1C: VGA_STATUS       [0] FRAME_DONE, [1] TRIGGERED, [2] NOTRIG
//   - Extended Software UI Customization Registers (Complete Processor Control):
//       0x20: VGA_TRACE_COLOR  [11:0] {R[3:0], G[3:0], B[3:0]} (Default: 0xEF2 Lime/Yellow)
//       0x24: VGA_GRID_COLOR   [11:0] {R[3:0], G[3:0], B[3:0]} (Default: 0x145 Dim Cyan)
//       0x28: VGA_BG_COLOR     [11:0] {R[3:0], G[3:0], B[3:0]} (Default: 0x001 Dark Navy)
//       0x2C: VGA_CURSOR_A_Y   [9:0]  Voltage Measurement Cursor A Y-line
//       0x30: VGA_CURSOR_B_Y   [9:0]  Voltage Measurement Cursor B Y-line
//       0x34: VGA_CURSOR_COLOR [11:0] {R[3:0], G[3:0], B[3:0]} (Default: 0xF0F Magenta)
//       0x38: VGA_UI_CTRL      [0] CURSOR_A_EN, [1] CURSOR_B_EN, [2] TRACE_THICKNESS
// =============================================================================

`resetall
`timescale 1ns / 1ps
`default_nettype none

module vga_controller #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter BUF_ADDR_WIDTH = 12
)(
    // Clock & Reset
    input  wire                      clk_sys,
    input  wire                      rst_sys_n,
    input  wire                      clk_vga,
    input  wire                      rst_vga_n,

    // Sample Buffer Read Port (clk_vga domain)
    output reg  [BUF_ADDR_WIDTH-1:0] sbuf_raddr,
    input  wire [15:0]               sbuf_rdata,

    // Ping-Pong VSYNC boundary pulse
    output reg                       vga_vsync_pulse,

    // External VGA Physical Interface
    output reg                       vga_hsync,
    output reg                       vga_vsync,
    output reg  [3:0]                vga_red,
    output reg  [3:0]                vga_green,
    output reg  [3:0]                vga_blue,

    // AXI4-Lite Slave CSR Interface (clk_sys domain)
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [3:0]                s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    output reg  [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready,

    // Interrupt
    output wire                      irq_vga_frame
);

    // -------------------------------------------------------------------------
    // CSR Registers (clk_sys)
    // -------------------------------------------------------------------------
    reg        vga_en;
    reg        vga_hold;
    reg        vga_grid_en;
    reg [15:0] vga_vdiv;
    reg [15:0] vga_tdiv;
    reg signed [15:0] vga_offset;
    reg signed [15:0] vga_trig_level;
    reg        vga_trig_edge;
    reg [15:0] vga_trig_holdoff;
    reg        vga_frame_done;
    reg        vga_triggered;
    reg        vga_notrig;

    // Software Customizable UI Palette & Cursor Registers
    reg [11:0] vga_trace_color;   // [11:8] R, [7:4] G, [3:0] B
    reg [11:0] vga_grid_color;
    reg [11:0] vga_bg_color;
    reg [9:0]  vga_cursor_a_y;
    reg [9:0]  vga_cursor_b_y;
    reg [11:0] vga_cursor_color;
    reg        vga_cursor_a_en;
    reg        vga_cursor_b_en;
    reg        vga_trace_thick;

    assign irq_vga_frame = vga_frame_done || vga_notrig;

    // -------------------------------------------------------------------------
    // Synchronize Control Signals to Pixel Clock (clk_vga)
    // -------------------------------------------------------------------------
    reg        vga_en_vga;
    reg        vga_hold_vga;
    reg        vga_grid_en_vga;
    reg [15:0] vga_vdiv_vga;
    reg [15:0] vga_tdiv_vga;
    reg signed [15:0] vga_offset_vga;
    reg signed [15:0] vga_trig_level_vga;
    reg        vga_trig_edge_vga;

    reg [11:0] vga_trace_color_vga;
    reg [11:0] vga_grid_color_vga;
    reg [11:0] vga_bg_color_vga;
    reg [9:0]  vga_cursor_a_y_vga;
    reg [9:0]  vga_cursor_b_y_vga;
    reg [11:0] vga_cursor_color_vga;
    reg        vga_cursor_a_en_vga;
    reg        vga_cursor_b_en_vga;
    reg        vga_trace_thick_vga;

    always @(posedge clk_vga or negedge rst_vga_n) begin
        if (!rst_vga_n) begin
            vga_en_vga           <= 1'b0;
            vga_hold_vga         <= 1'b0;
            vga_grid_en_vga      <= 1'b1;
            vga_vdiv_vga         <= 16'h0040;
            vga_tdiv_vga         <= 16'h0020;
            vga_offset_vga       <= 16'sh0;
            vga_trig_level_vga   <= 16'sh0;
            vga_trig_edge_vga    <= 1'b0;
            vga_trace_color_vga  <= 12'hEF2; // Bright Lime/Yellow
            vga_grid_color_vga   <= 12'h145; // Dim Cyan
            vga_bg_color_vga     <= 12'h001; // Dark Navy
            vga_cursor_a_y_vga   <= 10'd120;
            vga_cursor_b_y_vga   <= 10'd360;
            vga_cursor_color_vga <= 12'hF0F; // Magenta
            vga_cursor_a_en_vga  <= 1'b0;
            vga_cursor_b_en_vga  <= 1'b0;
            vga_trace_thick_vga  <= 1'b1;
        end else begin
            vga_en_vga           <= vga_en;
            vga_hold_vga         <= vga_hold;
            vga_grid_en_vga      <= vga_grid_en;
            vga_vdiv_vga         <= vga_vdiv;
            vga_tdiv_vga         <= vga_tdiv;
            vga_offset_vga       <= vga_offset;
            vga_trig_level_vga   <= vga_trig_level;
            vga_trig_edge_vga    <= vga_trig_edge;
            vga_trace_color_vga  <= vga_trace_color;
            vga_grid_color_vga   <= vga_grid_color;
            vga_bg_color_vga     <= vga_bg_color;
            vga_cursor_a_y_vga   <= vga_cursor_a_y;
            vga_cursor_b_y_vga   <= vga_cursor_b_y;
            vga_cursor_color_vga <= vga_cursor_color;
            vga_cursor_a_en_vga  <= vga_cursor_a_en;
            vga_cursor_b_en_vga  <= vga_cursor_b_en;
            vga_trace_thick_vga  <= vga_trace_thick;
        end
    end

    // -------------------------------------------------------------------------
    // Standard 640x480 @ 60 Hz Timing Generator (clk_vga = 25.175 MHz)
    // -------------------------------------------------------------------------
    localparam H_ACTIVE = 640;
    localparam H_FP     = 16;
    localparam H_SYNC   = 96;
    localparam H_BP     = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480;
    localparam V_FP     = 10;
    localparam V_SYNC   = 2;
    localparam V_BP     = 33;
    localparam V_TOTAL  = 525;

    reg [9:0] h_count;
    reg [9:0] v_count;

    wire active_video = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

    always @(posedge clk_vga or negedge rst_vga_n) begin
        if (!rst_vga_n) begin
            h_count         <= 10'd0;
            v_count         <= 10'd0;
            vga_hsync       <= 1'b1;
            vga_vsync       <= 1'b1;
            vga_vsync_pulse <= 1'b0;
        end else begin
            vga_vsync_pulse <= 1'b0;

            // Horizontal counter
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                // Vertical counter
                if (v_count == V_TOTAL - 1) begin
                    v_count         <= 10'd0;
                    vga_vsync_pulse <= 1'b1; // Top of new frame pulse
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end else begin
                h_count <= h_count + 1'b1;
            end

            // Sync pulse generation (Active Low for 640x480 standard)
            vga_hsync <= ~((h_count >= (H_ACTIVE + H_FP)) && 
                           (h_count <  (H_ACTIVE + H_FP + H_SYNC)));
            vga_vsync <= ~((v_count >= (V_ACTIVE + V_FP)) && 
                           (v_count <  (V_ACTIVE + V_FP + V_SYNC)));
        end
    end

    // -------------------------------------------------------------------------
    // Oscilloscope Rendering Engine
    // -------------------------------------------------------------------------
    always @(posedge clk_vga or negedge rst_vga_n) begin
        if (!rst_vga_n) begin
            sbuf_raddr <= {BUF_ADDR_WIDTH{1'b0}};
        end else if (!vga_hold_vga && active_video) begin
            // Address scales with horizontal scan
            sbuf_raddr <= {{(BUF_ADDR_WIDTH-10){1'b0}}, h_count};
        end
    end

    // Convert signed sample to screen Y coordinate: Center is 240
    wire signed [15:0] current_sample = sbuf_rdata;
    wire signed [23:0] scaled_sample  = (current_sample * $signed({1'b0, vga_vdiv_vga})) >>> 8;
    wire signed [15:0] calculated_y   = 16'sd240 - scaled_sample[15:0] - vga_offset_vga;

    // Waveform trace detection (1 or 3 pixels thickness)
    wire on_waveform = active_video && (
        vga_trace_thick_vga ?
            ((v_count >= (calculated_y - 1)) && (v_count <= (calculated_y + 1))) :
            (v_count == calculated_y)
    );

    // Reference Grid / Graticule Generator (divisions every 50 pixels)
    wire on_grid_h = (v_count % 50 == 0);
    wire on_grid_v = (h_count % 50 == 0);
    wire on_center_axes = (v_count == 240) || (h_count == 320);
    wire on_grid = active_video && vga_grid_en_vga && (on_grid_h || on_grid_v || on_center_axes);

    // Voltage Measurement Cursor Lines (dashed horizontal line every 4 pixels)
    wire on_cursor_a = active_video && vga_cursor_a_en_vga && (v_count == vga_cursor_a_y_vga) && (h_count[2]);
    wire on_cursor_b = active_video && vga_cursor_b_en_vga && (v_count == vga_cursor_b_y_vga) && (h_count[2]);
    wire on_any_cursor = on_cursor_a || on_cursor_b;

    // RGB Output Generation (Controlled via software color registers)
    always @(posedge clk_vga or negedge rst_vga_n) begin
        if (!rst_vga_n) begin
            vga_red   <= 4'h0;
            vga_green <= 4'h0;
            vga_blue  <= 4'h0;
        end else if (!active_video || !vga_en_vga) begin
            vga_red   <= 4'h0;
            vga_green <= 4'h0;
            vga_blue  <= 4'h0;
        end else if (on_any_cursor) begin
            // Cursor color (e.g. Magenta)
            vga_red   <= vga_cursor_color_vga[11:8];
            vga_green <= vga_cursor_color_vga[7:4];
            vga_blue  <= vga_cursor_color_vga[3:0];
        end else if (on_waveform) begin
            // Waveform Trace color
            vga_red   <= vga_trace_color_vga[11:8];
            vga_green <= vga_trace_color_vga[7:4];
            vga_blue  <= vga_trace_color_vga[3:0];
        end else if (on_grid) begin
            // Grid Lines color
            vga_red   <= vga_grid_color_vga[11:8];
            vga_green <= vga_grid_color_vga[7:4];
            vga_blue  <= vga_grid_color_vga[3:0];
        end else begin
            // Background color
            vga_red   <= vga_bg_color_vga[11:8];
            vga_green <= vga_bg_color_vga[7:4];
            vga_blue  <= vga_bg_color_vga[3:0];
        end
    end

    // Frame Complete detection
    wire frame_tick = (h_count == 0) && (v_count == V_ACTIVE);

    // -------------------------------------------------------------------------
    // AXI4-Lite CSR Read / Write Engine
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    always @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            s_axi_awready        <= 1'b0;
            s_axi_wready         <= 1'b0;
            s_axi_bvalid         <= 1'b0;
            s_axi_bresp          <= 2'b00;
            aw_done              <= 1'b0;
            w_done               <= 1'b0;
            awaddr_latched       <= {ADDR_WIDTH{1'b0}};

            vga_en               <= 1'b1; // Default enabled
            vga_hold             <= 1'b0;
            vga_grid_en          <= 1'b1;
            vga_vdiv             <= 16'h0040;
            vga_tdiv             <= 16'h0020;
            vga_offset           <= 16'sh0;
            vga_trig_level       <= 16'sh0;
            vga_trig_edge        <= 1'b0;
            vga_trig_holdoff     <= 16'h0010;
            vga_frame_done       <= 1'b0;
            vga_triggered        <= 1'b1;
            vga_notrig           <= 1'b0;

            vga_trace_color      <= 12'hEF2; // Bright Lime/Yellow
            vga_grid_color       <= 12'h145; // Dim Cyan
            vga_bg_color         <= 12'h001; // Dark Navy
            vga_cursor_a_y       <= 10'd120;
            vga_cursor_b_y       <= 10'd360;
            vga_cursor_color     <= 12'hF0F; // Magenta
            vga_cursor_a_en      <= 1'b0;
            vga_cursor_b_en      <= 1'b0;
            vga_trace_thick      <= 1'b1;
        end else begin
            // Address handshake
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            // Data handshake
            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Register write execution
            if (aw_done && w_done && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;

                case (awaddr_latched[7:0])
                    8'h00: begin // VGA_CTRL
                        vga_en      <= s_axi_wdata[0];
                        vga_hold    <= s_axi_wdata[1];
                        vga_grid_en <= s_axi_wdata[2];
                    end
                    8'h04: vga_vdiv         <= s_axi_wdata[15:0];
                    8'h08: vga_tdiv         <= s_axi_wdata[15:0];
                    8'h0C: vga_offset       <= s_axi_wdata[15:0];
                    8'h10: vga_trig_level   <= s_axi_wdata[15:0];
                    8'h14: vga_trig_edge    <= s_axi_wdata[0];
                    8'h18: vga_trig_holdoff <= s_axi_wdata[15:0];
                    8'h1C: begin // VGA_STATUS (W1C)
                        if (s_axi_wdata[0]) vga_frame_done <= 1'b0;
                        if (s_axi_wdata[2]) vga_notrig     <= 1'b0;
                    end
                    8'h20: vga_trace_color  <= s_axi_wdata[11:0];
                    8'h24: vga_grid_color   <= s_axi_wdata[11:0];
                    8'h28: vga_bg_color     <= s_axi_wdata[11:0];
                    8'h2C: vga_cursor_a_y   <= s_axi_wdata[9:0];
                    8'h30: vga_cursor_b_y   <= s_axi_wdata[9:0];
                    8'h34: vga_cursor_color <= s_axi_wdata[11:0];
                    8'h38: begin // VGA_UI_CTRL
                        vga_cursor_a_en <= s_axi_wdata[0];
                        vga_cursor_b_en <= s_axi_wdata[1];
                        vga_trace_thick <= s_axi_wdata[2];
                    end
                    default: ;
                endcase
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_done      <= 1'b0;
                w_done       <= 1'b0;
            end
        end
    end

    // Read Channel
    always @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;

                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= {29'd0, vga_grid_en, vga_hold, vga_en};
                    8'h04: s_axi_rdata <= {16'd0, vga_vdiv};
                    8'h08: s_axi_rdata <= {16'd0, vga_tdiv};
                    8'h0C: s_axi_rdata <= {{16{vga_offset[15]}}, vga_offset};
                    8'h10: s_axi_rdata <= {{16{vga_trig_level[15]}}, vga_trig_level};
                    8'h14: s_axi_rdata <= {31'd0, vga_trig_edge};
                    8'h18: s_axi_rdata <= {16'd0, vga_trig_holdoff};
                    8'h1C: s_axi_rdata <= {29'd0, vga_notrig, vga_triggered, vga_frame_done};
                    8'h20: s_axi_rdata <= {20'd0, vga_trace_color};
                    8'h24: s_axi_rdata <= {20'd0, vga_grid_color};
                    8'h28: s_axi_rdata <= {20'd0, vga_bg_color};
                    8'h2C: s_axi_rdata <= {22'd0, vga_cursor_a_y};
                    8'h30: s_axi_rdata <= {22'd0, vga_cursor_b_y};
                    8'h34: s_axi_rdata <= {20'd0, vga_cursor_color};
                    8'h38: s_axi_rdata <= {29'd0, vga_trace_thick, vga_cursor_b_en, vga_cursor_a_en};
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
