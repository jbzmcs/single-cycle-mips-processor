`timescale 1ns / 1ps

module control_tb();
    reg  [5:0] opcode, funct;
    wire       reg_dst, alu_src, mem_to_reg;
    wire       reg_write, mem_read, mem_write;
    wire [5:0] alu_func;

    control uut(
        .opcode(opcode), .funct(funct),
        .reg_dst(reg_dst),     .alu_src(alu_src),   .mem_to_reg(mem_to_reg),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .alu_func(alu_func)
    );

    task check;
        input [8*4:1] name;
        input exp_reg_dst, exp_alu_src, exp_mem_to_reg;
        input exp_reg_write, exp_mem_read, exp_mem_write;
        input [5:0] exp_alu_func;
        begin
            #10;
            if (reg_dst    == exp_reg_dst    &&
                alu_src    == exp_alu_src    &&
                mem_to_reg == exp_mem_to_reg &&
                reg_write  == exp_reg_write  &&
                mem_read   == exp_mem_read   &&
                mem_write  == exp_mem_write  &&
                alu_func   == exp_alu_func)
                $display("[PASS] %s", name);
            else
                $display("[FAIL] %s", name);
        end
    endtask

    initial begin
        // name        rd as mt rw mr mw  func
        opcode = 6'b100011; funct = 6'b000000;
        check("LW",   0, 1, 1, 1, 1, 0, 6'b100000);

        opcode = 6'b101011; funct = 6'b000000;
        check("SW",   0, 1, 0, 0, 0, 1, 6'b100000);

        opcode = 6'b001000; funct = 6'b000000;
        check("ADDI", 0, 1, 0, 1, 0, 0, 6'b100000);

        opcode = 6'b000000; funct = 6'b100000;
        check("ADD",  1, 0, 0, 1, 0, 0, 6'b100000);

        opcode = 6'b000000; funct = 6'b100010;
        check("SUB",  1, 0, 0, 1, 0, 0, 6'b100010);

        opcode = 6'b000000; funct = 6'b100100;
        check("AND",  1, 0, 0, 1, 0, 0, 6'b100100);

        opcode = 6'b000000; funct = 6'b100101;
        check("OR",   1, 0, 0, 1, 0, 0, 6'b100101);

        opcode = 6'b000000; funct = 6'b100110;
        check("XOR",  1, 0, 0, 1, 0, 0, 6'b100110);

        opcode = 6'b000000; funct = 6'b100111;
        check("NOR",  1, 0, 0, 1, 0, 0, 6'b100111);

        $display("Done.");
        #10 $stop;
    end
endmodule
