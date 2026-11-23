`timescale 1ns/1ns

module control_tb;

    // Inputs
    reg [5:0] opcode;
    reg [5:0] funct;

    // Outputs
    wire        reg_dst;
    wire        alu_src;
    wire        mem_to_reg;
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        branch;
    wire [5:0]  alu_func;

    // Instantiate the Unit Under Test (UUT)
    control uut (
        .opcode(opcode),
        .funct(funct),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .alu_func(alu_func)
    );

    initial begin
        opcode = 0;
        funct  = 0;
        #10;

        // =================================================================
        // Test 1: R-Type Instructions (opcode = 000000)
        // Expected for ALL R-types:
        //   reg_dst=1, alu_src=0, mem_to_reg=0, reg_write=1
        //   mem_read=0, mem_write=0, alu_func=funct (pass-through)
        // =================================================================
        $display("=== TEST 1: R-Type Instructions (opcode=000000) ===");
        opcode = 6'b000000;

        funct = 6'b100000; #10; // ADD
        $display("[ADD]  funct=100000 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==1 && alu_src==0 && reg_write==1 && mem_read==0 && mem_write==0 && alu_func==6'b100000)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=1 alu_src=0 reg_write=1 mem_read=0 mem_write=0 alu_func=100000");

        funct = 6'b100010; #10; // SUB
        $display("[SUB]  funct=100010 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==1 && alu_src==0 && reg_write==1 && mem_read==0 && mem_write==0 && alu_func==6'b100010)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=1 alu_src=0 reg_write=1 mem_read=0 mem_write=0 alu_func=100010");

        funct = 6'b100100; #10; // AND
        $display("[AND]  funct=100100 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==1 && alu_src==0 && reg_write==1 && mem_read==0 && mem_write==0 && alu_func==6'b100100)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=1 alu_src=0 reg_write=1 mem_read=0 mem_write=0 alu_func=100100");

        funct = 6'b100101; #10; // OR
        $display("[OR]   funct=100101 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==1 && alu_src==0 && reg_write==1 && mem_read==0 && mem_write==0 && alu_func==6'b100101)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=1 alu_src=0 reg_write=1 mem_read=0 mem_write=0 alu_func=100101");

        funct = 6'b100111; #10; // NOR
        $display("[NOR]  funct=100111 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==1 && alu_src==0 && reg_write==1 && mem_read==0 && mem_write==0 && alu_func==6'b100111)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=1 alu_src=0 reg_write=1 mem_read=0 mem_write=0 alu_func=100111");

        funct = 6'b100110; #10; // XOR
        $display("[XOR]  funct=100110 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==1 && alu_src==0 && reg_write==1 && mem_read==0 && mem_write==0 && alu_func==6'b100110)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=1 alu_src=0 reg_write=1 mem_read=0 mem_write=0 alu_func=100110");

        // =================================================================
        // Test 2: I-Type Instructions
        // =================================================================
        $display("=== TEST 2: I-Type Instructions ===");
        funct = 6'b000000; // funct don't care for I-types

        opcode = 6'b001000; #10; // ADDI
        $display("[ADDI] opcode=001000 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==0 && alu_src==1 && mem_to_reg==0 && reg_write==1 && mem_read==0 && mem_write==0 && alu_func==6'b100000)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=0 alu_src=1 mem_to_reg=0 reg_write=1 mem_read=0 mem_write=0 alu_func=100000");

        opcode = 6'b100011; #10; // LW
        $display("[LW]   opcode=100011 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==0 && alu_src==1 && mem_to_reg==1 && reg_write==1 && mem_read==1 && mem_write==0 && alu_func==6'b100000)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=0 alu_src=1 mem_to_reg=1 reg_write=1 mem_read=1 mem_write=0 alu_func=100000");

        opcode = 6'b101011; #10; // SW
        $display("[SW]   opcode=101011 | reg_dst=%b alu_src=%b mem_to_reg=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, alu_func);
        if (reg_dst==0 && alu_src==1 && mem_to_reg==0 && reg_write==0 && mem_read==0 && mem_write==1 && alu_func==6'b100000)
            $display("       PASS");
        else
            $display("       FAIL - Expected: reg_dst=0 alu_src=1 mem_to_reg=0 reg_write=0 mem_read=0 mem_write=1 alu_func=100000");

        opcode = 6'b000100; #10; // BEQ
        $display("[BEQ]  opcode=000100 | branch=%b alu_src=%b reg_write=%b mem_read=%b mem_write=%b alu_func=%b",
                  branch, alu_src, reg_write, mem_read, mem_write, alu_func);
        if (branch==1 && alu_src==0 && reg_write==0 && mem_read==0 && mem_write==0 && alu_func==6'b111100)
            $display("       PASS");
        else
            $display("       FAIL - Expected: branch=1 alu_src=0 reg_write=0 mem_read=0 mem_write=0 alu_func=111100");

        $display("=== All Tests Completed ===");

    end

endmodule
