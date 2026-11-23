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
	reg_dst		= 1'b0;
	reg_write	= 1'b0;
	alu_src		= 1'b0;
	mem_to_reg	= 1'b0;
	mem_read		= 1'b0;
	mem_write	= 1'b0;
	alu_func		= 6'b000000;
	
		case(opcode)
			6'b000000: begin 								//R-type
				reg_dst		=	1'b1;
				reg_write	=	1'b1;
				case (funct)
					6'b100000 : alu_func = 6'b100000; // ADD
					6'b100010 : alu_func = 6'b100010; // SUB
					6'b100100 : alu_func = 6'b100100; // AND
					6'b100101 : alu_func = 6'b100101; // OR
					6'b100110 : alu_func = 6'b100110; // XOR
					6'b100111 : alu_func = 6'b100111; // NOR
					default:		alu_func = 6'b100000; 
				endcase
			end
			6'b001000: begin								// ADDI
				alu_src		= 1'b1;
				reg_write 	= 1'b1;
				alu_func		= 6'b100000;
			end
			
			6'b100011: begin								// LW
				alu_src		= 1'b1;
				mem_read		= 1'b1;
				mem_to_reg	= 1'b1;
				reg_write	= 1'b1;
				alu_func		= 6'b100000;
			end
			
			6'b101011: begin								// SW
				alu_src		= 1'b1;
				mem_write	= 1'b1;
				alu_func		= 6'b100000;
			end
			
			default: ;
		endcase
	end
endmodule

		