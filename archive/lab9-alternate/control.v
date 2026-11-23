module control(
    input  [5:0] opcode,
    input  [5:0] funct,
    output reg   [1:0] reg_dst,    // 00=rt, 01=rd, 10=$ra
    output reg   alu_src,
    output reg   [1:0] mem_to_reg, // 00=ALU, 01=memory, 10=PC+4
    output reg   reg_write,
    output reg   mem_read,
    output reg   mem_write,
    output reg   branch,
    output reg   jump,
    output reg   jump_reg,
    output reg   lui,
    output reg   zero_extend,
    output reg   alu_shift,
    output reg   load_extend,
    output reg   [1:0] mem_size,
    output reg   [5:0] alu_func
);

    localparam OP_RTYPE = 6'b000000;
    localparam OP_J     = 6'b000010;
    localparam OP_JAL   = 6'b000011;
    localparam OP_BEQ   = 6'b000100;
    localparam OP_BNE   = 6'b000101;
    localparam OP_BGTZ  = 6'b000111;
    localparam OP_ADDI  = 6'b001000;
    localparam OP_ADDIU = 6'b001001;
    localparam OP_ANDI  = 6'b001100;
    localparam OP_ORI   = 6'b001101;
    localparam OP_LUI   = 6'b001111;
    localparam OP_LB    = 6'b100000;
    localparam OP_LW    = 6'b100011;
    localparam OP_SB    = 6'b101000;
    localparam OP_SW    = 6'b101011;

    localparam FUNCT_SLL = 6'b000000;
    localparam FUNCT_SRL = 6'b000010;
    localparam FUNCT_SRA = 6'b000011;
    localparam FUNCT_JR  = 6'b001000;

    always @(*) begin
        // Safe defaults prevent latches and make unsupported opcodes no-ops.
        reg_dst     = 2'b00;
        alu_src     = 0;
        mem_to_reg  = 2'b00;
        reg_write   = 0;
        mem_read    = 0;
        mem_write   = 0;
        branch      = 0;
        jump        = 0;
        jump_reg    = 0;
        lui         = 0;
        zero_extend = 0;
        alu_shift   = 0;
        load_extend = 0;
        mem_size    = 2'b11;     // Word by default.
        alu_func    = 6'b100000; // ADD by default.

        case (opcode)
            OP_RTYPE: begin
                case (funct)
                    FUNCT_JR: begin
                        jump_reg = 1;
                    end

                    FUNCT_SLL,
                    FUNCT_SRL,
                    FUNCT_SRA: begin
                        reg_dst   = 2'b01;
                        reg_write = 1;
                        alu_shift = 1;
                        alu_func  = funct;
                    end

                    default: begin // ADD/ADDU/SUB/SUBU/AND/OR/XOR/NOR/SLT/SLTU
                        reg_dst   = 2'b01;
                        reg_write = 1;
                        alu_func  = funct;
                    end
                endcase
            end

            OP_J: begin
                jump = 1;
            end

            OP_JAL: begin
                jump       = 1;
                reg_dst    = 2'b10;
                mem_to_reg = 2'b10;
                reg_write  = 1;
            end

            OP_BEQ: begin
                branch   = 1;
                alu_func = 6'b111100;
            end

            OP_BNE: begin
                branch   = 1;
                alu_func = 6'b111101;
            end

            OP_BGTZ: begin
                branch   = 1;
                alu_func = 6'b111111;
            end

            OP_ADDI: begin
                alu_src   = 1;
                reg_write = 1;
                alu_func  = 6'b100000;
            end

            OP_ADDIU: begin
                alu_src   = 1;
                reg_write = 1;
                alu_func  = 6'b100000;
            end

            OP_ANDI: begin
                alu_src     = 1;
                reg_write   = 1;
                zero_extend = 1;
                alu_func    = 6'b100100;
            end

            OP_ORI: begin
                alu_src     = 1;
                reg_write   = 1;
                zero_extend = 1;
                alu_func    = 6'b100101;
            end

            OP_LUI: begin
                alu_src     = 1;
                reg_write   = 1;
                zero_extend = 1;
                lui         = 1;
                alu_func    = 6'b100101;
            end

            OP_LB: begin
                alu_src     = 1;
                mem_to_reg  = 2'b01;
                reg_write   = 1;
                mem_read    = 1;
                load_extend = 1;
                mem_size    = 2'b11; // Read full word, then select/sign-extend byte.
                alu_func    = 6'b100000;
            end

            OP_LW: begin
                alu_src    = 1;
                mem_to_reg = 2'b01;
                reg_write  = 1;
                mem_read   = 1;
                mem_size   = 2'b11;
                alu_func   = 6'b100000;
            end

            OP_SB: begin
                alu_src   = 1;
                mem_write = 1;
                mem_size  = 2'b00;
                alu_func  = 6'b100000;
            end

            OP_SW: begin
                alu_src   = 1;
                mem_write = 1;
                mem_size  = 2'b11;
                alu_func  = 6'b100000;
            end

            default: begin
                reg_write = 0;
            end
        endcase
    end
endmodule
