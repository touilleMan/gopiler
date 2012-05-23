;;; File : linetracer
;;; Brief : The robot follow a line according to it sensors.
;;; Registers : $7 motors output
;;;                31--------15-------8---7-------0
;;;                          [Bn An B A] [Bn An B A]
;;;             $6 right motor counter
;;;             $5 left motor counter
;;;             $4 sensors input
;;;             $2
;;;             $1
;;;             $0 always-zero register
;;; Used instructions : addi, or, ori, andi, beq, lw, sw
;;;
;;; CPU : 50mHz
;;; Default wait loop : 38 instructions
;;; PMP speed    : 500Hz ==> count : 2631
;;; Fast speed   : 400Hz ==> count : 3289
;;; Medium speed : 300Hz ==> count : 4385
;;; Slow speed   : 200Hz ==> count : 6578

	;; First instruction should be useless
	or $0, $0, $0
start:
	;; Initialize the registers
	or $7, $0, $0
	or $6, $0, $0
	or $5, $0, $0

	;; Initialize the output
	sw $0, 0x20($0)
	sw $0, 0x10($0)


;;;;;;;;;;;;;;; Main loop ;;;;;;;;;;;;;;;;;
loop: 				; size : 7 instructions + updateS
	;; Update the sensors
	beq $0, $0, updateS

testMR:
	;; Check and update right motor
	beq $6, $0, upMR
	addi $6, $6, -1

testML:
	;; Check and update left motor
	beq $5, $0, upML
	addi $5, $5, -1

updateM:
	;; Sent the newly created value to the motors
	sw $7, 0x10($0)

	;; Branch to loop
	beq $0, $0, loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;; Update the sensors  ;;;;;;;;;;;
updateS:			; size : 31 instructions
	;; Reset the sensors input register
	or $4, $0, $0

	;; Get led 0
	ori $1, $0, 0x1
	sw $1, 0x20($0)
	lw $2, 0x21($0)
	or $4, $4, $2

	;; Get led 1
	ori $1, $0, 0x2
	sw $1, 0x20($0)
	lw $2, 0x21($0)
	or $4, $4, $2

	;; Get led 2
	ori $1, $0, 0x4
	sw $1, 0x20($0)
	lw $2, 0x21($0)
	or $4, $4, $2

	;; Get led 3
	ori $1, $0, 0x8
	sw $1, 0x20($0)
	lw $2, 0x21($0)
	or $4, $4, $2

	;; Get led 4
	ori $1, $0, 0x10
	sw $1, 0x20($0)
	lw $2, 0x21($0)
	or $4, $4, $2

	;; Get led 5
	ori $1, $0, 0x20
	sw $1, 0x20($0)
	lw $2, 0x21($0)
	or $4, $4, $2

	;; Get led 6
	ori $1, $0, 0x40
	sw $1, 0x20($0)
	lw $2, 0x21($0)
	or $4, $4, $2

	;; Stop the leds and go back in the loop
	sw $0, 0x20($0)
	beq $0, $0, testMR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;; Update the right motor ;;;;;;;;;
upMR:
	;; Get back the current pole
	andi $1, $7, 0x000F

	;; Determine it next position according to this array :
	;; reg1 value      pole activated         next pole
	;;     0x00             none                 A
	;;     0x01              A                   B
	;;     0x02              B                   An
	;;     0x04              An                  Bn
	;;     0x08              Bn                  A
	;;     else             WTF ???              A
	ori $2, $0, 0x1
	beq $1, $2, MRsetB
	ori $2, $0, 0x2
	beq $1, $2, MRsetAn
	ori $2, $0, 0x4
	beq $1, $2, MRsetBn
	;; If we are here, do the default action : set the motor to A
MRsetA:
	ori $1, $0, 0x1
	beq $0, $0, MRflush
MRsetB:
	ori $1, $0, 0x2
	beq $0, $0, MRflush
MRsetAn:
	ori $1, $0, 0x4
	beq $0, $0, MRflush
MRsetBn:
	ori $1, $0, 0x8
	beq $0, $0, MRflush

MRflush:
	;; Update $7 with the new right motor value
	andi $7, $7, 0xFFF0
	or $7, $7, $1

	;; Now reset the counter according to the input sensors
	;;          sensors
	;; Left 0 1 2 3 4 5 6 Right

	;; Test sensor 0
	ori $1, $0, 0x1
	andi $2, $4, 0x1
	beq $1, $2, MRspeedPMP
	
	;; Test sensor 1
	ori $1, $0, 0x2
	andi $2, $4, 0x2
	beq $1, $2, MRspeedFast

	;; Test sensor 2
	ori $1, $0, 0x4
	andi $2, $4, 0x4
	beq $1, $2, MRspeedMiddle

	;; No left sensors on so default speed on right motor : slow one
MRspeedSlow:
	ori $6, $0, 6578
	;; Go back in the loop
	beq $0, $0, testML

MRspeedPMP:
	ori $6, $0, 2631
	;; Go back in the loop
	beq $0, $0, testML
	
MRspeedFast:
	ori $6, $0, 3289
	;; Go back in the loop
	beq $0, $0, testML
	
MRspeedMiddle:
	ori $6, $0, 4385
	;; Go back in the loop
	beq $0, $0, testML
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;; Update the left motor ;;;;;;;;;
upML:
	;; Get back the current pole
	andi $1, $7, 0x00F0

	;; Determine it next position according to this array :
	;; reg1 value      pole activated         next pole
	;;     0x00             none                 A
	;;     0x10              A                   B
	;;     0x20              B                   An
	;;     0x40              An                  Bn
	;;     0x80              Bn                  A
	;;     else             WTF ???              A
	ori $2, $0, 0x10
	beq $1, $2, MLsetB
	ori $2, $0, 0x20
	beq $1, $2, MLsetAn
	ori $2, $0, 0x40
	beq $1, $2, MLsetBn
	;; If we are here, do the default action : set the motor to A
MLsetA:
	ori $1, $0, 0x10
	beq $0, $0, MLflush
MLsetB:
	ori $1, $0, 0x20
	beq $0, $0, MLflush
MLsetAn:
	ori $1, $0, 0x40
	beq $0, $0, MLflush
MLsetBn:
	ori $1, $0, 0x80
	beq $0, $0, MLflush

MLflush:
	;; Update $7 with the new left motor value
	andi $7, $7, 0xFF0F
	or $7, $7, $1

	;; Now reset the counter according to the input sensors
	;;          sensors
	;; Left 0 1 2 3 4 5 6 Right

	;; Test sensor 6
	ori $1, $0, 0x40
	andi $2, $4, 0x40
	beq $1, $2, MLspeedPMP
	
	;; Test sensor 5
	ori $1, $0, 0x20
	andi $2, $4, 0x20
	beq $1, $2, MLspeedFast

	;; Test sensor 4
	ori $1, $0, 0x10
	andi $2, $4, 0x10
	beq $1, $2, MLspeedMiddle

	;; No left sensors on so default speed on right motor : slow one
MLspeedSlow:
	ori $5, $0, 6578
	;; Go back in the loop
	beq $0, $0, updateM

MLspeedPMP:
	ori $5, $0, 2631
	;; Go back in the loop
	beq $0, $0, updateM
	
MLspeedFast:
	ori $5, $0, 3289
	;; Go back in the loop
	beq $0, $0, updateM
	
MLspeedMiddle:
	ori $5, $0, 4385
	;; Go back in the loop
	beq $0, $0, updateM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
