# Processor

## To run:

* Top-level entity: `cpu.vhd`
* Software resides in the `software` directory.
  * Project `.mif` file: `multiply.mif`
  * To compare the speed of software vs hardware, 
    `software_bench.asm` and `hardware_bench.asm` also reside in the folder.
* No slide switches need to be engaged. 
* Must use serial I/O. Recommended baud rate is 9600. 
* Recommended to build through Altera Quartus II. 

## Slide switches, LED's, and hex displays

* Hex displays 7 ~ 3 show the PC.
* Hex displays 3 ~ 0 show the IR.
* Slide switch 17 suspends memory.
* Slide switch 16 holds the clock.
* Key 3 resets memory.
* Key 2 "steps over" each fsm state.
* LED 4 shows `serial_character_ready`.
* LED 3 shows `mem_dataready_inv`.
* LED 2 shows `mem_addr_ready`.
* LED 1 shows `mem_rw`.
* LED G0 shows `addr_from_pc_or_alu`.
* Other interactions with slide switches and hex displays exist for debugging purposes.
  Please refer to `cpu.vhd`for more information.
