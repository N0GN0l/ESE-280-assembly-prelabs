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
	cbi VPORTE_OUT, 1	 ;Clear the flipflop
	sbi VPORTE_OUT, 1    ;CLR is active low so default the pin high

	ldi r16, 0xFF	
	out VPORTD_DIR, r16	 ;set all bits of VPORTD to output
	ldi r17, 0x00	     ;set up r17 to 0
	ldi r18, 0x00		;set up r18 to 0
	out VPORTD_OUT, r17	 ;set up VPORTD to display initial value
	ldi r16, 200        ;25.6ms/0.1ms = 256, 256 is out of range so I put 200

wait_for_flag:
	sbis VPORTE_IN, 0	 ;if the bit is 0 then it will continously loop back to the beginning 
	rjmp wait_for_flag

display_and_update:
	sbis VPORTE_IN, 0
	rjmp display_and_update		;program waits for the bit at PE0 is 1

	inc r17		;r17 is incremented by one

	rcall var_delay		;delay before increment

	mov r18, r17	;Need to copy the data so that the counter doesn't break
	com r18		;LED are active low
	out VPORTD_OUT, r20	 ;outputs the value of r17 to display on VPORTD

wait_for_release:
	sbic VPORTE_OUT, 2   ;if the bit is 1 then it will continously loop back to the beginning
	rjmp wait_for_release

	rcall var_delay		;delay before resetting the flipflop

	cbi VPORTE_OUT, 1    ;resets the FF flag
	sbi VPORTE_OUT, 1    ;goes back to high

	rjmp wait_for_flag	 ;goes back to waiting for the flag



var_delay:               ;delay for avr128db48 @ 4.00 MHz = r16 * 0.100475 ms
outer_loop:
	ldi r20, 133
inner_loop:
	dec r20
	brne inner_loop
	dec r16
	brne outer_loop
	ret
