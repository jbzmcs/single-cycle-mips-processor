module control(
	input [5:0] opcode,
	input [5:0] funct,
	output reg reg_dst,
	output reg alu_src,
	output reg mem_to_reg,
	output reg reg_write,
	output reg mem_read,
	output reg mem_write,
	output reg [5:0] alu_func
);

	always @(*) begin
	// default safe values
	reg_dst		= 0;
	alu_src		= 0;
	mem_to_reg	= 0;
	mem_read		= 0;
	mem_write	= 0;
	alu_func		= 6'b000000;
	
		case(opcode)
			6'b000000: begin //R-type
				reg_dst		= 1;
				reg_write	= 1;
				alu_func		= funct;
			end
			6'b001000: begin // ADDI
				alu_src 		= 1;
				reg_write	= 1;
				alu_func		= 6'b100000;
			end
			6'b100011: begin // LW
				alu_src		= 1;
				mem_write	= 1;
				alu_func		= 6'b100000;
			end
		endcase
	end
endmodule

		