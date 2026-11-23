`timescale 1ns / 1ps

module control_tb();
	reg 	[5:0]	opcode, funct;
	wire			reg_dst, alu_src, mem_to_reg;
	wire			reg_write, mem_read, mem_write;
	wire	[5:0]	alu_func;
	
	control dut(
		.opcode(opcode), .funct(funct),
		.reg_dst(reg_dst), .alu_src(alu_src), .mem_to_reg(mem_to_reg),
		.reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
		.alu_func(alu_func)
	);
	
	initial begin
		opcode = 6'b000000; funct = 6'b000000;
		#10 opcode = 6'b100011; funct = 6'b000000; // LW
		#10 opcode = 6'b101011; funct = 6'b000000; // sw
		#10 opcode = 6'b001000; funct = 6'b000000; // ADDI
		#10 opcode = 6'b000000; funct = 6'b100000; // ADD
		#10 opcode = 6'b000000; funct = 6'b100010; // SUB
		#10 opcode = 6'b000000; funct = 6'b100100; // AND
		#10 opcode = 6'b000000; funct = 6'b100101; // OR
		#10 opcode = 6'b000000; funct = 6'b100110; // XOR
		#10 opcode = 6'b000000; funct = 6'b100111; // NOR
		#10 opcode = 6'b111111; funct = 6'b000000; // default - unknown
		#20 $stop;
	end
endmodule


		
		