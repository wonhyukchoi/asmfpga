# Custom assembly language and Instruction Set Architecture Implementation in FPGA

**Custom 16-bit assembly language and instruction set architecture to implement hardware multiplication on a DE-115 FPGA.**

This project has been aimed to create a hardware and software multiplier capable of taking two signed 16-bit integers from I/O, multiplying them, and then returning them to I/O.

* [Principles of Operation](https://github.com/wonhyukchoi/asmfpga/blob/master/principles_of_operations/principles_of_operations.md)
* [`VHDL` source code](https://github.com/wonhyukchoi/asmfpga/blob/master/src)
* [Assembler and emulator](https://github.com/wonhyukchoi/asmfpga/blob/master/asm_and_emu)
* [High-level language representation](https://github.com/wonhyukchoi/asmfpga/blob/master/high_level_language)

Instruction Set Architecture closely follows the [`MIPS`](https://en.wikipedia.org/wiki/MIPS_architecture) architecture. 

Hardware synthesis is written in `VHDL`, assembler and emulator are written in `python`, and high-level language idea sketch is written in `C++`.