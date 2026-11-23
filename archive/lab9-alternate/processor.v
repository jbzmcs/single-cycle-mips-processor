module processor(
    input clock,
    input reset,

    // Serial IO ports wired to data_memory
    input  [7:0] serial_in,
    input        serial_valid_in,
    input        serial_ready_in,
    output [7:0] serial_out,
    output       serial_rden_out,
    output       serial_wren_out
);

    // ========================================================================
    // WIRES & SIGNALS
    // ========================================================================
    wire [31:0] pc_out;           // Current PC (output of PC register)
    wire [31:0] pc_next;          // Next PC (input to PC register)
    wire [31:0] pc_plus4;         // PC + 4
    wire [31:0] pc_branch_offset; // Shifted branch offset
    wire [31:0] pc_branch_target; // Branch target address
    wire [31:0] pc_jump_target;   // J/JAL target address
    wire [31:0] instruction;      // Fetched instruction
    wire [1:0]  pc_sel;           // Selects next PC source

    wire [4:0]  rs;
    wire [4:0]  rt;
    wire [4:0]  rd;
    wire [4:0]  shamt;
    wire [15:0] imm16;
    wire [25:0] jump_addr;

    wire [31:0] read_data1;       // rs value from register file
    wire [31:0] read_data2;       // rt value from register file
    wire [31:0] write_data;       // Data to write back to register file
    wire [31:0] alu_result;       // ALU output / memory address
    wire [31:0] sign_ext_imm;     // Sign-extended immediate
    wire [31:0] zero_ext_imm;     // Zero-extended immediate
    wire [31:0] ext_imm;          // Sign/zero selected immediate
    wire [31:0] lui_imm;          // Immediate shifted for LUI
    wire [31:0] final_imm;        // Immediate after LUI selection
    wire [31:0] alu_input_a;      // ALU operand A
    wire [31:0] alu_input_b;      // ALU operand B
    wire        alu_branch_out;   // ALU branch decision
    wire        branch_taken;     // Final branch decision
    wire [31:0] mem_read_data;    // Data read from data memory
    wire [31:0] load_ext_data;    // LB data after byte selection/sign extension
    wire [31:0] final_mem_data;   // Memory data after LW/LB selection
    wire [31:0] alu_or_mem;       // ALU/memory writeback data

    // Control Signals
    wire        mem_read;
    wire        mem_write;
    wire        alu_src;
    wire        reg_write;
    wire        branch;
    wire        jump;
    wire        jump_reg;
    wire        lui;
    wire        zero_extend;
    wire        alu_shift;
    wire        load_extend;
    wire [1:0]  mem_size;
    wire [1:0]  reg_dst;
    wire [1:0]  mem_to_reg;
    wire [5:0]  alu_func;
    wire [4:0]  write_reg_addr;
    wire [4:0]  rt_or_rd;

    // ========================================================================
    // 1. INSTRUCTION FETCH
    // ========================================================================

    program_counter PC_Unit (
        .clk(clock),
        .reset(reset),
        .next_pc(pc_next),
        .current_pc(pc_out)
    );

    adder PC_Adder (
        .a(pc_out),
        .b(32'd4),
        .result(pc_plus4)
    );

    shift_left_2 #(.WIDTH(32)) Branch_Shift_Left_2 (
        .in(sign_ext_imm),
        .out(pc_branch_offset)
    );

    adder Branch_Adder (
        .a(pc_plus4),
        .b(pc_branch_offset),
        .result(pc_branch_target)
    );

    assign pc_jump_target = {pc_plus4[31:28], jump_addr, 2'b00};
    assign branch_taken   = branch & alu_branch_out;
    assign pc_sel         = jump_reg ? 2'b11 : jump ? 2'b10 : branch_taken ? 2'b01 : 2'b00;
	 
							
    mux_4input #(.WIDTH(32)) PC_Next_Mux (
        .in0(pc_plus4),
        .in1(pc_branch_target),
        .in2(pc_jump_target),
        .in3(read_data1),
        .sel(pc_sel),
        .out(pc_next)
    );

    inst_rom #(
        .ADDR_WIDTH(10),
        // Benchmark options. Uncomment one INIT_PROGRAM and keep the matching
        // data_memory INIT_PROGRAM0-3 paths below.
//         .INIT_PROGRAM("C:/intelFPGA_lite/18.1/lab9/memh/nbhelloworld/nbhelloworld.inst_rom.memh")
//         .INIT_PROGRAM("C:/intelFPGA_lite/18.1/lab9/memh/hello_world/hello_world.inst_rom.memh")
         .INIT_PROGRAM("C:/intelFPGA_lite/18.1/lab9/memh/fib/fib.inst_rom.memh")
    ) IMEM (
        .clock(clock),
        .reset(reset),
        .addr_in(pc_next),
        .data_out(instruction)
    );

    // ========================================================================
    // 2. CONTROL UNIT
    // ========================================================================

    assign rs        = instruction[25:21];
    assign rt        = instruction[20:16];
    assign rd        = instruction[15:11];
    assign shamt     = instruction[10:6];
    assign imm16     = instruction[15:0];
    assign jump_addr = instruction[25:0];

    control Control (
        .opcode(instruction[31:26]),
        .funct(instruction[5:0]),
        .reg_dst(reg_dst),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_func(alu_func),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .branch(branch),
        .jump(jump),
        .jump_reg(jump_reg),
        .lui(lui),
        .zero_extend(zero_extend),
        .alu_shift(alu_shift),
        .load_extend(load_extend),
        .mem_size(mem_size)
    );

    // ========================================================================
    // 3. INSTRUCTION DECODE / REGISTER FILE READ
    // ========================================================================

    mux_2input #(.WIDTH(5)) RegDst_Mux (
        .in0(rt),
        .in1(rd),
        .sel(reg_dst[0]),
        .out(rt_or_rd)
    );

    mux_2input #(.WIDTH(5)) RegDst_RA_Mux (
        .in0(rt_or_rd),
        .in1(5'd31),
        .sel(reg_dst[1]),
        .out(write_reg_addr)
    );

    register_file RegFile (
        .clk(clock),
        .reset(reset),
        .RegWrite_in(reg_write),
        .WriteReg_in(write_reg_addr),
        .WriteData_in(write_data),
        .ReadReg1_in(rs),
        .ReadData1_out(read_data1),
        .ReadReg2_in(rt),
        .ReadData2_out(read_data2)
    );

    sign_extender SignExt (
        .in(imm16),
        .out(sign_ext_imm)
    );

    zero_extender #(.IN_WIDTH(16), .OUT_WIDTH(32)) ZeroExt (
        .in(imm16),
        .out(zero_ext_imm)
    );

    // ========================================================================
    // 4. EXECUTION (ALU)
    // ========================================================================

    mux_2input #(.WIDTH(32)) Extend_Mux (
        .in0(sign_ext_imm),
        .in1(zero_ext_imm),
        .sel(zero_extend),
        .out(ext_imm)
    );

    assign lui_imm = {imm16, 16'b0};

    mux_2input #(.WIDTH(32)) LUI_Mux (
        .in0(ext_imm),
        .in1(lui_imm),
        .sel(lui),
        .out(final_imm)
    );

    assign alu_input_a = alu_shift ? {27'b0, shamt} : read_data1;

    mux_2input #(.WIDTH(32)) ALUSrc_Mux (
        .in0(read_data2),
        .in1(final_imm),
        .sel(alu_src),
        .out(alu_input_b)
    );

    alu ALU (
        .Func_in(alu_func),
        .A_in(alu_input_a),
        .B_in(alu_input_b),
        .O_out(alu_result),
        .Branch_out(alu_branch_out),
        .Jump_out()
    );

    // ========================================================================
    // 5. MEMORY ACCESS
    // ========================================================================

    data_memory #(
        // Hello World, no branch:
        // .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/lab9/memh/nbhelloworld/nbhelloworld.data_ram0.memh"),
        // .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/lab9/memh/nbhelloworld/nbhelloworld.data_ram1.memh"),
        // .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/lab9/memh/nbhelloworld/nbhelloworld.data_ram2.memh"),
        // .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/lab9/memh/nbhelloworld/nbhelloworld.data_ram3.memh")

        // Hello World, with branch:
//         .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/lab9/memh/hello_world/hello_world.data_ram0.memh"),
//         .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/lab9/memh/hello_world/hello_world.data_ram1.memh"),
//         .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/lab9/memh/hello_world/hello_world.data_ram2.memh"),
//         .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/lab9/memh/hello_world/hello_world.data_ram3.memh")

        // Fibonacci:
         .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/lab9/memh/fib/fib.data_ram0.memh"),
         .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/lab9/memh/fib/fib.data_ram1.memh"),
         .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/lab9/memh/fib/fib.data_ram2.memh"),
         .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/lab9/memh/fib/fib.data_ram3.memh")
    ) DMEM (
        .clock(clock),
        .reset(reset),
        .addr_in(alu_result),
        .writedata_in(read_data2),
        .re_in(mem_read),
        .we_in(mem_write),
        .readdata_out(mem_read_data),
        .size_in(mem_size),
        .serial_in(serial_in),
        .serial_ready_in(serial_ready_in),
        .serial_valid_in(serial_valid_in),
        .serial_out(serial_out),
        .serial_rden_out(serial_rden_out),
        .serial_wren_out(serial_wren_out)
    );

    load_extender LoadExt (
        .mem_data(mem_read_data),
        .addr_offset(alu_result[1:0]),
        .extended_data(load_ext_data)
    );

    mux_2input #(.WIDTH(32)) Load_Select_Mux (
        .in0(mem_read_data),
        .in1(load_ext_data),
        .sel(load_extend),
        .out(final_mem_data)
    );

    // ========================================================================
    // 6. WRITE BACK
    // ========================================================================

    mux_2input #(.WIDTH(32)) MemToReg_Mux (
        .in0(alu_result),
        .in1(final_mem_data),
        .sel(mem_to_reg[0]),
        .out(alu_or_mem)
    );

    mux_2input #(.WIDTH(32)) Link_Writeback_Mux (
        .in0(alu_or_mem),
        .in1(pc_plus4),
        .sel(mem_to_reg[1]),
        .out(write_data)
    );

endmodule
