# This is a sample asm code
or $1, $0, $0

addi $1, $1, 0x1c # numbers starting with 0x are in hexadecimal
loop: # label
	addi $1, $1, -07 # numbers starting with 0 are in octal

	lw $3, 0($1)

	beq $1, $0, loop


# end of file#