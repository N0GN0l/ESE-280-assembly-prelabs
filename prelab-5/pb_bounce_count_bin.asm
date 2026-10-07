.nolist
.include "m4809def.inc"
.list

start:
	cbi VPORTE_DIR, 0	;setup VPORTE bit 0 to be input
	ldi r16, 0xFF	
	out VPORTD_DIR, r16	;set all bits of VPORTD to output
	ldi r17, 0x00	;set up r17 to 0
	out VPORTD_OUT, r17	;set up VPORTD to display initial value

wait_for_0:
	sbic VPORTE_IN, 0	;if the bit is 1 then it will continously loop back to the beginning 
	rjmp wait_for_0

wait_for_1:
	sbis VPORTE_IN, 0	;if the bit is 0 then it will continously loop to wait for a 1
	rjmp wait_for_1

	cpi r17, 0xFF	;check to see if the next increment should be a rollover
	breq roll_over	

	inc r17		;if the check fails then r17 is incremented by one
	out VPORTD_OUT, r17	;outputs the value of r17 to display on VPORTD
	rjmp wait_for_0		;goes back to waiting for a 0
	 
roll_over:
	ldi r17, 0x00	;resets r17
	out VPORTD_OUT, r17	;needs to still output to VPORTD
	rjmp wait_for_0
