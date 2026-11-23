module processor(

	input clock,

	input reset,

	//these ports are used for serial IO and 
	//must be wired up to the data_memory module

	input [7:0] serial_in,
	input serial_valid_in,
	input serial_ready_in,

	output [7:0] serial_out,
	output serial_rden_out,
	output serial_wren_out

);

// --- Wires to connect components ---
    wire [31:0] pc_out, pc_next, pc_plus4;
    wire [31:0] instruction;
    wire [31:0] read_data1, read_data2;
    wire [31:0] write_data;
    wire [31:0] alu_result;
    wire [31:0] sign_ext_imm;
    wire [31:0] alu_input_b;
    wire [31:0] mem_read_data;
    
    // Control Signals
    wire reg_dst, mem_read, mem_to_reg, mem_write, alu_src, reg_write;
    wire [5:0] alu_func;
    wire [4:0] write_reg_addr;
    wire alu_branch_out, alu_jump_out;

    // ========================================================================
    // 1. INSTRUCTION FETCH
    // ========================================================================
    
    program_counter PC_Unit (
        .clk(clock), .reset(reset),
        .next_pc(pc_next),
        .current_pc(pc_out)
    );

    adder PC_Adder (
        .a(pc_out), .b(32'd4),
        .result(pc_plus4)
    );
    
    assign pc_next = pc_plus4; 

    inst_rom #(
        .INIT_PROGRAM("blank.memh") // Pointing to your blank file
    ) IMEM (
        .clock(clock), .reset(reset),
        .addr_in(pc_next), 
        .data_out(instruction)
    );

    // ========================================================================
    // 2. CONTROL SIGNALS -> Hardwired
    // ========================================================================
    assign reg_dst    = 1'b0;
    assign alu_src    = 1'b0;
    assign reg_write  = 1'b0;
    assign mem_read   = 1'b0;
    assign mem_write  = 1'b0;
    assign mem_to_reg = 1'b0;
    assign alu_func   = 6'b100000;

    // ========================================================================
    // 3. INSTRUCTION DECODE / REGISTER FILE READ
    // ========================================================================
    
    // Mux to select destination register (rt vs rd)
    mux_2input #(.WIDTH(5)) RegDst_Mux (
        .in0(instruction[20:16]), // rt
        .in1(instruction[15:11]), // rd
        .sel(reg_dst),
        .out(write_reg_addr)
    );

    register_file RegFile (
        .clk(clock), .reset(reset),
        .RegWrite_in(reg_write),
        .WriteReg_in(write_reg_addr),
        .WriteData_in(write_data),
        .ReadReg1_in(instruction[25:21]), // rs
        .ReadData1_out(read_data1),
        .ReadReg2_in(instruction[20:16]), // rt
        .ReadData2_out(read_data2)
    );

    sign_extender SignExt (
        .in(instruction[15:0]),
        .out(sign_ext_imm)
    );

    // ========================================================================
    // 4. EXECUTION (ALU)
    // ========================================================================

    // Mux to select ALU input B (Register B vs Immediate)
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

    // ========================================================================
    // 5. MEMORY ACCESS & WRITE BACK
    // ========================================================================

    data_memory #(
        .INIT_PROGRAM0("blank.memh"), .INIT_PROGRAM1("blank.memh"),
        .INIT_PROGRAM2("blank.memh"), .INIT_PROGRAM3("blank.memh")
    ) DMEM (
        .clock(clock), .reset(reset),
        .addr_in(alu_result),
        .writedata_in(read_data2),
        .re_in(mem_read),
        .we_in(mem_write),
        .readdata_out(mem_read_data),
        .size_in(2'b11), // Word size
        // Serial Wiring
        .serial_in(serial_in), .serial_ready_in(serial_ready_in),
        .serial_valid_in(serial_valid_in), .serial_out(serial_out),
        .serial_rden_out(serial_rden_out), .serial_wren_out(serial_wren_out)
    );

    // Mux to select data to write back to register (ALU Result vs Memory)
    mux_2input #(.WIDTH(32)) MemToReg_Mux (
        .in0(alu_result),
        .in1(mem_read_data),
        .sel(mem_to_reg),
        .out(write_data)
    );

endmodule
