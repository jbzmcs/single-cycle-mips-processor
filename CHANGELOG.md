# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [branches-complete] — Branches, Jumps and Shifts (Lab 9)

### Added
- **Next-PC logic** in `processor.v`: 4-way select with priority JR > J/JAL > taken branch > PC+4
- **Branch target** (`PC+4 + signext(imm) << 2`) and **jump target** (`{PC+4[31:28], addr26, 00}`)
- **JAL link path**: `$ra` as a write-register option and PC+4 as a write-back option
- **Immediate select**: zero-extend for ANDI/ORI/XORI, `imm << 16` for LUI
- **Byte loads**: sign-extends the selected byte lane for LB
- **ALU shift unit** for SLL/SRL/SRA; operand A is driven by `shamt`
- New control outputs: `branch`, `jump`, `jump_reg`, `link`, `lui`, `zero_extend`, `mem_size`, `alu_shift`
- Benchmarks: `fib`, `hello_world`, `beq_test`, `lab8-test`
- `control_signal_table.csv`: control-signal table from the lab report

### Changed
- `inst_rom` is addressed by `pc_next` instead of `pc_out`. It is a registered ROM, so this keeps the fetched instruction aligned with the PC and branch targets. Its address width is widened to 10 bits.
- `program_counter` takes a `RESET_ADDR` parameter (default `0x003FFFFC`).

### Fixed
- Shifts returned `X`: the provided ALU had no shift support, and `fib` needs `sll`/`sra`.

### Supported Instructions
- **R-type:** ADD, ADDU, SUB, SUBU, AND, OR, XOR, NOR, SLT, SLTU, SLL, SRL, SRA, JR
- **I-type:** ADDI, ADDIU, SLTI, SLTIU, ANDI, ORI, XORI, LUI
- **Memory:** LW, LB, SW, SB
- **Branches:** BEQ, BNE, BLTZ, BGEZ, BLEZ, BGTZ
- **Jumps:** J, JAL

---

## [control-complete] — Single-Cycle Control Unit (Lab 8)

### Added
- **control.v**: combinational control unit that decodes opcode and funct into RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite and the ALU's 6-bit `Func_in` (passed straight through from `funct` for R-type)
- **control_tb.v**: control-unit testbench covering each instruction type
- Benchmarks: `lab7-test` and `nbhelloworld` (no-branch Hello World)

### Changed
- **processor.v**: the control unit replaces the tied-off control signals
- **program_counter.v**: resets to `0x003FFFFC`, and `inst_rom` is addressed by `pc_out`, so the first instruction fetched is at `0x00400000`
- **async_memory.v**: updated to the course's revised version, which initializes memory to `0xADADADAD`

### Supported Instructions
- **R-type:** ADD, SUB, AND, OR, NOR, XOR
- **I-type:** ADDI
- **Memory:** LW, SW

---

## [datapath-complete] — Single-Cycle MIPS Datapath (Lab 7)

### Added
- Complete single-cycle datapath in `processor.v`
- Core modules: `program_counter`, `adder` (PC+4), `register_file` (with `register_file_tb`), `sign_extender`, parameterized `mux_2input`
- RegDst, ALUSrc and MemToReg multiplexers
- Course-provided `alu`, `inst_rom`, `data_memory`, `async_memory` and `serial_buf`, plus the top-level `testbench`
- Control signals tied to constants, so the design synthesizes but doesn't execute yet
