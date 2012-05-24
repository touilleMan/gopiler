;;; File : linetracer
;;; Brief : The robot follow a line according to it sensors.
;;; Registers : $7 motors output
;;;                31--------15-------8---7-------0
;;;                          [Bn An B A] [Bn An B A]
;;;             $6 right motor counter
;;;             $5 left motor counter
;;;             $4 sensors input
;;;             $3 Sensors counter
;;;             $2
;;;             $1
;;;             $0 always-zero register
;;; Used instructions : addi, or, ori, andi, beq, lw, sw
;;;
;;; CPU : 50mHz
;;; Waiter loop : 10 instructions * 100 times ==> 1k ==> 50kHz
;;; PMP speed    : 500Hz ==> wait 100k ==> Motor count : 100
;;; Fast speed   : 400Hz ==> wait 125k ==> Motor count : 125
;;; Medium speed : 300Hz ==> wait 167k ==> Motor count : 167
;;; Slow speed   : 200Hz ==> wait 250k ==> Motor count : 250
;;; Sensors      : 100Hz ==> wait 500k ==> Sensors count : 500

	;; First instruction should be useless
	or $0, $0, $0
start:
	;; Initialize the registers
	or $7, $0, $0
	or $6, $0, $0
	or $5, $0, $0
	or $4, $0, $0
	or $3, $0, $0

	;; Initialize the motor
	sw $0, 0x10($0)

	;; Enable the Leds
	ori $1, $0, 0x7f
	sw $1, 0x20($0)


;;;;;;;;;;;;;;; Main loop ;;;;;;;;;;;;;;;;;
loop:
	;; Wait counter : 10 instructions long * 100 = 1k instructions
	ori $1, $0, 100
waiter:
	beq $0, $1, testSensors
	addi $1, $1, -1
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	j waiter

testSensors:
	;; Check and update sensors
	beq $0, $3, upS
	addi $3, $3, -1

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

	;; Jump for infinite loop
	j loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;; Update the sensors  ;;;;;;;;;;;
upS:
	lw $4, 0x21($0)
	ori $3, $0, 500
	j testMR
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
	ori $6, $0, 250
	;; Go back in the loop
	beq $0, $0, testML

MRspeedPMP:
	ori $6, $0, 100
	;; Go back in the loop
	beq $0, $0, testML
	
MRspeedFast:
	ori $6, $0, 125
	;; Go back in the loop
	beq $0, $0, testML
	
MRspeedMiddle:
	ori $6, $0, 167
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
	ori $5, $0, 250
	;; Go back in the loop
	beq $0, $0, updateM

MLspeedPMP:
	ori $5, $0, 100
	;; Go back in the loop
	beq $0, $0, updateM
	
MLspeedFast:
	ori $5, $0, 125
	;; Go back in the loop
	beq $0, $0, updateM
	
MLspeedMiddle:
	ori $5, $0, 167
	;; Go back in the loop
	beq $0, $0, updateM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
