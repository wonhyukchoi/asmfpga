# Assembler, emulator
---

## General instructions
To emulate your assembly code, do the following:
```shell script
python3.7 assembler.py input.asm output.mif
python3 emulator.py output.mif 
```
Voila! 

## Assembler
To assemble:
```shell
$ python3.7 assembler.py input.asm output.mif
```

Note: the assembler is dependent on `python3.7`. It will not run on previous versions.

This is because the command `str.isacii()` was introduced in [`python3.7`.](https://docs.python.org/3/whatsnew/3.7.html)


## Emulator

To emulate:

```shell
$ python3 emulator.py input.mif
```

You can supply debug arguments to the emulator.
Most notably, you can give it the argument "break", and it will stop after each instruction.
Example:
```shell script
$ python3 emulator.py input.mif break
```

Currently, the emulator only runs on `python3`.
Making it compatible with `python2.7` is a rather trivial task, and has been left to the reader as an exercise. 

## Notes on break points and the language

* Break points are activated by copying a register into itself.
  Doing so will print the contents of the register to the interface.
  

Example:
  ```
  cp $r0 $r0 -- break point to print contents of register $r0 and halt instruction
  ```

  