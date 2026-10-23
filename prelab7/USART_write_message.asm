;
; USART_write_message.asm
;
; Created: 10/21/2026 4:30:13 PM
; Author : str22
;
;===================================
;Description
;This program uses the USART hardware to send the "Hello World What happens now" message
;Combines Task 2 and Task 3
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


	ldi r18, '|'		;|
	rcall serial_send	;Call the output subroutine
	
	ldi r18, '-'
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

main_loop:
	rjmp main_loop


serial_send:
	lds r16, USART3_STATUS  ;Reads USART3 status register
	sbrs r16, 5             ;Skip next line if DRIEF is 1
	rjmp serial_send

	sts USART3_TXDATAL, r18  ;writes content of r18 into the trasnmit buffer register

	ret

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
