`ifndef BTN_UP5K
`define BTN_UP5K

`define BUTTON_DATA   2'b00

module doppler_buttons (
    input clk,
    input reset,

    /* the Pins -> top -> pcf */
    input button1,
		input button2,

    /* memory bus */
    input [31:0] address_in,
    input sel_in,
    input read_in,
    output logic [31:0] read_value_out,
    input [3:0] write_mask_in,
    input [31:0] write_value_in,
    output logic ready_out
);

assign ready_out = sel_in;

wire b1,b2;

SB_IO #( .PIN_TYPE(6'b 1010_01), .PULLUP(1'b1) )
					btn1 	(
						 .PACKAGE_PIN(button1),
						 .OUTPUT_ENABLE(1'b0),
						 .D_IN_0(b1) );

SB_IO #( .PIN_TYPE(6'b 1010_01), .PULLUP(1'b1) )
 					btn2 	(
 						 .PACKAGE_PIN(button2),
 						 .OUTPUT_ENABLE(1'b0),
 						 .D_IN_0(b2) );

    always_comb begin
        if (sel_in) begin
            case (address_in[3:2])
                `BUTTON_DATA: begin
                    read_value_out = {30'b0, ~b2, ~b1};
                end
                default: begin
                    read_value_out = 32'bx;
                end
            endcase
        end else begin
            read_value_out = 0;
        end
    end

endmodule

`endif
