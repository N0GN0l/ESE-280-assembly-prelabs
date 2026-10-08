;
; conditional_input_sftwe.asm
;
; Created: 10/8/2026 1:39:25 AM
; Author : str22
;


; Replace with your application code
.nolist
.include "m4809def.inc"
.list

start:
	ldi r16, 0x00         ;PC7 - PC0 set as inputs (Switch Bank)
	out VPORTC_DIR, r16

	ldi r16, 0xFF         ;PD7 - PD0 set as outputs (Bargraph)
	out VPORTD_DIR, r16

	cbi VPORTE_DIR, 0     ;PE0 set as input
	sbi VPORTE_DIR, 1     ;PE1 set as output
	cbi VPORTE_DIR, 2     ;PE2 set as input

	sbi VPORTE_OUT, 1     ;sets PE1 high

	cbi VPORTE_OUT, 2	  ;reset the flipflop at startup
	sbi VPORTE_OUT, 2	  ;make sure the flipflop is not constantly reset

	ldi r17, 0x00	;setup r17 to 0
	ldi r18, 0x00	;setup r18 to 0


wait_for_flag:
	sbis VPORTE_IN, 0     ;skip rjmp if PE0 is 1
	rjmp wait_for_flag

	in r17, VPORTC_IN     ;reads data from PORTC into r17
	mov r18, r17
	com r18		;LED are active low
	out VPORTD_OUT, r18   ;displays onto bargraph


wait_for_release:
	sbic VPORTE_IN, 2    ;skip rjmp is PE2 is 0
	rjmp wait_for_release

	ldi r16, 100          ;i remember prof. short saying something was 10ms
	rcall var_delay

	cbi VPORTE_IN, 1      ;resets flag
	sbi VPORTE_IN, 1      ;sets PE1 high

	rjmp wait_for_flag

var_delay:
outer_loop:
	ldi r18, 133
inner_loop:
	dec r18
	brne inner_loop
	dec r16
	brne outer_loop
	ret


