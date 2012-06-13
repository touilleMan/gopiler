;;; File : battle
;;; Brief : The robot is remote controled and fight with another one.
;;; Registers : $7 motors output
;;;                31--------15-------8---7-------0
;;;                          [Bn An B A] [Bn An B A]
;;;             $6 motor counter
;;;             $5 RF save
;;;             $4 life counter
;;;             $3 buzzer counter
;;;             $2
;;;             $1
;;;             $0 always-zero register
;;; Used instructions : addi, or, ori, andi, beq, lw, sw
;;;
;;; Memory Map :
;;; 0x000
;;; 0x001
;;; 0x010  Set motors
;;; 0x020  Set leds
;;; 0x021  Get Sensors
;;; 0x030  Get RF
;;; 0x031  Set BUZZER
;;; 0x032  Set SEG
;;; 0x033  Set EL_7L
;;; 0x034  Set ST_7L
;;;
;;; FPGA clock : 50mHz
;;; CPU speed : 50mHz / 4 = 12.5mHz
;;; Waiter loop : 10 instructions * 25 times ==> 50kHz
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
	or $2, $0, $0
	or $1, $0, $0

	;; Initialize the motor
	sw $0, 0x10($0)
	;; Initialize the Buzzer
	sw $0, 0x31($0)
	;; Initialize the SEG
	sw $0, 0x32($0)
	;; Initialize EL_7L
	sw $0, 0x33($0)

	;; The robot starts with 3 lives
	ori $4, $0, 3

	;; Update the display before start
	j screenThree
	
;;;;;;;;;;;;;;; Main loop ;;;;;;;;;;;;;;;;;
loop:
	;; Wait counter
	ori $1, $0, 25
waiter:
	beq $0, $1, checkBuzzer
	addi $1, $1, -1
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	or $0, $0, $0 		; useless
	j waiter

checkBuzzer:
	;; If the Buzzer is on, the robot cannot fire or being hit
	beq $0, $3, buzzerOff
	addi $3, $3, -1
	ori $1, $0, 1
	sw $1, 0x31($0)
	j loop

buzzerOff:
	;; Disable the Buzzer
	sw $0, 0x31($0)

Destroyed:
	;; If the robot is destroyed, infiny loop here
	beq $4, $0, -1

checkHit:
	;; Check the ST_7L sensors to determine if we are hit
	lw $1, 0x34($0)
	andi $1, $1, 0x3F
 	beq $1, $0, checkRF
	;; The robot is hit ! Remove a life and update the display
	addi $4, $4, -1
	ori $1, $0, 3
	beq $1, $4, screenThree
	ori $1, $0, 2
	beq $1, $4, screenTwo
	ori $1, $0, 1
	beq $1, $4, screenOne
	;; Default comportement : the robot is destroyed
	j screenZero

setBuzzer:
	;; Set the buzzer and init it counter
	ori $1, $0, 1
	sw $1, 0x31($0)
	ori $3, $0, 25000    ; buzzer for 500ms ==> counter = 25000
	j loop

screenThree:
	;; 3 ==> pins 0,1,2,3,6 ==> 0x4F
	ori $1, $0, 0x4F
	sw $1, 0x32($0)
	j setBuzzer
screenTwo:
	;; 2 ==> pins 0,1,3,4,6 ==> 0x5B
	ori $1, $0, 0x5B
	sw $1, 0x32($0)
	j setBuzzer
screenOne:
	;; 1 ==> pins 2,3 ==> 0x06
	ori $1, $0, 0x06
	sw $1, 0x32($0)
	j setBuzzer
screenZero:
	;; 0 ==> pins 0,1,2,3,4,5 ==> 0x3F
	ori $1, $0, 0x3F
	sw $1, 0x32($0)
	j setBuzzer

checkRF:
	;; Check the RF input to determine the orders
	lw $5, 0x30($0)
checkFire:
	andi $1, $5, 0x1
	beq $1, $0, noFire
	;; The fire order is given
	ori $1, $0, 0x7
	sw $1, 0x33($0)
	j checkMotor
noFire:
	sw $0, 0x33($0)

checkMotor:
	;; Check the motor counter
	beq $6, $0, checkML
	addi $6, $6, -1
	j loop

checkML:
	;; Check the order from the RF for the motors
	andi $1, $5, 0x2
	beq $1, $0, checkMR
	j upML

checkMR:
	;; Check the order from the RF for the motors
	andi $1, $5, 0x4
	beq $1, $0, updateMotor
	j upMR

updateMotor:
	;; Update motor counter
	ori $6, $0, 167
	;; Sent the newly created value to the motors
	sw $7, 0x10($0)
	;; Jump back in the loop
	j loop
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

	;; Go back in the loop
	beq $0, $0, updateMotor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;; Update the left motor ;;;;;;;;;
upML:
	;; Get back the current pole
	andi $1, $7, 0x00F0

	;; Determine it next position according to this array :
	;; reg1 value      pole activated         next pole
	;;     0x00             none                 A
	;;     0x10              A                   Bn
	;;     0x20              B                   A
	;;     0x40              An                  B
	;;     0x80              Bn                  An
	;;     else             WTF ???              A
	ori $2, $0, 0x10
	beq $1, $2, MLsetBn
	ori $2, $0, 0x20
	beq $1, $2, MLsetA
	ori $2, $0, 0x40
	beq $1, $2, MLsetB
	ori $2, $0, 0x80
	beq $1, $2, MLsetAn
	;; If we are here, do the default action : set the motor to Bn
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

	;; Go back in the loop
	beq $0, $0, checkMR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
