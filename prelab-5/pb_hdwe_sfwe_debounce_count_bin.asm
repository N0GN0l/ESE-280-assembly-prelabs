;
; AssemblerApplication2.asm
;
; Created: 10/7/2026 5:00:14 PM
; Author : str22
;


; Replace with your application code
.nolist
.include "m4809def.inc"
.list

start:
	cbi VPORTE_DIR, 0    ;setup VPORTE bit 0 to be input
	sbi VPORTE_DIR, 1    ;setup VPORTE bit 1 to be output
	cbi VPORTE_DIR, 2    ;setup VPORTE bit 2 to be input
	sbi VPORTE_OUT, 1    ;CLR is active low so set pin high

	ldi r16, 0xFF	
	out VPORTD_DIR, r16	 ;set all bits of VPORTD to output
	ldi r17, 0x00	     ;set up r17 to 0
	out VPORTD_OUT, r17	 ;set up VPORTD to display initial value
	ldi r16, 200        ;25.6ms/0.1ms = 256, 256 is out of range so I put 200

wait_for_flag:
	sbis VPORTE_IN, 0	 ;if the bit is 0 then it will continously loop back to the beginning 
	rjmp wait_for_flag

display_and_update:
	sbi VPORTE_OUT, 1	;reset PE1 so that the flip-flop doesnt get constantly cleared
	cpi r17, 0xFF	     ;check to see if the next increment should be a rollover
	breq roll_over	

	inc r17		         ;if the check fails then r17 is incremented by one
	out VPORTD_OUT, r17	 ;outputs the value of r17 to display on VPORTD

	cbi VPORTE_OUT, 1    ;reset the flip flop 

	sbic VPORTE_IN, 2
	rcall var_delay
	rjmp wait_for_flag

roll_over:
	ldi r17, 0x00	     ;resets r17
	out VPORTD_OUT, r17	 ;needs to still output to VPORTD
	rjmp wait_for_flag

var_delay:               ;delay for avr128db48 @ 4.00 MHz = r16 * 0.100475 ms
outer_loop:
	ldi r18, 133
inner_loop:
	dec r18
	brne inner_loop
	dec r16
	brne outer_loop
	ret
