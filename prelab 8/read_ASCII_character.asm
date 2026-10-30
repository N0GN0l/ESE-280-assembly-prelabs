;
; read_ASCII_character.asm
;***************************************************************************
;*
;* Title: Lab 08: Software and Hardware Serial Recievers, Design Task 2
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;*
;* DESCRIPTION
;* This program reads a character from PB1, (8N1 format, 9600 baud), and uses
;* the subroutine serial_recieve to detects the negative edge of PB1 (the start
;* of the frame), then it returns the character to r16 along with a carry flag to
;* check if there was any framing errors. Then displays the character along with the
;* carry flag C (8th bit) on the bargraph LED.
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************

.nolist
.include "m4809def.inc"
.list

start:
    ldi r16, 0xFF                     ;PD7 - PD0 output
	out VPORTD_DIR, r16
	cbi VPORTB_DIR, 1                 ;PB1 input, Rx pin

main_loop:
	rcall serial_recieve              ;returns character in r16 and Carry flag

	andi r16, 0x7F                     ;mask to ensure the 7 bits are good
	brcc display                      ;if Carry flag = 0, then no FE
	ori r16, 0x80                      ;Sets Carry flag into the 8th bit
display:
	com r16                           ;outputs to the bargraph led
	out VPORTD_OUT, r16               
	rjmp main_loop


;*****************************************************************************
;* 
;* "serial_recieve" - read_ASCII_character
;*
;* Description:
;* Polls PB1 to detect negative edge (start of the frame), and checks for a 
;* framing error (incorrect stop bit). Returns character to r16, and includes
;* the carry flag set if stop bit is incorrect.
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;* Number of words: 22
;* Number of cycles: Depends on when the negative edge comes
;* Low registers modified: None
;* High registers modified: r16, r17, r18
;*
;* Parameters: None
;*
;* Returns: 7 bit character to r16 and carry flag C
;*
;* Notes: Frequency: 4MHz, Baud: 9600
;*
;***************************************************************************** 

serial_recieve:
wait_for_1:
	sbis VPORTB_IN, 1                   ;skips next line if PB1 is 1 (start bit)
	rjmp wait_for_1                      

wait_for_0:
	sbic VPORTB_IN, 1                   ;skips next line if PB1 is 0 (start bit)
	rjmp wait_for_0                     ;loops while PB1 is high

	rcall half_bit_time_52us            ;delays half a bit time to check that the bit will still be 0

	sbic VPORTB_IN, 1                   ;checks that PB1 is still 0
	rjmp wait_for_1

	ldi r17, 8                          ;lcv
bit_loop:
	rcall bit_time_104us                ;one bit time delay after each bit

	sbic VPORTB_IN, 1                   ;checks if PB1 is 0
	sec                                 ;Sets Carry flag high

	ror r18                             ;rotate carry bit into MSB
	dec r17                             ;decrements loop counter
	brne bit_loop                       ;Goes through all 8 bits

	rcall bit_time_104us
	rjmp stop_bit

	sec                                 ;Sets Carry Flag (FE = 1)
	mov r16, r18                        ;moves the bits into r16
	ret
stop_bit:
	clc                                 ;Clears Carry Flag (FE = 0)
	mov r16, r18                        ;moves the bits into r16
	ret

;*****************************************************************************
;* 
;* "half_bit_time_52us" - read_ASCII_character
;*
;* Description:
;*	 Generates a 52us delay which is 208 clock cycles using our 4Mhz frequency
;* and it represents half a bit time for 9600 serial baud. 
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;* Number of words: 5
;* Number of cycles: 206 (208 if we include rcall)
;* Low registers modified: None
;* High registers modified: r16
;*
;* Parameters: None
;*
;* Returns: None
;*
;* Notes: Clock rate = 0.25us/cycle, 52us * 0.25us/cycle = 208 cycles
;*
;***************************************************************************** 

half_bit_time_52us:
	ldi r16, 67			                // 1 clock
half_bt_loop:
	dec r16					            // 1 clock
	brne half_bt_loop		            // 2/1 clocks
	nop                                 // 1 padding
	ret						            // 4

;*****************************************************************************
;* 
;* "bit_time_104us" - read_ASCII_character
;*
;* Description:
;*	 Generates a 104us delay which is 416 clock cycles using our 4Mhz frequency
;* and it represents a bit time for 9600 serial baud. 
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;* Number of words: 6
;* Number of cycles: 414 (416 if we include rcall)
;* Low registers modified: None
;* High registers modified: r16
;*
;* Parameters: None
;*
;* Returns: None
;*
;* Notes: Clock rate = 0.25us/cycle, 104us * 0.25us/cycle = 416 cycles
;*
;***************************************************************************** 

bit_time_104us:
	ldi r16, 136                        // 1 clock
bt_loop:
	dec r16                             // 1 clock
	brne bt_loop                        // 2/1 clocks
	nop                                 // 2 padding
	nop
	ret                                 // 4



