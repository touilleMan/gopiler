[![Build Status](https://travis-ci.org/touilleMan/gopiler.svg?branch=master)](https://travis-ci.org/touilleMan/gopiler)
[ ![Codeship Status for touilleMan/gopiler](https://codeship.io/projects/68e9c780-0b49-0132-b0c1-12fe8603e519/status)](https://codeship.io/projects/31945)

# Gopiler - Simple assembler written in Go

Gopiler assemble is just a simple project aiming at creating a MIPS assembler in Go.

# Features

 - Simple easy to hack and readable code : less than 700 lines including tests
 - No support for ELF or any other system headers, Gopiler only compile your code, nothing more
 - Three possible types of outputs :
    - Default binary
    - Binary in text output
    - VHDL output to easily include it into embedded designer tools (i.g. Xilinx)

```
    when "00000000000000000000000000000000"=>output<="00000000000000000000000000100101";
    when "00000000000000000000000000000100"=>output<="00000000000000000011100000100101";
```

# Supported instructions

 - `add`
 - `addi`
 - `addiu`
 - `addu`
 - `and`
 - `andi`
 - `beq`
 - `bneq`
 - `j`
 - `jal`
 - `jr`
 - `lbu`
 - `lhu`
 - `lui`
 - `lw`
 - `nor`
 - `or`
 - `ori`
 - `sb`
 - `sh`
 - `sll`
 - `slt`
 - `slti`
 - `sltiu`
 - `sltu`
 - `srl`
 - `sw`
 - `sub`
 - `subu`
 - labels (`mylabel:`)
 - and comments (lines starting by `;`) of course !

# Quick use

### Linux :
`./gopiler -h` will tell you everything you need !

### Windows :
Go in win directory and launch `start_gopiler.bat`
The input used file is `input.asm`
The output file is `ouput.txt`
(you can of course change thoses files by editing the bat script !)

# License

See the LICENSE file for more details, but basically do what the fuck you to with this code ;-)
