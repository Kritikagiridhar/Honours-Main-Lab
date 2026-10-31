// =============================================================================
// Module      : sync_fifo.sv
// Description : Generic Synchronous FIFO buffer with programmable flags
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module sync_fifo #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH      = 64,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                  clk,
    input  wire                  rst_n,
    
    // Write interface
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output wire                  full,
    output reg                   overflow,
    
    // Read interface
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout,
    output wire                  empty,
    output reg                   underflow,
    
    // Occupancy status
    output reg  [ADDR_WIDTH:0]   count
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr    <= {ADDR_WIDTH{1'b0}};
            rd_ptr    <= {ADDR_WIDTH{1'b0}};
            count     <= {(ADDR_WIDTH+1){1'b0}};
            overflow  <= 1'b0;
            underflow <= 1'b0;
            dout      <= {DATA_WIDTH{1'b0}};
        end else begin
            overflow  <= 1'b0;
            underflow <= 1'b0;

            // Simultaneous Read and Write
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin // Write only
                    mem[wr_ptr] <= din;
                    wr_ptr      <= wr_ptr + 1'b1;
                    count       <= count + 1'b1;
                end
                2'b01: begin // Read only
                    dout        <= mem[rd_ptr];
                    rd_ptr      <= rd_ptr + 1'b1;
                    count       <= count - 1'b1;
                end
                2'b11: begin // Simultaneous read and write
                    mem[wr_ptr] <= din;
                    dout        <= mem[rd_ptr];
                    wr_ptr      <= wr_ptr + 1'b1;
                    rd_ptr      <= rd_ptr + 1'b1;
                end
                default: ;
            endcase

            // Error conditions
            if (wr_en && full) begin
                overflow <= 1'b1;
            end
            if (rd_en && empty) begin
                underflow <= 1'b1;
            end
        end
    end

endmodule
