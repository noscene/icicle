`ifndef SPI_SLAVE
`define SPI_SLAVE

`define SPI_DATA			   2'b00
`define SPI_STATUS		   2'b01

module spi_slave (
    input clk,
	//	input clk_cpu,
    input reset,

    /* spi slave port */
    input pin_mosi, pin_clk, pin_cs,
    output logic pin_miso,

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
	reg [15:0] data_from_spi = 0;
	reg [15:0] data_to_spi	 = 0;

	always_comb begin
			if (sel_in) begin
					case (address_in[3:2])
							`SPI_DATA: begin
									read_value_out = {16'b0, data_from_spi};
							end
							`SPI_STATUS: begin
									read_value_out = {31'b0, pin_cs};
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
							`SPI_DATA: begin
									if (write_mask_in[1] && write_mask_in[0])
											data_to_spi <= write_value_in[15:8];
							end
					endcase
			end
	end

	// see this https://youtu.be/IOmG5y7VMrg?t=49m32s (german only)
	// Cross Domain Clock Syncing! SPI_INCOMING_CLK
	reg spi_clk1,spi_clk2;
	wire spi_clk_negedge = ( ~spi_clk1 &&  spi_clk2)  ;
	wire spi_clk_posedge = (  spi_clk1 && ~spi_clk2)  ;
	always @(posedge clk) begin
		spi_clk1 <= pin_clk;
		spi_clk2 <= spi_clk1;
	end

	// Cross Domain Clock Syncing! SPI_INCOMING_CS + register Set
	reg spi_cs1,spi_cs2;
	wire spi_cs_negedge = ( ~spi_cs1 &&  spi_cs2)  ;
	wire spi_cs_posedge = (  spi_cs1 && ~spi_cs2)  ;
	always @(posedge clk) begin
		spi_cs1 <= pin_cs;
		spi_cs2 <= spi_cs1;
	end /*
	reg cs;
	always @(posedge clk) begin
		if(spi_cs_posedge)				cs<= 1'b1;
		else if(spi_cs_negedge)		cs<= 1'b0;
	end
	*/

	// Cross Domain Clock Syncing! SPI_INCOMING_MOSI + register Set
	reg spi_mosi1,spi_mosi2;
	wire spi_mosi_negedge = ( ~spi_mosi1 &&  spi_mosi2)  ;
	wire spi_mosi_posedge = (  spi_mosi1 && ~spi_mosi2)  ;
	always @(posedge clk) begin
		spi_mosi1 <= pin_mosi;
		spi_mosi2 <= spi_mosi1;
	end
	reg mosi;
	always @(posedge clk) begin
		if(spi_mosi_posedge)				mosi<= 1'b1;
		else if(spi_mosi_negedge)		mosi<= 1'b0;
	end

	// Spi Shifter
	reg [15:0]		spi_in;
	reg [15:0]		miso_shift;
	assign pin_miso = miso_shift[15];
	always @(posedge clk) begin
		if(spi_cs_posedge) begin
			data_from_spi 			<= spi_in;
		end else if(spi_cs_negedge) begin
			miso_shift 	<= data_to_spi;
		end else begin
			if(spi_clk_posedge)		spi_in[15:0] 			<= {spi_in[14:0] , 			mosi};
			if(spi_clk_posedge)		miso_shift[15:0] 	<= {miso_shift[14:0] , 	1'b1};
		end
	end


endmodule
