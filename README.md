# Single-Cycle MIPS Processor

A single-cycle processor for a subset of the MIPS32 ISA, written in Verilog for
Intel Quartus Prime (Cyclone V). Every instruction is fetched, decoded, executed,
and written back in one clock cycle. The processor runs compiled C programs,
including a Fibonacci benchmark that prints its output over a memory-mapped
serial port.

> **Coursework context:** Built for COE 181.1 (Computer Organization) across
> three labs: the datapath (Lab 7), the control unit (Lab 8), and branches and
> jumps (Lab 9). Each lab is a tagged commit. See [Project history](#project-history).

## Repository layout

```
├── rtl/              Processor design (top level: processor.v)
├── sim/              Testbenches
├── programs/         Benchmark programs, one folder each (memory images + sources)
├── docs/             Control-signal table
├── archive/          Older and alternate working copies
├── processor.qpf     Quartus project
└── processor.qsf     Quartus settings and file list
```

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
group) is in [`docs/control_signal_table.csv`](docs/control_signal_table.csv).

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

Each folder in `programs/` holds one program's memory images: `*.inst_rom.memh`
for `inst_rom`, and `*.data_ram0-3.memh` for the four byte lanes of
`data_memory`.

| Program | What it exercises | Expected serial output |
|---|---|---|
| `fib` | `jal`/`jr` calls, `bgtz` loop, `slt`/`bnez` division loop, shifts | `S`, then `0 1 1 2 3 5 8 13 21 34` (digits printed back to back), then `E` |
| `hello_world` | `jal`/`jr`, `lb`, `bnez` on the string terminator | `Hello World` |
| `beq_test` | Taken and not-taken `beq` | None (check the registers in the waveform) |
| `lab8-test` | Lab 8 instruction mix | None (check the registers in the waveform) |

Both printing programs end in a `jal`-to-itself loop, so they print once and
then spin silently. The Lab 8 benchmarks (`lab7-test` and the no-branch
`nbhelloworld`) are in the `control-complete` tag.

**Choosing a program:** set `BENCHMARK` at the top of
[`rtl/processor.v`](rtl/processor.v):

```verilog
`define BENCHMARK "fib"   // or "hello_world", "beq_test", "lab8-test"
```

The paths are relative. Quartus resolves them from the project folder, and
ModelSim (launched through NativeLink) from `simulation/modelsim`.
`processor.v` picks the right prefix using ModelSim's built-in `MODEL_TECH`
macro.

## Simulation

`sim/testbench.v` instantiates the processor and generates the clock. It holds
`reset` high for the first 200 ns and prints every byte written to the serial
port:

```
[<time>] Serial: <char>
```

In Quartus, set the testbench to `testbench` and run **Tools → Run Simulation
Tool → RTL Simulation** (ModelSim – Intel FPGA Edition). Unit testbenches:
`sim/control_tb.v` and `sim/register_file_tb.v`.

## Building (Quartus)

1. Open `processor.qpf` in Intel Quartus Prime 18.1 Lite.
2. Run **Processing → Start Compilation**.
3. Check the wiring with **Tools → Netlist Viewers → RTL Viewer**.

## Design Files

| File | Description |
|---|---|
| `rtl/processor.v` | Top level: datapath, next-PC logic, and write-back |
| `rtl/control.v` | Main control unit (opcode/funct/rt → 15 control signals) |
| `rtl/alu.v` | ALU with branch-condition outputs, plus the shift unit |
| `rtl/register_file.v` | 32 × 32-bit register file (`$zero` hardwired) |
| `rtl/program_counter.v` | PC register (resets to `0x003FFFFC`) |
| `rtl/adder.v`, `rtl/sign_extender.v`, `rtl/mux_2input.v` | Small building blocks |
| `rtl/inst_rom.v` | Registered instruction ROM |
| `rtl/data_memory.v`, `rtl/async_memory.v`, `rtl/serial_buf.v` | Data RAM and memory-mapped serial port |
| `sim/testbench.v`, `sim/control_tb.v`, `sim/register_file_tb.v` | Testbenches |

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

The tags hold each lab's flat Quartus project as it was submitted, with
absolute `.memh` paths. Check one out with `git checkout control-complete`.
See [CHANGELOG.md](CHANGELOG.md) for details. Older and alternate working
copies are kept in [`archive/`](archive/).
