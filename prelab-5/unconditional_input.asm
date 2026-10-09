;
; AssemblerApplication3.asm
;
; Created: 10/7/2026 11:17:35 PM
; Author : str22
;


.nolist
.include "m4809def.inc"
.list

start:
	ldi r16, 0x00         ;sets PC7-PC0 as inputs
	out VPORTC_DIR, r16

	ldi r16, 0xFF         ;sets PD7-PD0 as outputs
	out VPORTD_DIR, r16
	ldi r17, 0x00

loop:
	in r16, VPORTC_IN     ;reads inputs from PC7-PC0
	mov r17, r16
	com r17
	out VPORTD_OUT, r17   ;outputs the contents of r16 into the bargraph led
	rjmp loop

