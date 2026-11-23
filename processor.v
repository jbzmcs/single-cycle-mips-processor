module processor (
    input  clock,
    input  reset,

    // Serial I/O (wired through to data_memory)
    input  [7:0] serial_in,
    input        serial_valid_in,
    input        serial_ready_in,
    output [7:0] serial_out,
    output       serial_rden_out,
    output       serial_wren_out
);

    // =====================================================================
    // WIRE DECLARATIONS
    // =====================================================================

    // Program counter
    wire [31:0] pc_out, pc_next, pc_plus4;
    wire [31:0] pc_branch_target, pc_jump_target;
    wire        branch_taken;

    // Instruction fields
    wire [31:0] instruction;
    wire [4:0]  rs, rt, rd, shamt;
    wire [15:0] imm16;
    wire [25:0] jump_addr;

    // Register file
    wire [31:0] read_data1, read_data2, write_data;
    wire [4:0]  write_reg_addr;

    // Immediate
    wire [31:0] sign_ext_imm, final_imm;

    // ALU
    wire [31:0] alu_input_a, alu_input_b, alu_result;
    wire        alu_branch_out, alu_jump_out;

    // Memory / write-back
    wire [31:0] mem_read_data;
    reg  [31:0] load_data;

    // Control signals
    wire [5:0] alu_func;
    wire       reg_dst, alu_src, mem_to_reg, reg_write;
    wire       mem_read, mem_write;
    wire       branch, jump, jump_reg, link;
    wire       lui, zero_extend, alu_shift;
    wire [1:0] mem_size;

    // =====================================================================
    // 1. INSTRUCTION FETCH
    // =====================================================================

    // PC resets to 003FFFFC so that pc_plus4 = 00400000 during reset.
    // IMEM then fetches ROM[0] on the first active clock after reset drops.
    program_counter #(.RESET_ADDR(32'h003FFFFC)) PC_Unit (
        .clk(clock), .reset(reset),
        .next_pc(pc_next), .current_pc(pc_out)
    );

    adder PC_Adder (.a(pc_out), .b(32'd4), .result(pc_plus4));

    // Branch target: PC+4 + sign_ext(imm16) * 4
    assign pc_branch_target = pc_plus4 + {sign_ext_imm[29:0], 2'b00};

    // Jump target: {PC+4[31:28], instr[25:0], 2'b00}
    assign pc_jump_target = {pc_plus4[31:28], jump_addr, 2'b00};

    // PC-next mux — priority: JR > J/JAL > branch > sequential
    // No reset override here; the PC register handles reset internally.
    assign branch_taken = branch & alu_branch_out;
    assign pc_next = jump_reg     ? read_data1       :
                     jump         ? pc_jump_target   :
                     branch_taken ? pc_branch_target :
                                    pc_plus4;

    inst_rom #(
        .ADDR_WIDTH(10),
//      .INIT_PROGRAM("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/hello_world.inst_rom.memh")
        .INIT_PROGRAM("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/fib.inst_rom.memh")
    ) IMEM (
        .clock(clock), .reset(reset),
        .addr_in(pc_next), .data_out(instruction)
    );

    // =====================================================================
    // 2. INSTRUCTION DECODE — FIELDS
    // =====================================================================
    assign rs        = instruction[25:21];
    assign rt        = instruction[20:16];
    assign rd        = instruction[15:11];
    assign shamt     = instruction[10:6];
    assign imm16     = instruction[15:0];
    assign jump_addr = instruction[25:0];

    // =====================================================================
    // 3. CONTROL UNIT
    // =====================================================================
    control Control (
        .opcode(instruction[31:26]),
        .funct(instruction[5:0]),
        .rt(rt),

        .reg_dst(reg_dst),     .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),.reg_write(reg_write),
        .mem_read(mem_read),   .mem_write(mem_write),
        .branch(branch),       .jump(jump),
        .jump_reg(jump_reg),   .link(link),
        .lui(lui),             .zero_extend(zero_extend),
        .mem_size(mem_size),   .alu_func(alu_func),
        .alu_shift(alu_shift)
    );

    // =====================================================================
    // 4. REGISTER FILE  (decode stage)
    // =====================================================================
    sign_extender SignExt (.in(imm16), .out(sign_ext_imm));

    // Write-register address: $ra (31) for JAL/link, rd for R-type, rt for I-type
    assign write_reg_addr = link    ? 5'd31 :
                            reg_dst ? rd    :
                                      rt;

    register_file RegFile (
        .clk(clock),            .reset(reset),
        .RegWrite_in(reg_write),
        .WriteReg_in(write_reg_addr),
        .WriteData_in(write_data),
        .ReadReg1_in(rs),        .ReadData1_out(read_data1),
        .ReadReg2_in(rt),        .ReadData2_out(read_data2)
    );

    // =====================================================================
    // 5. ALU  (execute stage)
    // =====================================================================

    // Immediate: LUI shifts imm16 left 16, ANDI/ORI/XORI zero-extend, else sign-extend
    assign final_imm = lui         ? {imm16, 16'b0}  :
                       zero_extend ? {16'b0,  imm16} :
                                      sign_ext_imm;

    // A-input: shamt (zero-extended to 32 bits) for shifts, rs data otherwise
    assign alu_input_a = alu_shift ? {27'b0, shamt} : read_data1;

    mux_2input #(.WIDTH(32)) ALUSrc_Mux (
        .in0(read_data2), .in1(final_imm),
        .sel(alu_src), .out(alu_input_b)
    );

    alu ALU (
        .Func_in(alu_func),
        .A_in(alu_input_a), .B_in(alu_input_b),
        .O_out(alu_result),
        .Branch_out(alu_branch_out), .Jump_out(alu_jump_out)
    );

    // =====================================================================
    // 6. DATA MEMORY  (memory stage)
    // =====================================================================
    data_memory #(
//      .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/hello_world.data_ram0.memh"),
//      .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/hello_world.data_ram1.memh"),
//      .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/hello_world.data_ram2.memh"),
//      .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/hello_world.data_ram3.memh")
        .INIT_PROGRAM0("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/fib.data_ram0.memh"),
        .INIT_PROGRAM1("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/fib.data_ram1.memh"),
        .INIT_PROGRAM2("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/fib.data_ram2.memh"),
        .INIT_PROGRAM3("C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/fib.data_ram3.memh")
    ) DMEM (
        .clock(clock),            .reset(reset),
        .addr_in(alu_result),     .writedata_in(read_data2),
        .re_in(mem_read),         .we_in(mem_write),
        .readdata_out(mem_read_data), .size_in(mem_size),
        .serial_in(serial_in),    .serial_ready_in(serial_ready_in),
        .serial_valid_in(serial_valid_in),
        .serial_out(serial_out),  .serial_rden_out(serial_rden_out),
        .serial_wren_out(serial_wren_out)
    );

    // Byte-load: sign-extend the selected byte based on address[1:0]
    always @(*) begin
        case (mem_size)
            2'b00: begin
                case (alu_result[1:0])
                    2'b00: load_data = {{24{mem_read_data[7]}},  mem_read_data[7:0]};
                    2'b01: load_data = {{24{mem_read_data[15]}}, mem_read_data[15:8]};
                    2'b10: load_data = {{24{mem_read_data[23]}}, mem_read_data[23:16]};
                    2'b11: load_data = {{24{mem_read_data[31]}}, mem_read_data[31:24]};
                endcase
            end
            default: load_data = mem_read_data;
        endcase
    end

    // =====================================================================
    // 7. WRITE-BACK
    // =====================================================================
    wire [31:0] alu_or_mem = mem_to_reg ? load_data : alu_result;
    assign write_data = link ? pc_plus4 : alu_or_mem;

endmodule
