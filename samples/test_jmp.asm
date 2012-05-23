;;; File : test_jmp
;;; Brief : Simple 1 increased modulo counter.
;;; Registers : $7
;;;             $6
;;;             $5
;;;             $4
;;;             $2 Modulo value
;;;             $1 Current counter value
;;;             $0 always-zero register
;;; Used instructions : addi, or, ori, beq, sw, j
;;;
;;; 50mHz CPU, 3 instructions loop for waiting => 17mHz
;;; motor's max speed : 4kHz => counter 4250
;;; motor's middle speed : 2kHz => counter : 8500
;;; motor's low speed : 1kHz => counter : 17000

	;; Initialize
	or $0, $0, $0
	sw $0, 0x20($0)
	sw $0, 0x10($0)
	ori $2, $0, 0x9
start:
	ori $1, $0, 0x0

loop:
	addi $1, $1, 1
	sw $1, 0x10($0)
	beq $1, $2, start
	j loop
