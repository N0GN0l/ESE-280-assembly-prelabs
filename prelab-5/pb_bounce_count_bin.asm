.nolist
.include "m4809def.inc"
.list

start:
	cbi VPORTE_DIR, 0	;setup VPORTE bit 0 to be input
	ldi r16, 0xFF	
	out VPORTD_DIR, r16	;set all bits of VPORTD to output
	ldi r17, 0x00	;set up r17 to 0
	ldi r18, 0x00	;set up r18 to 0
	out VPORTD_OUT, r17	;set up VPORTD to display initial value

wait_for_0:
	sbic VPORTE_IN, 0	;if the bit is 1 then it will continously loop back to the beginning 
	rjmp wait_for_0

wait_for_1:
	sbis VPORTE_IN, 0	;if the bit is 0 then it will continously loop to wait for a 1
	rjmp wait_for_1

	inc r17		;r17 is incremented by 1
	rjmp display 

display:	;turns on LED'S
	mov r18, r17	;copies r17 to not affect the counter
	com r18		;LED are active low so we compliment it
	out VPORTD_OUT, r18		;output values to LED bits
	rjmp wait_for_0		;goes back to waiting for a 0
