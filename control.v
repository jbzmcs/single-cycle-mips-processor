module control(
    input  [5:0] opcode,
    input  [5:0] funct,
    output reg   reg_dst,
    output reg   alu_src,
    output reg   mem_to_reg,
    output reg   reg_write,
    output reg   mem_read,
    output reg   mem_write,
    output reg   [5:0] alu_func
);

    always @(*) begin
        // Safe defaults — prevents latches
        reg_dst    = 0;
        alu_src    = 0;
        mem_to_reg = 0;
        reg_write  = 0;
        mem_read   = 0;
        mem_write  = 0;
        alu_func   = 6'b100000; // Default: ADD

        case (opcode)
            6'b000000: begin // R-Type (ADD, SUB, AND, OR, XOR, NOR)
                reg_dst   = 1;
                reg_write = 1;
                alu_func  = funct; // funct field maps directly to ALU Func_in
            end

            6'b100011: begin // LW (Load Word)
                alu_src    = 1;
                mem_to_reg = 1;
                reg_write  = 1;
                mem_read   = 1;
                alu_func   = 6'b100000; // ADD (base + offset)
            end

            6'b101011: begin // SW (Store Word)
                alu_src   = 1;
                mem_write = 1;
                alu_func  = 6'b100000; // ADD (base + offset)
            end

            6'b001000: begin // ADDI (Add Immediate)
                alu_src   = 1;
                reg_write = 1;
                alu_func  = 6'b100000; // ADD
            end

            default: begin
                reg_write = 0;
            end
        endcase
    end
endmodule
