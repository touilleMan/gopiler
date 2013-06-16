package main

import (
	"testing"
)

func TestSpace(t *testing.T) {
	GopilerReset()

	if AsmParse(&AsmLex{s: ""}) != 0 {
		t.Fail()
	}
	if AsmParse(&AsmLex{s: "      \n\n   "}) != 0 {
		t.Fail()
	}
}

func TestLabel(t *testing.T) {
	var cmds_array = []string{
		"label:",
		"         label:          ",
		"      label:   label:  ",
		" label:label:",
	}

	for _, cmd := range cmds_array {
		GopilerReset()
		lex := AsmLex{s: cmd}
		if AsmParse(&lex) != 0 {
			t.Error("Parse : \"", cmd, "\" (", lex.err, ")")
		}
	}
}

func TestBadLabel(t *testing.T) {
	var cmds_array = []string{
		"label",
		"         label:otherlabel          ",
		"      label   otherlabel:  ",
		" firstlabel   :otherlabel  ",
	}

	for _, cmd := range cmds_array {
		GopilerReset()
		if AsmParse(&AsmLex{s: cmd}) == 0 {
			t.Error("Parse : \"", cmd, "\" (should not be parsed)")
		}
	}
}

func TestInstruction(t *testing.T) {
	var cmds_array = []string{
		// R instructions
		"add $1, $2, $3",
		"addu $1, $2, $3",
		"and $1, $2, $3",
		"jr $1, $2, $3",
		"nor $1, $2, $3",
		"or $1, $2, $3",
		"sltu $1, $2, $3",
		"sub $1, $2, $3",
		// I instructions
		"addi $7, $5, -22",
		"addiu $7, $5, -22",
		"andi $7, $5, -22",
		"beq $1, $2, 111",
		"beq $1, $2, label",
		"bneq $1, $2, 111",
		"bneq $1, $2, label",
		"lbu $1, 0x442($2)",
		"lhu $1, 0x1142($20)",
		"lui $1, 0xFFFF($12)",
		"lw $1, -0x9998($4)",
		"lw $1, 0x4242($2)",
		"ori $3, $3, 0xFFF",
		"sb $1, 0x4242($2)",
		"sh $1, 0x4242($2)",
		"sll $1, $2, 11123",
		"sll $1, $2, 23",
		"sll $1, $2, 4",
		"slt $1, $2, $3",
		"slti $1, 0x4242($31)",
		"sltiu $1, 0x4242($0)",
		"srl $1, $2, 42",
		"sw $1, -0123($6)",
		"sw $1, 023423 ( $3 )",
		// J instructions
		"j 0x42",
		"j 0x3ffffff",
		"jal 0x42",
		"jal label",
	}

	GopilerReset()
	for _, cmd := range cmds_array {
		lex := AsmLex{s: cmd}
		if AsmParse(&lex) != 0 {
			t.Error("Parse : \"", cmd, "\" (", lex.err, ")")
		}
	}
}

func TestBadInstruction(t *testing.T) {
	var cmds_array = []string{
		"and $1, $2, ",
		"or , $2, $3",
		"nor $1, $2, $3,",
		"nor $1, $221, $3",
		"add $1, $2, $3, $3",
		"sub $1, $2, $3 $1",
		"jr",
		"sh $1, $2, 32",
		"beq $1, $2 111",
		"beq $1, $2, $1",
		"sll $1, $2, 4$2",
		"sll $1, 44($2), 23",
		"sll $1, $2, $1",
		"sll $1, $2, label",
		"srl 23, $2, 42",
		"lw $1, $2, $1",
		"sw $1, $2, label",
		"sw $1, label($1)",
		"sw $1, 42($1), $2",
		"slt $1, label, $3",
		"sw $5, (0)$2",
		"j 0x33, $1",
		"j $1$",
		"jal 0x33, $1",
		"jal label:",
	}

	GopilerReset()
	for _, cmd := range cmds_array {
		if AsmParse(&AsmLex{s: cmd}) == 0 {
			t.Error("Parse : \"", cmd, "\" (should not be parsed)")
		}
	}
}

func TestMultiline(t *testing.T) {
	cmds := "start:\n" +
		"and $1, $2, $3\n" +
		"sub $4, $3, $6\n" +
		"beq $1, $3, start\n" +
		"sll $7, $8, 30\n"

	GopilerReset()
	lex := AsmLex{s: cmds}
	if AsmParse(&lex) != 0 {
		t.Error("Parse : \"", cmds, "\" (", lex.err, ")")
	}
}

func TestComment(t *testing.T) {
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
}
