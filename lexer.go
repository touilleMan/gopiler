package main

import (
	"errors"
	"fmt"
	"strconv"
	"unicode"
)

type AsmLex struct {
	s   string
	pos int
	err error
}

var name_instructions = map[string]int{
	// R instructions
	"add":  ADD,
	"addu": ADDU,
	"and":  AND,
	"jr":   JR,
	"nor":  NOR,
	"or":   OR,
	"sltu": SLTU,
	"sub":  SUB,
	"subu": SUBU,
	// I instructions
	"addi":  ADDI,
	"addiu": ADDIU,
	"andi":  ANDI,
	"beq":   BEQ,
	"bneq":  BNEQ,
	"lbu":   LBU,
	"lhu":   LHU,
	"lui":   LUI,
	"lw":    LW,
	"ori":   ORI,
	"sb":    SB,
	"sh":    SH,
	"sll":   SLL,
	"slt":   SLT,
	"slti":  SLTI,
	"sltiu": SLTIU,
	"srl":   SRL,
	"sw":    SW,
	// J instructions
	"j":   J,
	"jal": JAL,
}

func (l *AsmLex) Lex(lval *AsmSymType) int {
	// First thing to do : get ride of the spaces.
	for _, c := range l.s[l.pos:] {
		if !unicode.IsSpace(c) {
			break
		}
		l.pos += 1
	}

	// Check if we have finished the parsing.
	if l.pos == len(l.s) {
		return 0
	}

	var tok string
	if unicode.IsLetter(rune(l.s[l.pos])) {
		for _, c := range l.s[l.pos:] {
			if unicode.IsLetter(rune(c)) || unicode.IsDigit(rune(c)) {
				tok += string(c)
				continue
			}
			break
		}
		l.pos += len(tok)
		lval.name = tok

		// Check if the token is a reserved word.
		if code, ok := name_instructions[tok]; ok {
			lval.val = int32(code)
			return code
		}

		// The token is a label.
		return LABEL
	} else if unicode.IsDigit(rune(l.s[l.pos])) {
		// The current Token is a number
		for _, c := range l.s[l.pos:] {
			if unicode.IsLetter(rune(c)) || unicode.IsDigit(rune(c)) {
				tok += string(c)
				continue
			}
			break
		}

		// Convert the token to a regular number.
		val, err := strconv.ParseInt(tok, 0, 32)
		if err == nil {
			lval.val = int32(val)
			l.pos += len(tok)
			return NUMBER
		}
	} else if l.s[l.pos] == '$' {
		// Reg is $ and one or two digits.
		l.pos++
		if l.pos < len(l.s) && unicode.IsDigit(rune(l.s[l.pos])) {
			lval.val = int32(l.s[l.pos] - '0')
			l.pos++
			if l.pos < len(l.s) && unicode.IsDigit(rune(l.s[l.pos])) {
				lval.val *= 10
				lval.val += int32(l.s[l.pos] - '0')
				l.pos++
			}
			return REG
		}
	} else if l.s[l.pos] == ';' {
		// Comments
		for _, c := range l.s[l.pos:] {
			l.pos++
			if c != '\n' {
				continue
			}
		}
		return COMMENT
	}

	// Unrecognise token.
	l.pos++
	return int(l.s[l.pos-1])
}

func (l *AsmLex) Error(s string) {
	var tok string
	fmt.Sscan(l.s[l.pos:], &tok)
	msg := s
	msg += fmt.Sprintln()
	msg += l.s
	for i := 0; i < l.pos; i++ {
		if l.s[i] == '\t' {
			msg += "\t"
		} else {
			msg += " "
		}
	}
	msg += "^"
	l.err = errors.New(msg)
}
