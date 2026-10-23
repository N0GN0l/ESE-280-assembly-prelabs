;
; USART3_asynch_test.asm
;
; Created: 10/20/2026 6:35:27 PM
; Author : str22
;


; Replace with your application code
;===================================
;Description
;This program contains a loop that repeatedly transmits character A - Z repeatedly 
;It verifies that the USART hardware transmitter works
;Baud rate: 9600, Frame format: 8N1, Asynchronous Hardware Transmit with DRIEF polling
;===================================

.nolist
.include "AVR128DB48def.inc"
.list

start:
	sbi VPORTB_DIR, 0	    ;Set PB0 to output
	sbi VPORTB_OUT, 0	    ;Set the initial value of VPORTB 0 to high

	ldi r16, LOW(1667)      ;Load Baud register for 9600 baud 
	sts USART3_BAUDL, r16
	ldi r16, HIGH(1667)     ;Baud Formula: (4 * f_clk) / baud = (4 * 4M) / 9600 = 1667 = 0x0683
	sts USART3_BAUDH, r16

	ldi r16, 0x03           ;Sets the frame format: 8N1 and sets Character Size to 8-bits
	sts USART3_CTRLC, r16

	ldi r16, 0x40           ;Enables Transmitter
	sts USART3_CTRLB, r16
	rcall delay_500ms		;Account for setup time


	ldi r18, '|'
wait_for_DRIEF1:
	lds r16, USART3_STATUS  ;Reads USART3 status register
	sbrs r16, 5             ;Skip next line if DRIEF is 1
	rjmp wait_for_DRIEF1

	sts USART3_TXDATAL, r18  ;writes content of r18 into the trasnmit buffer register

	rcall delay_500ms




	ldi r18, '-'
wait_for_DRIEF2:
	lds r16, USART3_STATUS  ;Reads USART3 status register
	sbrs r16, 5             ;Skip next line if DRIEF is 1
	rjmp wait_for_DRIEF2

	sts USART3_TXDATAL, r18  ;writes content of r18 into the trasnmit buffer register
	rcall delay_500ms

reset_ch:
	ldi r18, 'A'           ;Loads 'A' into the register

wait_for_DRIEF:
	lds r16, USART3_STATUS  ;Reads USART3 status register
	sbrs r16, 5             ;Skip next line if DRIEF is 1
	rjmp wait_for_DRIEF

	sts USART3_TXDATAL, r18  ;writes content of r18 into the trasnmit buffer register

	cpi r18, 0x5A           ;checks if r18 is 'Z'
	breq reset_ch           ;if equal, it gets reset to 'A'

	inc r18                 ;Increments r18 to the next letter
	rcall delay_500ms
	rjmp wait_for_DRIEF     ;Goes back to waiting for the flag
		

delay_500ms:
	ldi r30, LOW(2601)
	ldi r31, HIGH(2601)

outer_loop:
	ldi r25, $FF
inner_loop:
	dec r25
	brne inner_loop
	sbiw r31:r30, 1
	brne outer_loop
	ret
