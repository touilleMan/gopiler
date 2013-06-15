package main

import (
	"fmt"
	"testing"
)

func TestBind(t *testing.T) {
	var cmds_array = []string{
		"and $1, $2, $3",
		"or $1, $2, $3",
		"xor $1, $2, $3",
		"add $1, $2, $3",
		"sub $1, $2, $3",
		"beq $1, $2, 111",
		"beq $1, $2, label label:",
		"beq $1, $2, -1",
		"ori $3, $7, 0xFFF",
		"sw $5, 0($2)",
		"lw $1, -4($4)",
		"j 0x42",
		"label: j label",
	}
	var results = []uint32{
		0x430824,   // 000000 00010 00011 00001 00000 100100
		0x430825,   // 000000 00010 00011 00001 00000 100101
		0x430827,   // 000000 00010 00011 00001 00000 100111
		0x430820,   // 000000 00010 00011 00001 00000 100000
		0x430822,   // 000000 00010 00011 00001 00000 100010
		0x1022006f, // 000100 00001 00010 0000000001101111
		0x10220000, // 000100 00001 00010 0000000000000000
		0x1022ffff, // 000100 00001 00010 1111111111111111
		0x34e30fff, // 001101 00111 00011 0000111111111111
		0xac450000, // 101011 00010 00101 0000000000000000
		0x8c81fffc, // 100011 00100 00001 1111111111111100
		134217794,  // 000010 00000000000000000000101010
		134217728,  // 000010 00000000000000000000000000
	}

	for i, cmd := range cmds_array {
		GopilerReset()
		lex := AsmLex{s: cmd}
		if AsmParse(&lex) != 0 {
			t.Error("Parse : \"", cmd, "\" (", lex.err, ")")
			return
		}

		bin, err := prog_instance.instructions[0].Bind()
		if err != nil {
			t.Error("Bind : \"", cmd, "\" (", err, ")")
		} else if bin != results[i] {
			msg := fmt.Sprintf("(binary output differs)\nout  : %b\nreal : %b", bin, results[i])
			t.Error("Bind : \"", cmd, "\"", msg)
		}
	}
}

func TestBadBind(t *testing.T) {
	var cmds_array = []string{
		"add $1, $3, $42",     // register 42 doesn't exist
		"beq $1, $2, 0x10000", // branch offset is too big
		"beq $1, $2, -0x8000", // branch offset is too small
		"sll $1, $2, 50",      // shift amount is too big
		"srl $1, $2, -1",      // shift amount is negative
		"beq $0, $0, label",   // label has not been declared
		"j -42",               // no negative address
		"j 0x4000000",         // adress bigger than 26bits
		"j label",             // label not defined
	}

	for _, cmd := range cmds_array {
		GopilerReset()
		lex := AsmLex{s: cmd}
		if AsmParse(&lex) != 0 {
			t.Error("Parse : \"", cmd, "\" (", lex.err, ")")
			return
		}

		_, err := prog_instance.instructions[0].Bind()
		if err == nil {
			t.Error("Bind : \"", cmd, "\" (should not be binded)")
		}
	}
}

func TestBindComment(t *testing.T) {
	cmds := "start: ;comment !\n" +
		"and $1, $2, $3; comment ;;;\n" +
		"; everything is commented sub $4, $3, $6\n" +
		"beq $1, $3, start\n" +
		"sll $7, $8, 30\n" +
		";\n;;;\nlabel:\n;"

	GopilerReset()
	lex := AsmLex{s: cmds}
	if AsmParse(&lex) != 0 {
		t.Error("Parse : \"", cmds, "\" (", lex.err, ")")
	}
	for _, cmd := range prog_instance.instructions {
		_, err := cmd.Bind()
		if err == nil {
			t.Error("Bind : \"", cmd, "\" (should not be binded)")
		}
	}
}
