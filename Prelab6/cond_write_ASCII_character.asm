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
	ldi r16, 0x00         ;PC7 - PC0 set as inputs (Switch Bank)
	out VPORTC_DIR, r16

	cbi VPORTE_DIR, 0     ;PE0 set as input
	sbi VPORTE_DIR, 1     ;PE1 set as output
	cbi VPORTE_DIR, 2     ;PE2 set as input

	sbi VPORTE_OUT, 1     ;sets PE1 high

	cbi VPORTE_OUT, 2	  ;reset the flipflop at startup
	sbi VPORTE_OUT, 2	  ;make sure the flipflop is not constantly reset

	sbi VPORTB_DIR, 0	;Set PB0 to output and use r20 as the loop control varaible, there are 7 bits so the register is n+1=8
	sbi VPORTB_OUT, 0	;Set the initial value of VPORTB 0 to high




wait_for_flag:
	sbis VPORTE_IN, 0     ;skip rjmp if PE0 is 1
	rjmp wait_for_flag

	in r16, VPORTC_IN     ;reads data from PORTC into r16


wait_for_release:
	sbic VPORTE_IN, 2    ;skip rjmp is PE2 is 0
	rjmp wait_for_release

	ldi r23, 100          ;i remember prof. short saying something was 10ms
	rcall var_delay

	cbi VPORTE_IN, 1      ;resets flag
	sbi VPORTE_IN, 1      ;sets PE1 high

	rcall serial_send
	rjmp delay_500ms
	rjmp wait_for_flag

var_delay:
outer_loop:
	ldi r18, 133
inner_loop:
	dec r18
	brne inner_loop
	dec r23
	brne outer_loop
	ret

;=========================================
;Serial send function
;Used to output the ASCII character using PB0
;
;First bit must be low, next 8 bits will be determined by a GP register, P bit is 0, then one high bit for STOP
;========================================

serial_send:
	ldi r17, 0x08
	;Output character D using ASCII code 0x44 
	cbi VPORTB_OUT, 0	;Initial bit of the frame is always 0
	rcall bit_time_104us
bit_sequence_loop:
	lsr r16
	brcc output_zero
	brcs output_one
bit_delay:
	rcall bit_time_104us
	dec r17
	brne bit_sequence_loop
	sbi VPORTB_OUT, 0	;S1 = 1
	rcall bit_time_104us
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
	ldi r21, 136
bt_loop:
	dec r21
	brne bt_loop
	nop
	nop
	ret





delay_500ms:
	ldi r30, LOW(2601)
	ldi r31, HIGH(2601)	
	rjmp wait_for_flag
