`ifndef GPIO_UP5K
`define GPIO_UP5K

`define GPIO_DIR   2'b00
`define GPIO_DATA  2'b01

module gpio_up5k (
    input clk,
    input reset,

    /* the Pins -> top -> pcf */
    inout [7:0] hardware_pins,

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

logic [7:0]	port_dir;
wire  [7:0]	out_value;
wire  [7:0]	in_value;

// define  8 SB_IO in a single block on Doppler Hardware Pins F0....F7
// see this https://stackoverflow.com/questions/33899691/instantiate-modules-in-generate-for-loop-in-verilog
/*
	https://github.com/YosysHQ/arachne-pnr/issues/64
	When a PLL is enabled then the two IO pins on the corresponding IO block can only be used as PLL inputs or output-only.
	(That's why those pins are used for the LEDs on the IcoBoard: LEDs are inherently output-only.) This is the issue discussed on the mystorm forum.
*/
SB_IO #( .PIN_TYPE(6'b 1010_01), .PULLUP(1'b1) )
					upin_4[7:0] 	(
						 .PACKAGE_PIN(hardware_pins),
						 .OUTPUT_ENABLE(port_dir),
						 .D_OUT_0(out_value) ,
						 .D_IN_0(in_value) );

    always_comb begin
        if (sel_in) begin
            case (address_in[3:2])
                `GPIO_DIR: begin
                    read_value_out = {24'b0, port_dir};
                end
                `GPIO_DATA: begin
										read_value_out = {24'b0, in_value};
                end
                default: begin
                    read_value_out = 32'bx;
                end
            endcase
        end else begin
            read_value_out = 0;
        end
    end

    always_ff @(posedge clk) begin
        if (sel_in) begin
            case (address_in[3:2])
                `GPIO_DIR: begin
								//		if (write_mask_in[3])
								//				port_dir[23:16]  <= write_value_in[23:16];
                //    if (write_mask_in[1])
                //        port_dir[15:8] <= write_value_in[15:8];
                    if (write_mask_in[0])
                        port_dir[7:0]  <= write_value_in[7:0];
                end
                `GPIO_DATA: begin
								//		if (write_mask_in[3])
								//				port_dir[23:16]  <= write_value_in[23:16];
								//		if (write_mask_in[1])
								//				port_dir[15:8] <= write_value_in[15:8];
										if (write_mask_in[0])
												out_value[7:0]  <= write_value_in[7:0];
                end
            endcase
        end
    end


endmodule

`endif
