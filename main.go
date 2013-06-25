package main

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"os"
)

var f_input = flag.String("i", "", "Input file. (stdin if nothing specified)")
var f_output = flag.String("o", "", "Output file. (stdout if nothing specified)")
var f_type = flag.String("t", "vhdl", "Type of output : binary, print, vhdl")
var f_bootaddr = flag.Uint("boot-address", 0xbfc00000, "Boot address (default : 0xbfc00000)")

func GopilerReset() {
	prog_instance = program{[]Binder{}, make(map[string]uint32), []uint32{}}
}

func GopilerFront() error {
	var file *os.File
	if *f_input == "" {
		// Read on STDIN.
		file = os.NewFile(0, "stdin")
	} else {
		// Open the input file.
		var err error
		file, err = os.Open(*f_input)
		if err != nil {
			return err
		}
	}
	defer file.Close()

	fi := bufio.NewReader(file)
	for line := 1; ; line++ {
		cmd, prefix, err := fi.ReadLine()
		if err != nil || prefix {
			// No more lines to parse.
			return nil
		}

		// Execute the parsing.
		lex := AsmLex{s: string(cmd)}
		if AsmParse(&lex) != 0 {
			msg := fmt.Sprint("Parsing Error line ", line, " : ", lex.err)
			return errors.New(msg)
		}
	}
	return nil
}

func GopilerBack() error {
	var out *bufio.Writer
	if *f_output == "" {
		// Not ouput file, use stdout
		out = bufio.NewWriter(os.Stdout)
	} else {
		// Create the output file
		file, err := os.Create(*f_output)
		if err != nil {
			return err
		}
		defer file.Close()
		out = bufio.NewWriter(file)
	}

	for pos, cmd := range prog_instance.instructions {
		bin, err := cmd.Bind()
		if err != nil {
			msg := fmt.Sprint("Binding Error : ", err)
			return errors.New(msg)
		}

		switch *f_type {
		case "binary":
			out.WriteByte(byte(bin))
			out.WriteByte(byte(bin >> 8))
			out.WriteByte(byte(bin >> 16))
			out.WriteByte(byte(bin >> 24))
		case "print":
			for i := 0; i < 32; i++ {
				b := fmt.Sprintf("%b", bin>>uint(31-i)&1)
				out.Write([]byte(b))
			}
			out.Write([]byte("\n"))
		case "vhdl":
			// Address is the boot address plus the instruction position * 4
			address := *f_bootaddr + uint(pos*4)
			out.Write([]byte("when \""))
			for i := 0; i < 32; i++ {
				b := fmt.Sprintf("%b", address>>uint(31-i)&1)
				out.Write([]byte(b))
			}
			out.Write([]byte("\"=>output<=\""))
			for i := 0; i < 32; i++ {
				b := fmt.Sprintf("%b", bin>>uint(31-i)&1)
				out.Write([]byte(b))
			}
			out.Write([]byte("\";\n"))
		}
	}
	out.Flush()
	return nil
}

func main() {
	flag.Parse()
	GopilerReset()

	if err := GopilerFront(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if err := GopilerBack(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
}
