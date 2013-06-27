package main

import (
	"errors"
	"fmt"
)

type r_instruction struct {
	cmd   int32
	rs    uint32
	rt    uint32
	rd    uint32
	shamt uint32
}

type i_instruction struct {
	cmd   int32
	rs    uint32
	rt    uint32
	immed int32
	label string
	pos   uint32
}

type j_instruction struct {
	cmd     int32
	address uint32
	label   string
	pos     uint32
}

type Binder interface {
	Bind() (uint32, error)
}

type program struct {
	instructions []Binder
	labels       map[string]uint32
	binary_out   []uint32
}

var prog_instance program

var opcode_instructions = map[int32]uint32{
	// R intructions
	AND:  0x00,
	OR:   0x00,
	NOR:  0x00,
	ADD:  0x00,
	ADDU: 0x00,
	SUB:  0x00,
	SUBU: 0x00,
	JR:   0x00,
	SLTU: 0x00,
	// I instructions
	BEQ:   0x04,
	BNEQ:  0x05,
	SLL:   0x00,
	SRL:   0x00,
	LW:    0x23,
	SW:    0x2b,
	SLT:   0x00,
	ANDI:  0x0c,
	ORI:   0x0d,
	ADDI:  0x08,
	ADDIU: 0x09,
	LBU:   0x24,
	LHU:   0x25,
	LUI:   0x0f,
	SLTI:  0x0a,
	SLTIU: 0x0b,
	SB:    0x28,
	SH:    0x29,
	// J instructions
	J:   0x02,
	JAL: 0x03,
}

var funct_instructions = map[int32]uint32{
	AND:  0x24,
	OR:   0x25,
	NOR:  0x27,
	ADD:  0x20,
	ADDU: 0x21,
	SUB:  0x22,
	SUBU: 0x23,
	SLL:  0x00,
	SRL:  0x02,
	SLT:  0x2a,
	JR:   0x08,
	SLTU: 0x2b,
}

func cmd_r(cmd, rs, rt, rd, shamt int32) {
	inst := r_instruction{cmd, uint32(rs), uint32(rt), uint32(rd), uint32(shamt)}
	prog_instance.instructions = append(prog_instance.instructions, inst)
}

func cmd_i(cmd, rs, rt, immed int32, label string) {
	inst := i_instruction{cmd, uint32(rs), uint32(rt), immed, label, uint32(len(prog_instance.instructions))}
	prog_instance.instructions = append(prog_instance.instructions, inst)
}

func cmd_j(cmd, address int32, label string) {
	inst := j_instruction{cmd, uint32(address), label, uint32(len(prog_instance.instructions))}
	prog_instance.instructions = append(prog_instance.instructions, inst)
}

func label(name string) {
	prog_instance.labels[name] = uint32(len(prog_instance.instructions))
}

func (r r_instruction) Bind() (bin uint32, err error) {
	// Check if the registers are valid
	for _, reg := range []uint32{r.rs, r.rt, r.rd} {
		if reg < 0 || reg > 31 {
			msg := fmt.Sprintf("$%v doesn't exist, should be between 0 and 31", reg)
			err = errors.New(msg)
			return
		}
	}

	// Generate opcode and funct
	bin = (opcode_instructions[r.cmd] & 0x3f) << 26
	bin |= (funct_instructions[r.cmd] & 0x3f)

	// Generate registers
	bin |= (r.rs & 0x1f) << 21
	bin |= (r.rt & 0x1f) << 16
	bin |= (r.rd & 0x1f) << 11

	// Shamt is code on 6bits
	if r.shamt < 0 || r.shamt > 31 {
		err = errors.New("shamt should be between 0 and 31")
		return
	}
	bin |= (r.shamt & 0x1f) << 6
	return
}

func (i i_instruction) Bind() (bin uint32, err error) {
	// Check if the registers are valid
	for reg := range []uint32{i.rs, i.rt} {
		if reg < 0 || reg > 31 {
			msg := fmt.Sprintf("$%v doesn't exist, should be between 0 and 31", reg)
			err = errors.New(msg)
			return
		}
	}

	// Generate opcode and funct
	bin = (opcode_instructions[i.cmd] & 0x3f) << 26

	// Generate regiers
	bin |= (i.rs & 0x1f) << 21
	bin |= (i.rt & 0x1f) << 16

	// Convert the label if it exists
	if i.label != "" {
		label, ok := prog_instance.labels[i.label]
		if ok {
			// pos + 1 + immed = label
			i.immed = int32(label) - int32(i.pos) - 1
		} else {
			msg := fmt.Sprintf("Label %s has not been declared", i.label)
			err = errors.New(msg)
			return
		}
	}

	// Immed is coded on 16bits and can be signed or not.
	if i.immed < -(1<<15-1) || i.immed > (1<<16-1) {
		err = errors.New("immed should be 16bits long")
		return
	}
	bin |= uint32(i.immed & 0xffff)
	return
}

func (j j_instruction) Bind() (bin uint32, err error) {
	// Convert the label if it exists
	if j.label != "" {
		label, ok := prog_instance.labels[j.label]
		if ok {
			// The jump immed is [27:2], then we discare [31:28] and [1:0]
			j.address = (uint32(*f_bootaddr>>2) + label) & 0x03FFFFFF
		} else {
			msg := fmt.Sprintf("Label %s has not been declared", j.label)
			err = errors.New(msg)
			return
		}
	}

	// Check if the address is 26bits long
	if j.address < 0 || j.address > (1<<26-1) {
		msg := fmt.Sprintf("%x is not a valid 26 bits long unsigned address", j.address)
		err = errors.New(msg)
		return
	}
	// Generate opcode and address
	bin = (opcode_instructions[j.cmd] & 0x3f) << 26
	bin |= (j.address & 0x03ffffff)
	return
}
