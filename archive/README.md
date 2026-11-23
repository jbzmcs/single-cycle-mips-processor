# Archive

Older and alternate working copies of the processor, kept for reference. They
are not part of the tagged history at the repo root. Each folder is a separate
Quartus project, and its `.memh` paths are absolute, pointing at where the copy
originally lived.

| Folder | What it is |
|---|---|
| `coe181/lab7` | Separate working copy of the Lab 7 datapath, with its RTL schematic |
| `coe181/lab8` | Separate working copy of the Lab 8 control unit, with its control schematic |
| `coe181/lab9` | Copy of `lab8` set up for Lab 9. Branches were never added here, but it includes the C, assembly and disassembly for `fib` and `hello_world`. |
| `lab9-alternate` | A second Lab 9 implementation that also runs `fib`. It uses separate modules (`mux_4input`, `shift_left_2`, `zero_extender`, `load_extender`) and 2-bit `reg_dst`/`mem_to_reg` selects. |
