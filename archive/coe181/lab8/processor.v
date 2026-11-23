module processor(
    input clock,
    input reset,
    // Serial I/O (unused in Lab 7 but data_memory expects them)
    input  [7:0] serial_in,
    input        serial_valid_in,
    input        serial_ready_in,
    output [7:0] serial_out,
    output       serial_rden_out,
    output       serial_wren_out
);

	// --- Wires ---
    wire [31:0] pc_out, pc_next, pc_plus4, instruction;
    wire [31:0] read_data1, read_data2, write_data;
    wire [31:0] sign_ext_imm, alu_input_b, alu_result;
    wire [31:0] mem_read_data;
    wire [4:0]  write_reg_addr;
	 
	 // --- Control signals ---
    wire reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write;
    wire [5:0] alu_func;
    wire alu_branch_out, alu_jump_out; 
	 
	 // --- 1. FETCH ---
    assign pc_next = pc_plus4;  // Lab 7: no branches/jumps yet
    program_counter PC_Unit (
        .clk(clock), .reset(reset),
        .next_pc(pc_next), .current_pc(pc_out)
    );
    adder PC_Adder (.a(pc_out), .b(32'd4), .result(pc_plus4));

    inst_rom #(
//      .INIT_PROGRAM("C:/intelFPGA_lite/18.1/coe181/lab8/lab7-test.inst_rom.memh")
        .INIT_PROGRAM("C:/intelFPGA_lite/18.1/coe181/lab8/nbhelloworld.inst_rom.memh")
    ) IMEM (
        .clock(clock), .reset(reset),
        .addr_in(pc_next), .data_out(instruction)
    );

    // --- 2. CONTROL ---
    control Control (
        .opcode(instruction[31:26]),
        .funct(instruction[5:0]),
        .reg_dst(reg_dst), 
		  .alu_src(alu_src),
		  .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
		  .mem_read(mem_read),
		  .mem_write(mem_write),
        .alu_func(alu_func)
    );

    // --- 3. DECODE / REG FILE ---
    mux_2input #(.WIDTH(5)) RegDst_Mux (
        .in0(instruction[20:16]),  // rt
        .in1(instruction[15:11]),  // rd
        .sel(reg_dst),
        .out(write_reg_addr)
    );

    register_file RegFile (
        .clk(clock), .reset(reset),
        .RegWrite_in(reg_write),
        .WriteReg_in(write_reg_addr), 
		  .WriteData_in(write_data),
        .ReadReg1_in(instruction[25:21]), 
		  .ReadData1_out(read_data1),
        .ReadReg2_in(instruction[20:16]), 
		  .ReadData2_out(read_data2)
    );

    sign_extender SignExt (.in(instruction[15:0]), .out(sign_ext_imm));

    // --- 4. EXECUTE ---
    mux_2input #(.WIDTH(32)) ALUSrc_Mux (
        .in0(read_data2), 
		  .in1(sign_ext_imm),
        .sel(alu_src), 
		  .out(alu_input_b)
    );

    alu ALU (
        .Func_in(alu_func),
        .A_in(read_data1), 
		  .B_in(alu_input_b),
        .O_out(alu_result),
        .Branch_out(alu_branch_out), 
		  .Jump_out(alu_jump_out)
    );

    // --- 5. MEMORY ---
    data_memory #(
//      .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/coe181/lab8/lab7-test.data_ram0.memh"),
//      .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/coe181/lab8/lab7-test.data_ram1.memh"),
//      .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/coe181/lab8/lab7-test.data_ram2.memh"),
//      .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/coe181/lab8/lab7-test.data_ram3.memh")
        .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/coe181/lab8/nbhelloworld.data_ram0.memh"),
        .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/coe181/lab8/nbhelloworld.data_ram1.memh"),
        .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/coe181/lab8/nbhelloworld.data_ram2.memh"),
        .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/coe181/lab8/nbhelloworld.data_ram3.memh")
    ) DMEM (
        .clock(clock), .reset(reset),
        .addr_in(alu_result), 
		  .writedata_in(read_data2),
        .re_in(mem_read), 
		  .we_in(mem_write),
        .size_in(2'b11),  // Word access for Lab 7
        .readdata_out(mem_read_data),
        .serial_in(serial_in), 
		  .serial_valid_in(serial_valid_in), 
		  .serial_ready_in(serial_ready_in),
        .serial_out(serial_out), 
		  .serial_rden_out(serial_rden_out), 
		  .serial_wren_out(serial_wren_out)
    );

    // --- 6. WRITE-BACK ---
    mux_2input #(.WIDTH(32)) WB_Mux (
        .in0(alu_result), .in1(mem_read_data),
        .sel(mem_to_reg), .out(write_data)
    );

endmodule