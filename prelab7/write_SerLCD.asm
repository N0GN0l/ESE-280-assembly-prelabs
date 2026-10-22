.nolist
.include "AVR128DB48def.inc"
.list

;===================================
;Description
;This program using subroutines and delays to output  ASCII characters frame from PB0
;The ASCII character is determined by r16 while the rest of the frame is predetermined
;Each ASCII character is output in order to create the prase:
;Hello World
;What happens now
;===================================

start:
	ldi r17, 0x08
	sbi VPORTB_DIR, 0	;Set PB0 to output and use r17 as the loop control varaible
	sbi VPORTB_OUT, 0	;Set the initial value of VPORTB 0 to high
main_loop:
	ldi r16, 0x7C		;|
	rcall serial_send	;Call the output subroutine
	
	ldi r16, 0x2E		;.
	rcall serial_send
	
	ldi r18, 'H'
	rcall serial_send
	
	ldi r18, 'e'
	rcall serial_send
	
	ldi r18, 'l'
	rcall serial_send
	
	ldi r18, 'l'
	rcall serial_send
	
	ldi r18, 'o'
	rcall serial_send

	ldi r18, 0x20		;space
	rcall serial_send

	ldi r18, 'W'
	rcall serial_send

	ldi r18, 'o'
	rcall serial_send

	ldi r18, 'r'
	rcall serial_send
	
	ldi r18, 'l'
	rcall serial_send

	ldi r18, 'd'
	rcall serial_send

	ldi r18, 0x0D		;CR
	rcall serial_send
	
	ldi r18, 0x0A		;LR
	rcall serial_send

	ldi r18, 'W'
	rcall serial_send
	
	ldi r18, 'h'
	rcall serial_send

	ldi r18, 'a'
	rcall serial_send

	ldi r18, 't'
	rcall serial_send

	ldi r18, 0x20		;space
	rcall serial_send

	ldi r18, 'h'
	rcall serial_send

	ldi r18, 'a'
	rcall serial_send

	ldi r18, 'p'
	rcall serial_send
	
	ldi r18, 'p'
	rcall serial_send
	
	ldi r18, 'e'
	rcall serial_send

	ldi r18, 'n'
	rcall serial_send
	
	ldi r18, 's'
	rcall serial_send

	ldi r18, 0x20
	rcall serial_send

	ldi r18, 'n'
	rcall serial_send
	
	ldi r18, 'o'
	rcall serial_send

	ldi r18, 'w'
	rcall serial_send

;=========================================
;Serial send function
;Used to output the ASCII character using PB0
;
;First bit must be low, next 8 bits will be determined by a GP register, P bit is 0, then one high bit for STOP
;========================================

serial_send: 
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
	rcall bit_time_104us
	rcall delay_500ms
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
	ret
