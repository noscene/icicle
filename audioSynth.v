`ifndef ZMSYNTH
`define ZMSYNTH

`include "zmSuperSaw.v"
`include "zmPCM5102.v"
`include "zmVCA.v"
`include "zmFilter.v"

`define OSC_PITCH        2'b00
`define OSC_AMP					 2'b01
`define FLT_FRQ				   2'b10
`define FLT_RES				   2'b11


module audiosynth (
    input clk,
    input reset,

    /* I2S */
    output logic I2S_LR,
		output logic I2S_BCLK,
		output logic I2S_DATA,

    /* memory bus */
    input [31:0] address_in,
    input sel_in,
    input read_in,
    output logic [31:0] read_value_out,
    input [3:0] write_mask_in,
    input [31:0] write_value_in,
    output logic ready_out
);


always_ff @(posedge clk) begin
		if (sel_in && write_mask_in[1] && write_mask_in[0]) begin
				case (address_in[3:2])
						`OSC_PITCH: begin	pitch[15:0] <= write_value_in[15:0]; end
						`OSC_AMP: 	begin	vca_level[15:0] <= write_value_in[15:0]; end
						`FLT_FRQ: 	begin	filter_frq[15:0] <= write_value_in[15:0]; end
				endcase
		end
end
assign ready_out = sel_in;
assign read_value_out = 0;
/*
always_comb begin
		if (sel_in) begin
				case (address_in[3:2])
						`OSC_PITCH: begin
								read_value_out = {16'b0,pitch[15:0]};
						end
						default: begin
								read_value_out = 32'bx;
						end
				endcase
		end else begin
				read_value_out = 0;
		end
end
*/

reg [15:0] pitch;
reg [15:0] vca_level;
reg [15:0] filter_frq;

wire [15:0] mysaw;
SUPERSAW ssaw(.clk(I2S_LR),
							.pitch(pitch),
							.audio_out(mysaw) );


wire [15:0] filter_lp_out;
/*
filter_svf16  vcf (
  .clk(I2S_LR),
  .in(mysaw  ),
  // .rst(button_reset),
  .out_lowpass(filter_lp_out),
  //.out_highpass(RDATA_c),
  //.out_bandpass(RDATA_c),
  .F(filter_frq),  // F1: frequency control; fixed point 1.13  ; F = 2sin(π*Fc/Fs).  At a sample rate of 250kHz, F ranges from 0.00050 (10Hz) -> ~0.55 (22kHz)
  .Q1(16'h05ff)   // Q1: Q control;         fixed point 2.12  ; Q1 = 1/Q        Q1 ranges from 2 (Q=0.5) to 0 (Q = infinity).
);
*/


wire  [15:0] vca_out;
VCA vca1( 	  .clk(clk),
      				.vca_in_a(vca_level),
      				.vca_in_b(mysaw),
      				.vca_out(vca_out) );

PCM5102 dac(  .clk(clk),
              .left(vca_out),
              .right(vca_out),
              .din(I2S_DATA),
              .bck(I2S_BCLK),
              .lrck(I2S_LR) );




endmodule

`endif
