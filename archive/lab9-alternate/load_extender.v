module load_extender(
    input  [31:0] mem_data,
    input  [1:0]  addr_offset,
    output reg [31:0] extended_data
);
    always @(*) begin
        case (addr_offset)
            2'b00: extended_data = {{24{mem_data[7]}},  mem_data[7:0]};
            2'b01: extended_data = {{24{mem_data[15]}}, mem_data[15:8]};
            2'b10: extended_data = {{24{mem_data[23]}}, mem_data[23:16]};
            2'b11: extended_data = {{24{mem_data[31]}}, mem_data[31:24]};
        endcase
    end
endmodule
