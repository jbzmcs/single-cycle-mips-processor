# Single-Cycle MIPS Processor

A single-cycle processor for a subset of the MIPS32 ISA, written in Verilog for
Intel Quartus Prime (Cyclone V). Every instruction is fetched, decoded, executed,
and written back in one clock cycle. The processor runs compiled C programs,
including a Fibonacci benchmark that prints its output over a memory-mapped
serial port.

> **Coursework context:** Built for COE 181.1 (Computer Organization) across
> three labs: the datapath (Lab 7), the control unit (Lab 8), and branches and
> jumps (Lab 9). Each lab is a tagged commit. See [Project history](#project-history).

## Supported Instructions

| Group | Instructions |
|---|---|
| R-type ALU | `add`, `addu`, `sub`, `subu`, `and`, `or`, `xor`, `nor`, `slt`, `sltu` |
| Shifts | `sll`, `srl`, `sra` |
| I-type ALU | `addi`, `addiu`, `slti`, `sltiu`, `andi`, `ori`, `xori`, `lui` |
| Loads / stores | `lw`, `lb`, `sw`, `sb` |
| Branches | `beq`, `bne`, `bltz`, `bgez`, `blez`, `bgtz` |
| Jumps | `j`, `jal`, `jr` |

The full control-signal table (one row per signal, one column per instruction
group) is in [`control_signal_table.csv`](control_signal_table.csv).

## Datapath

```
                 jr  ─► rs
                 j   ─► {PC+4[31:28], addr26, 00}
  next-PC mux ◄─ beq ─► PC+4 + (signext(imm) << 2)   (if taken)
       │         else ► PC+4
       ▼
  PC ─► inst_rom ─► control ─► register_file ─► ALU ─► data_memory ─► write-back
```

1. **Fetch.** `program_counter` holds the PC, and `adder` computes PC+4. The
   next-PC select is prioritized: `jr` > `j`/`jal` > taken branch > PC+4.
   `inst_rom` is a registered ROM, so it is addressed by `pc_next` so that the
   fetched instruction lines up with the PC on the next cycle.
2. **Decode.** `control` decodes the opcode, `funct`, and `rt` (for
   `bltz`/`bgez`). `register_file` reads `rs`/`rt`. The immediate is
   sign-extended, zero-extended (`andi`/`ori`/`xori`), or shifted left 16
   (`lui`).
3. **Execute.** The `alu` computes the result, or evaluates the branch condition
   (`branch_taken = branch & alu_branch_out`). For shifts, operand A is `shamt`.
4. **Memory.** `data_memory` handles word and byte accesses. Byte loads are
   sign-extended from the selected byte lane. Stores to `0xffff000c` go to the
   serial port.
5. **Write-back.** Writes the ALU result, the loaded data, or PC+4 (for `jal`).
   The destination is `rd`, `rt`, or `$ra` (for `jal`).

## Benchmarks

The `.memh` files hold assembled programs for `inst_rom` (`*.inst_rom.memh`) and
the four byte lanes of `data_memory` (`*.data_ram0-3.memh`).

| Program | What it exercises | Expected serial output |
|---|---|---|
| `fib` | `jal`/`jr` calls, `bgtz` loop, `slt`/`bnez` division loop, shifts | `S`, then `0 1 1 2 3 5 8 13 21 34` (digits printed back to back), then `E` |
| `hello_world` | `jal`/`jr`, `lb`, `bnez` on the string terminator | `Hello World` |
| `beq_test` | Taken and not-taken `beq` | None (check the registers in the waveform) |
| `lab8-test` | Lab 8 instruction mix | None (check the registers in the waveform) |

Both printing programs end in a `jal`-to-itself loop, so they print once and
then spin silently. The Lab 8 benchmarks (`lab7-test` and the no-branch
`nbhelloworld`) are in the `control-complete` tag.

To switch programs, comment and uncomment the matching `INIT_PROGRAM` (in
`inst_rom`) and `INIT_PROGRAM0`–`3` (in `data_memory`) lines in `processor.v`.

> The `INIT_PROGRAM` paths in `processor.v` are absolute
> (`C:/intelFPGA_lite/18.1/SingleCycleMIPSBranches/...`). Update them to where you
> cloned this repository.

## Simulation

`testbench.v` instantiates the processor and generates the clock. It holds
`reset` high for the first 200 ns and prints every byte written to the serial
port:

```
[<time>] Serial: <char>
```

In Quartus, set the testbench to `testbench` and run **Tools → Run Simulation
Tool → RTL Simulation** (ModelSim – Intel FPGA Edition). Unit testbenches:
`control_tb.v` and `register_file_tb.v`.

## Building (Quartus)

1. Open `processor.qpf` in Intel Quartus Prime 18.1 Lite.
2. Run **Processing → Start Compilation**.
3. Check the wiring with **Tools → Netlist Viewers → RTL Viewer**.

## File Structure

| File | Description |
|---|---|
| `processor.v` | Top level: datapath, next-PC logic, and write-back |
| `control.v` | Main control unit (opcode/funct/rt → 15 control signals) |
| `alu.v` | ALU with branch-condition outputs, plus the shift unit |
| `register_file.v` | 32 × 32-bit register file (`$zero` hardwired) |
| `program_counter.v` | PC register (resets to `0x003FFFFC`) |
| `adder.v`, `sign_extender.v`, `mux_2input.v` | Small building blocks |
| `inst_rom.v` | Registered instruction ROM |
| `data_memory.v`, `async_memory.v`, `serial_buf.v` | Data RAM and memory-mapped serial port |
| `testbench.v`, `control_tb.v`, `register_file_tb.v` | Testbenches |
| `*.memh` | Benchmark memory images |
| `control_signal_table.csv` | Control-signal table from the lab report |
| `processor.qpf`, `processor.qsf` | Quartus project and settings |

## Credits

The course provided the starting framework (originally by Adrian Caulfield and
Trevor Bunker): `alu.v` (without shifts), `inst_rom.v`, `data_memory.v`,
`async_memory.v`, `serial_buf.v`, and the benchmark programs. My own work is the
datapath, the control unit, the next-PC and write-back logic, the register file,
and the ALU shift unit.

## Project history

| Tag | Lab | State |
|---|---|---|
| `datapath-complete` | Lab 7 | Datapath with control signals tied to constants; synthesizes but doesn't execute |
| `control-complete` | Lab 8 | Control unit for R-type, `addi`, `lw`, `sw`; runs `lab7-test` and `nbhelloworld` |
| `branches-complete` | Lab 9 | Branches, jumps, shifts, byte memory; runs `fib` and `hello_world` |

Check out any tag (`git checkout control-complete`) to get that lab's Quartus
project. See [CHANGELOG.md](CHANGELOG.md) for details.
