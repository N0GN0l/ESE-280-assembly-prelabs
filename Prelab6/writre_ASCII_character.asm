.nolist
.include "AVR128DB48def.inc"
.list

;===================================
;Description
;This program using subroutines and delays to output a ASCII character frame from PB0
;The ASCII character is determined by r16 while the rest of the frame is predetermined
;
;===================================

start:
	ldi r17 0x09
	sbi VPORTB_DIR, 0	;Set PB0 to output and use r17 as the loop control varaible
	sbi VPORTB_OUT, 0	;Set the initial value of VPORTB 0 to high
main_loop:
	rcall serial_send	;Call the output subroutine
	rjmp delay_500ms	;There needs to be a delay between the output of each ASCII character sequence


;=========================================
;Serial send function
;Used to output the ASCII character using PB0
;
;First bit must be low, next 8 bits will be determined by a GP register, P bit is 0, then one high bit for STOP
;========================================

serial_send:
	ldi r16 0x44	;Output character D using ASCII code 0x44 
	sbi VPORTB_OUT, 0	;Initial bit of the frame is always 0
	rcall bit_time_104us
bit_sequence_loop:
	lsr r16
	brcc output_zero
	brcs output_one
bit_delay:
	rcall bit_time_104us
	dec r17
	brne bit_sequence_loop
	cbi VPORTB_OUT, 0	;Ending logic to output P = 0
	rcall bit_time_104us
	sbi VPORTB_OUT, 0	;S1 = 1
	ret




;===========================
;Helper functions:
;
;Functions change the output of PB0 based off of the value of the carry bit
;
;===========================
output_zero:
	cbi VPORTB_OUT, 0
	rjmp bit_delay
	
output_one:
	sbi VPORTB_OUT, 0
	rjmp bit_delay
	


;====================
;Delay functions:


bit_time_104us:
	ldi r16, 136
bt_loop:
	dec r16
	brne bt_loop
	nop
	nop
	ret





delay_500ms:
	ldi r30, LOW(2601)
	ldi r31, HIGH(2601)	
	rjmp main_loop
