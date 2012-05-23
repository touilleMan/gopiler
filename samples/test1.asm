;;; File : test1
;;; Brief : The robot go straight at constant speed.
;;; Registers : $7 motors output
;;;                31--------15-------8---7-------0
;;;                          [Bn An B A] [Bn An B A]
;;;             $6 sensors input (not used yet)
;;;             $5 counter
;;;             $4 counter base value
;;;             $2 tmp register
;;;             $1 tmp register
;;;             $0 always-zero register
;;; Used instructions : addi, or, ori, andi, beq, sw
;;;
;;; 50mHz CPU, 3 instructions loop for waiting => 17mHz
;;; motor's max speed : 4kHz => counter 4250
;;; motor's middle speed : 2kHz => counter : 8500
;;; motor's low speed : 1kHz => counter : 17000

	;; Do nothing for initialize
	or $0, $0, $0
start:
	;; Set the base value to middle speed
	addi $4, $0, 8500

	;; Initialize the counter to base value
	or $5, $0, $4

	;; Initialize the motors
	andi $7, $7, 0x0

loop:
	;; Main loop, decrease the counter until 0, then move the engines
	addi $5, $5, -1
	beq $0, $5, updateMotors
	beq $0, $0, loop 	; If the counter != 0, continue the loop

updateMotors:
	;; Set the next pole of the motors, then set back the counter
	;; Get back the left motor previous values
	andi $1, $7, 0x00F0

	;; Determine it next position according to this array :
	;; reg1 value      pole activated         next pole
	;;     0                none                 A
	;;     1                 A                   B
	;;     2                 B                   An
	;;     4                 An                  Bn
	;;     8                 Bn                  A
	;;    else             WTF ???               A
	ori $2, $0, 0x10
	beq $1, $2, test1setB
	ori $2, $0, 0x20
	beq $1, $2, test1setAn
	ori $2, $0, 0x40
	beq $1, $2, test1setBn
	;; If we are here, do the default action : set the motor to A
test1setA:
	ori $1, $0, 0x10
	beq $0, $0, test1end
test1setB:
	ori $1, $0, 0x20
	beq $0, $0, test1end
test1setAn:
	ori $1, $0, 0x40
	beq $0, $0, test1end
test1setBn:
	ori $1, $0, 0x80
	beq $0, $0, test1end

test1end:
	;; Update $7 with the new left motor value
	andi $7, $7, 0xFF0F
	or $7, $7, $1

	;; Do the same for right motor
	andi $1, $7, 0x000F

	ori $2, $0, 0x1
	beq $1, $2, test2setB
	ori $2, $0, 0x2
	beq $1, $2, test2setAn
	ori $2, $0, 0x4
	beq $1, $2, test2setBn
	;; If we are here, do the default action : set the motor to A
test2setA:
	ori $1, $0, 0x1
	beq $0, $0, test2end
test2setB:
	ori $1, $0, 0x2
	beq $0, $0, test2end
test2setAn:
	ori $1, $0, 0x4
	beq $0, $0, test2end
test2setBn:
	ori $1, $0, 0x8
	beq $0, $0, test2end

test2end:
	;; Update $7 with the new right motor value
	andi $7, $7, 0xFFF0
	or $7, $7, $1

	;; Send the newly created value to the motors
	sw $7, 0x10($0)

	;; Set back the counter to base value
	or $5, $0, $4

	;; Go back to the main loop
	beq $0, $0, loop
