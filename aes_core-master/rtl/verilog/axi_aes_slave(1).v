`timescale 1ns/1ps

// AXI4-Lite register wrapper for the existing AES-128 cores.
// Existing AES RTL is NOT modified.
//
// Register map:
// 00 CONTROL: bit0 START, bit1 MODE (0=encrypt, 1=decrypt)
// 04 STATUS : bit0 BUSY, bit1 DONE
// 10-1C KEY0..KEY3
// 20-2C DATA_IN0..DATA_IN3
// 30-3C DATA_OUT0..DATA_OUT3
//
// Mapping: AES key = {KEY3,KEY2,KEY1,KEY0}
//          AES input = {IN3,IN2,IN1,IN0}

module axi_aes_slave #(
    parameter ADDR_WIDTH=6,
    parameter DATA_WIDTH=32,
    parameter ID_WIDTH=1
)(
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,

    input wire [ID_WIDTH-1:0] S_AXI_AWID,
    input wire [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [7:0] S_AXI_AWLEN,
    input wire [2:0] S_AXI_AWSIZE,
    input wire [1:0] S_AXI_AWBURST,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,

    input wire [DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input wire S_AXI_WLAST,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,

    output reg [ID_WIDTH-1:0] S_AXI_BID,
    output reg [1:0] S_AXI_BRESP,
    output reg S_AXI_BVALID,
    input wire S_AXI_BREADY,

    input wire [ID_WIDTH-1:0] S_AXI_ARID,
    input wire [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire [7:0] S_AXI_ARLEN,
    input wire [2:0] S_AXI_ARSIZE,
    input wire [1:0] S_AXI_ARBURST,
    input wire S_AXI_ARVALID,
    output reg S_AXI_ARREADY,

    output reg [ID_WIDTH-1:0] S_AXI_RID,
    output reg [DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0] S_AXI_RRESP,
    output reg S_AXI_RLAST,
    output reg S_AXI_RVALID,
    input wire S_AXI_RREADY
);

localparam [5:0] A_CONTROL=6'h00, A_STATUS=6'h04;
localparam [5:0] A_KEY0=6'h10, A_KEY1=6'h14, A_KEY2=6'h18, A_KEY3=6'h1C;
localparam [5:0] A_IN0=6'h20, A_IN1=6'h24, A_IN2=6'h28, A_IN3=6'h2C;
localparam [5:0] A_OUT0=6'h30, A_OUT1=6'h34, A_OUT2=6'h38, A_OUT3=6'h3C;

localparam [2:0] IDLE=3'd0, ENC_RUN=3'd1, DEC_KEY=3'd2,
                 DEC_RUN=3'd3;

reg [2:0] state;
reg [3:0] dec_count;

reg [31:0] key0,key1,key2,key3;
reg [31:0] in0,in1,in2,in3;
reg mode_reg,busy_reg,done_reg;

reg aes_ld,aes_kld;

reg aw_pending,w_pending;
reg [ID_WIDTH-1:0] awid_reg;
reg [ADDR_WIDTH-1:0] awaddr_reg;
reg [DATA_WIDTH-1:0] wdata_reg;
reg [DATA_WIDTH/8-1:0] wstrb_reg;

reg [127:0] result_reg;

wire [127:0] aes_key={key3,key2,key1,key0};
wire [127:0] aes_in={in3,in2,in1,in0};

wire [127:0] enc_out,dec_out;
wire enc_done,dec_done;

assign S_AXI_AWREADY = S_AXI_ARESETN && !aw_pending && !S_AXI_BVALID;
assign S_AXI_WREADY  = S_AXI_ARESETN && !w_pending && !S_AXI_BVALID;

aes_cipher_top u_enc(
 .clk(S_AXI_ACLK), .rst(S_AXI_ARESETN), .ld(aes_ld),
 .done(enc_done), .key(aes_key), .text_in(aes_in), .text_out(enc_out)
);

// IMPORTANT: the original inverse core has a separate internal key-expansion
// completion signal which is not a module output. Therefore the wrapper issues
// kld first, waits the fixed AES-128 key-expansion latency, then issues ld.
aes_inv_cipher_top u_dec(
 .clk(S_AXI_ACLK), .rst(S_AXI_ARESETN), .kld(aes_kld), .ld(aes_ld),
 .done(dec_done), .key(aes_key), .text_in(aes_in), .text_out(dec_out)
);

function [31:0] apply_wstrb;
 input [31:0] old_value,new_value;
 input [3:0] strb;
 integer i;
 begin
  apply_wstrb=old_value;
  for(i=0;i<4;i=i+1)
   if(strb[i]) apply_wstrb[i*8 +: 8]=new_value[i*8 +: 8];
 end
endfunction

always @(posedge S_AXI_ACLK) begin
 if(!S_AXI_ARESETN) begin
  S_AXI_BVALID<=0; S_AXI_BRESP<=0; S_AXI_BID<=0;
  aw_pending<=0; w_pending<=0; awid_reg<=0; awaddr_reg<=0;
  wdata_reg<=0; wstrb_reg<=0;
  key0<=0;key1<=0;key2<=0;key3<=0;
  in0<=0;in1<=0;in2<=0;in3<=0;
  mode_reg<=0;busy_reg<=0;done_reg<=0;
  aes_ld<=0;aes_kld<=0;
  result_reg<=0;state<=IDLE;dec_count<=0;
 end else begin
  aes_ld<=0;
  aes_kld<=0;

  if(S_AXI_BVALID && S_AXI_BREADY) S_AXI_BVALID<=0;

  if(S_AXI_AWVALID && S_AXI_AWREADY) begin
   aw_pending<=1; awid_reg<=S_AXI_AWID; awaddr_reg<=S_AXI_AWADDR;
  end
  if(S_AXI_WVALID && S_AXI_WREADY) begin
   w_pending<=1; wdata_reg<=S_AXI_WDATA; wstrb_reg<=S_AXI_WSTRB;
  end

  if(aw_pending && w_pending && !S_AXI_BVALID) begin
   aw_pending<=0; w_pending<=0;
   S_AXI_BVALID<=1; S_AXI_BID<=awid_reg; S_AXI_BRESP<=2'b00;

   // Register interface supports one 32-bit beat per AXI4-Lite transaction.
   if(S_AXI_AWLEN!=0 || S_AXI_AWBURST!=2'b01) begin
    S_AXI_BRESP<=2'b10;
   end else begin
    case(awaddr_reg)
     A_CONTROL: begin
      if(wstrb_reg[0]) begin
       mode_reg<=wdata_reg[1];
       if(wdata_reg[0] && !busy_reg) begin
        busy_reg<=1; done_reg<=0;
        if(wdata_reg[1]==0) begin
         // Encryption core loads key/data with ld.
         aes_ld<=1;
         state<=ENC_RUN;
        end else begin
         // Inverse core first needs the expanded key.
         aes_kld<=1;
         dec_count<=0;
         state<=DEC_KEY;
        end
       end
      end
     end
     A_KEY0:key0<=apply_wstrb(key0,wdata_reg,wstrb_reg);
     A_KEY1:key1<=apply_wstrb(key1,wdata_reg,wstrb_reg);
     A_KEY2:key2<=apply_wstrb(key2,wdata_reg,wstrb_reg);
     A_KEY3:key3<=apply_wstrb(key3,wdata_reg,wstrb_reg);
     A_IN0:in0<=apply_wstrb(in0,wdata_reg,wstrb_reg);
     A_IN1:in1<=apply_wstrb(in1,wdata_reg,wstrb_reg);
     A_IN2:in2<=apply_wstrb(in2,wdata_reg,wstrb_reg);
     A_IN3:in3<=apply_wstrb(in3,wdata_reg,wstrb_reg);
     default:S_AXI_BRESP<=2'b10;
    endcase
   end
  end

  case(state)
   IDLE: begin end

   ENC_RUN: begin
    if(enc_done) begin
     result_reg<=enc_out;
     busy_reg<=0; done_reg<=1; state<=IDLE;
    end
   end

   DEC_KEY: begin
    // aes_inv_cipher_top starts key expansion when kld is asserted.
    // Its internal key buffer has 11 AES-128 round-key entries.
    // Wait for the key expansion to finish, then issue ld.
    if(dec_count==4'd11) begin
     aes_ld<=1;
     state<=DEC_RUN;
    end else begin
     dec_count<=dec_count+1'b1;
    end
   end

   DEC_RUN: begin
    if(dec_done) begin
     result_reg<=dec_out;
     busy_reg<=0; done_reg<=1; state<=IDLE;
    end
   end

   default: state<=IDLE;
  endcase
 end
end

always @(posedge S_AXI_ACLK) begin
 if(!S_AXI_ARESETN) begin
  S_AXI_ARREADY<=0; S_AXI_RID<=0; S_AXI_RDATA<=0;
  S_AXI_RRESP<=0; S_AXI_RLAST<=0; S_AXI_RVALID<=0;
 end else begin
  S_AXI_ARREADY<=!S_AXI_RVALID;
  if(S_AXI_RVALID && S_AXI_RREADY) S_AXI_RVALID<=0;

  if(S_AXI_ARVALID && S_AXI_ARREADY) begin
   S_AXI_RID<=S_AXI_ARID; S_AXI_RLAST<=1; S_AXI_RVALID<=1;
   S_AXI_RRESP<=2'b00;

   if(S_AXI_ARLEN!=0 || S_AXI_ARBURST!=2'b01) begin
    S_AXI_RRESP<=2'b10; S_AXI_RDATA<=0;
   end else begin
    case(S_AXI_ARADDR)
     A_CONTROL:S_AXI_RDATA<={30'b0,mode_reg,1'b0};
     A_STATUS:S_AXI_RDATA<={30'b0,done_reg,busy_reg};
     A_KEY0:S_AXI_RDATA<=key0; A_KEY1:S_AXI_RDATA<=key1;
     A_KEY2:S_AXI_RDATA<=key2; A_KEY3:S_AXI_RDATA<=key3;
     A_IN0:S_AXI_RDATA<=in0; A_IN1:S_AXI_RDATA<=in1;
     A_IN2:S_AXI_RDATA<=in2; A_IN3:S_AXI_RDATA<=in3;
     A_OUT0:S_AXI_RDATA<=result_reg[31:0];
     A_OUT1:S_AXI_RDATA<=result_reg[63:32];
     A_OUT2:S_AXI_RDATA<=result_reg[95:64];
     A_OUT3:S_AXI_RDATA<=result_reg[127:96];
     default:begin S_AXI_RDATA<=0; S_AXI_RRESP<=2'b10; end
    endcase
   end
  end
 end
end

endmodule
