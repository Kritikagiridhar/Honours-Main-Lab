// =============================================================================
// Module      : cdc_sync.sv
// Description : Clock Domain Crossing (CDC) synchronization primitives
// Modules     : 
//   1. cdc_sync_bit   - Multi-stage flip-flop synchronizer for 1-bit signals
//   2. cdc_sync_pulse - Fast-to-slow / slow-to-fast pulse synchronizer
//   3. cdc_sync_bus   - Handshake-based multi-bit bus synchronizer
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

// -----------------------------------------------------------------------------
// 1. Bit Synchronizer (Double / Triple Flip-Flop)
// -----------------------------------------------------------------------------
module cdc_sync_bit #(
    parameter STAGES = 2,
    parameter INIT   = 1'b0
)(
    input  wire clk_dst,
    input  wire rst_dst_n,
    input  wire sig_in,
    output wire sig_out
);
    (* ASYNC_REG = "TRUE" *) reg [STAGES-1:0] sync_reg;

    always @(posedge clk_dst or negedge rst_dst_n) begin
        if (!rst_dst_n) begin
            sync_reg <= {STAGES{INIT}};
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], sig_in};
        end
    end

    assign sig_out = sync_reg[STAGES-1];

endmodule

// -----------------------------------------------------------------------------
// 2. Pulse Synchronizer (Toggle-based CDC Pulse Transfer)
// -----------------------------------------------------------------------------
module cdc_sync_pulse (
    input  wire clk_src,
    input  wire rst_src_n,
    input  wire pulse_in,
    input  wire clk_dst,
    input  wire rst_dst_n,
    output wire pulse_out
);
    reg src_toggle;
    wire dst_toggle;
    reg dst_toggle_d;

    // Toggle generation in source domain
    always @(posedge clk_src or negedge rst_src_n) begin
        if (!rst_src_n) begin
            src_toggle <= 1'b0;
        end else if (pulse_in) begin
            src_toggle <= ~src_toggle;
        end
    end

    // 2-stage synchronization in destination domain
    cdc_sync_bit #(
        .STAGES(2),
        .INIT(1'b0)
    ) u_bit_sync (
        .clk_dst(clk_dst),
        .rst_dst_n(rst_dst_n),
        .sig_in(src_toggle),
        .sig_out(dst_toggle)
    );

    // Edge detect in destination domain
    always @(posedge clk_dst or negedge rst_dst_n) begin
        if (!rst_dst_n) begin
            dst_toggle_d <= 1'b0;
        end else begin
            dst_toggle_d <= dst_toggle;
        end
    end

    assign pulse_out = dst_toggle ^ dst_toggle_d;

endmodule

// -----------------------------------------------------------------------------
// 3. Multi-bit Bus Synchronizer with Level Handshaking
// -----------------------------------------------------------------------------
module cdc_sync_bus #(
    parameter WIDTH = 16
)(
    input  wire             clk_src,
    input  wire             rst_src_n,
    input  wire [WIDTH-1:0] data_src,
    input  wire             valid_src,
    output wire             ready_src,

    input  wire             clk_dst,
    input  wire             rst_dst_n,
    output reg  [WIDTH-1:0] data_dst,
    output wire             valid_dst
);
    reg [WIDTH-1:0] src_data_hold;
    reg             src_req;
    wire            dst_req;
    wire            src_ack;
    reg             dst_ack;

    // Source domain
    always @(posedge clk_src or negedge rst_src_n) begin
        if (!rst_src_n) begin
            src_req       <= 1'b0;
            src_data_hold <= {WIDTH{1'b0}};
        end else begin
            if (valid_src && !src_req && !src_ack) begin
                src_req       <= 1'b1;
                src_data_hold <= data_src;
            end else if (src_req && src_ack) begin
                src_req       <= 1'b0;
            end
        end
    end

    assign ready_src = !src_req && !src_ack;

    // Synchronize req to dst
    cdc_sync_bit #(.STAGES(2)) u_sync_req (
        .clk_dst(clk_dst),
        .rst_dst_n(rst_dst_n),
        .sig_in(src_req),
        .sig_out(dst_req)
    );

    // Destination domain
    always @(posedge clk_dst or negedge rst_dst_n) begin
        if (!rst_dst_n) begin
            dst_ack  <= 1'b0;
            data_dst <= {WIDTH{1'b0}};
        end else begin
            if (dst_req && !dst_ack) begin
                data_dst <= src_data_hold;
                dst_ack  <= 1'b1;
            end else if (!dst_req && dst_ack) begin
                dst_ack  <= 1'b0;
            end
        end
    end

    assign valid_dst = dst_req && !dst_ack;

    // Synchronize ack back to src
    cdc_sync_bit #(.STAGES(2)) u_sync_ack (
        .clk_dst(clk_src),
        .rst_dst_n(rst_src_n),
        .sig_in(dst_ack),
        .sig_out(src_ack)
    );

endmodule
