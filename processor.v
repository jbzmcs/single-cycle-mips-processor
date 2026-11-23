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
    wire [31:0] pc_out;          // Current PC (output of PC register)
    wire [31:0] pc_next;         // Next PC (input to PC register)
    wire [31:0] pc_plus4;        // PC + 4
    wire [31:0] instruction;     // Fetched instruction

    wire [31:0] read_data1;      // rs value from register file
    wire [31:0] read_data2;      // rt value from register file
    wire [31:0] write_data;      // Data to write back to register file
    wire [31:0] alu_result;      // ALU output / memory address
    wire [31:0] sign_ext_imm;    // Sign-extended immediate
    wire [31:0] alu_input_b;     // ALU operand B (register or immediate)
    wire [31:0] mem_read_data;   // Data read from data memory

    // Control Signals
    wire        reg_dst;
    wire        mem_read;
    wire        mem_to_reg;
    wire        mem_write;
    wire        alu_src;
    wire        reg_write;
    wire [5:0]  alu_func;
    wire [4:0]  write_reg_addr;

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

    assign pc_next = pc_plus4;

    inst_rom #(
         .INIT_PROGRAM("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/lab7-test.inst_rom.memh")
//        .INIT_PROGRAM("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/nbhelloworld.inst_rom.memh")
    ) IMEM (
        .clock(clock),
        .reset(reset),
        .addr_in(pc_out),
        .data_out(instruction)
    );

    // ========================================================================
    // 2. CONTROL UNIT
    // ========================================================================

    control Control (
        .opcode(instruction[31:26]),
        .funct(instruction[5:0]),
        .reg_dst(reg_dst),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_func(alu_func),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_write(reg_write)
    );

    // ========================================================================
    // 3. INSTRUCTION DECODE / REGISTER FILE READ
    // ========================================================================

    // Mux: select destination register (rt for I-type, rd for R-type)
    mux_2input #(.WIDTH(5)) RegDst_Mux (
        .in0(instruction[20:16]), // rt
        .in1(instruction[15:11]), // rd
        .sel(reg_dst),
        .out(write_reg_addr)
    );

    register_file RegFile (
        .clk(clock),
        .reset(reset),
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

    // Mux: select ALU operand B (register value or sign-extended immediate)
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
        .Branch_out(),
        .Jump_out()
    );

    // ========================================================================
    // 5. MEMORY ACCESS & WRITE BACK
    // ========================================================================

    data_memory #(
         .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/lab7-test.data_ram0.memh"),
         .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/lab7-test.data_ram1.memh"),
         .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/lab7-test.data_ram2.memh"),
         .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/lab7-test.data_ram3.memh")
//        .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/nbhelloworld.data_ram0.memh"),
//        .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/nbhelloworld.data_ram1.memh"),
//        .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/nbhelloworld.data_ram2.memh"),
//        .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/SingleCycleMIPSControl/nbhelloworld.data_ram3.memh")
    ) DMEM (
        .clock(clock),
        .reset(reset),
        .addr_in(alu_result),
        .writedata_in(read_data2),
        .re_in(mem_read),
        .we_in(mem_write),
        .readdata_out(mem_read_data),
        .size_in(2'b11), // Word size — hardwired for Lab 8
        .serial_in(serial_in),
        .serial_ready_in(serial_ready_in),
        .serial_valid_in(serial_valid_in),
        .serial_out(serial_out),
        .serial_rden_out(serial_rden_out),
        .serial_wren_out(serial_wren_out)
    );

    // Mux: select write-back data (ALU result or memory read data)
    mux_2input #(.WIDTH(32)) MemToReg_Mux (
        .in0(alu_result),
        .in1(mem_read_data),
        .sel(mem_to_reg),
        .out(write_data)
    );

endmodule
