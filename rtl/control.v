module control (
    input  [5:0] opcode,
    input  [5:0] funct,
    input  [4:0] rt,          // needed for REGIMM (BLTZ/BGEZ)

    output reg        reg_dst,
    output reg        alu_src,
    output reg        mem_to_reg,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch,
    output reg        jump,
    output reg        jump_reg,
    output reg        link,
    output reg        lui,
    output reg        zero_extend,
    output reg [1:0]  mem_size,
    output reg [5:0]  alu_func,
    output reg        alu_shift
);

    always @(*) begin
        // ----- safe defaults -----
        reg_dst     = 0;
        alu_src     = 0;
        mem_to_reg  = 0;
        reg_write   = 0;
        mem_read    = 0;
        mem_write   = 0;
        branch      = 0;
        jump        = 0;
        jump_reg    = 0;
        link        = 0;
        lui         = 0;
        zero_extend = 0;
        mem_size    = 2'b11;     // word
        alu_func    = 6'b100000; // ADD
        alu_shift   = 0;

        case (opcode)

            // ----------------------------------------------------------
            // R-TYPE
            // ----------------------------------------------------------
            6'b000000: begin
                case (funct)
                    6'b001000: begin           // JR
                        jump_reg = 1;
                    end
                    6'b000000,                 // SLL
                    6'b000010,                 // SRL
                    6'b000011: begin           // SRA
                        reg_dst  = 1;
                        reg_write = 1;
                        alu_shift = 1;
                        alu_func  = funct;
                    end
                    default: begin             // ADD/ADDU/SUB/AND/OR/XOR/NOR/SLT/SLTU ...
                        reg_dst  = 1;
                        reg_write = 1;
                        alu_func  = funct;
                    end
                endcase
            end

            // ----------------------------------------------------------
            // BRANCHES
            // ----------------------------------------------------------
            6'b000001: begin                   // REGIMM: BLTZ / BGEZ
                branch = 1;
                case (rt)
                    5'b00000: alu_func = 6'b111000; // BLTZ
                    5'b00001: alu_func = 6'b111001; // BGEZ
                    default:  alu_func = 6'b111000;
                endcase
            end
            6'b000100: begin                   // BEQ
                branch   = 1;
                alu_func = 6'b111100;
            end
            6'b000101: begin                   // BNE
                branch   = 1;
                alu_func = 6'b111101;
            end
            6'b000110: begin                   // BLEZ
                branch   = 1;
                alu_func = 6'b111110;
            end
            6'b000111: begin                   // BGTZ
                branch   = 1;
                alu_func = 6'b111111;
            end

            // ----------------------------------------------------------
            // JUMPS
            // ----------------------------------------------------------
            6'b000010: begin                   // J
                jump = 1;
            end
            6'b000011: begin                   // JAL
                jump      = 1;
                link      = 1;
                reg_write = 1;
            end

            // ----------------------------------------------------------
            // I-TYPE ARITHMETIC / LOGIC
            // ----------------------------------------------------------
            6'b001000: begin                   // ADDI
                alu_src  = 1;
                reg_write = 1;
                alu_func  = 6'b100000;
            end
            6'b001001: begin                   // ADDIU
                alu_src  = 1;
                reg_write = 1;
                alu_func  = 6'b100000;
            end
            6'b001010: begin                   // SLTI
                alu_src  = 1;
                reg_write = 1;
                alu_func  = 6'b101010;         // SLT (signed)
            end
            6'b001011: begin                   // SLTIU
                alu_src  = 1;
                reg_write = 1;
                alu_func  = 6'b101011;         // SLTU (unsigned)
            end
            6'b001100: begin                   // ANDI
                alu_src     = 1;
                reg_write   = 1;
                zero_extend = 1;
                alu_func    = 6'b100100;       // AND
            end
            6'b001101: begin                   // ORI
                alu_src     = 1;
                reg_write   = 1;
                zero_extend = 1;
                alu_func    = 6'b100101;       // OR
            end
            6'b001110: begin                   // XORI
                alu_src     = 1;
                reg_write   = 1;
                zero_extend = 1;
                alu_func    = 6'b100110;       // XOR
            end
            6'b001111: begin                   // LUI
                alu_src  = 1;
                reg_write = 1;
                lui       = 1;
                alu_func  = 6'b100101;         // OR ($zero | shifted_imm)
            end

            // ----------------------------------------------------------
            // LOAD
            // ----------------------------------------------------------
            6'b100011: begin                   // LW
                alu_src    = 1;
                mem_to_reg = 1;
                reg_write  = 1;
                mem_read   = 1;
                alu_func   = 6'b100000;
            end
            6'b100000: begin                   // LB  (sign-extend byte)
                alu_src    = 1;
                mem_to_reg = 1;
                reg_write  = 1;
                mem_read   = 1;
                mem_size   = 2'b00;
                alu_func   = 6'b100000;
            end

            // ----------------------------------------------------------
            // STORE
            // ----------------------------------------------------------
            6'b101011: begin                   // SW
                alu_src  = 1;
                mem_write = 1;
                alu_func  = 6'b100000;
            end
            6'b101000: begin                   // SB
                alu_src  = 1;
                mem_write = 1;
                mem_size  = 2'b00;
                alu_func  = 6'b100000;
            end

            default: begin
                reg_write = 0;
            end

        endcase
    end

endmodule
