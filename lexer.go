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
	// Pseudo instructions
	"nop": NOP,
}

var reg_bind = map[string]int{
	// Numeric naming
	"0":  0,
	"1":  1,
	"2":  2,
	"3":  3,
	"4":  4,
	"5":  5,
	"6":  6,
	"7":  7,
	"8":  8,
	"9":  9,
	"10": 10,
	"11": 11,
	"12": 12,
	"13": 13,
	"14": 14,
	"15": 15,
	"16": 16,
	"17": 17,
	"18": 18,
	"19": 19,
	"20": 20,
	"21": 21,
	"22": 22,
	"23": 23,
	"24": 24,
	"25": 25,
	"26": 26,
	"27": 27,
	"28": 28,
	"29": 29,
	"30": 30,
	"31": 31,
	// Standart naming
	"zero": 0,
	"at":   1,
	"v0":   2,
	"v1":   3,
	"a0":   4,
	"a1":   5,
	"a2":   6,
	"a3":   7,
	"t0":   8,
	"t1":   9,
	"t2":   10,
	"t3":   11,
	"t4":   12,
	"t5":   13,
	"t6":   14,
	"t7":   15,
	"s0":   16,
	"s1":   17,
	"s2":   18,
	"s3":   19,
	"s4":   20,
	"s5":   21,
	"s6":   22,
	"s7":   23,
	"t8":   24,
	"t9":   25,
	"k0":   26,
	"k1":   27,
	"gp":   28,
	"sp":   29,
	"fp":   30,
	"ra":   31,
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
		// Registers always start by '$'
		var reg_name string
		for l.pos++; l.pos < len(l.s) && (unicode.IsDigit(rune(l.s[l.pos])) ||
			unicode.IsLetter(rune(l.s[l.pos]))); l.pos++ {
			reg_name += string(l.s[l.pos])
		}
		// Check if the register name is valid and get it value
		if reg_val, ok := reg_bind[reg_name]; ok {
			lval.val = int32(reg_val)
			return REG
		} else {
			return int(l.s[l.pos-1])
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
	msg += fmt.Sprintln()
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
