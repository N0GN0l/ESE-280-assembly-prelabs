;
; loop_back_test.asm
;***************************************************************************
;*
;* Title: Lab 08: Software and Hardware Serial Recievers, Design Task 4
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;*
;* DESCRIPTION
;* In this program, we check if the USART is functional by applying a 
;* loop back test. We test this by connect the Rx pin to the Tx so Rx
;* can read Tx data. We use three subroutines. serial_send to send the character
;* "U" into the USART. Then a delay_500ms for timing. And then serial_reiceve_hdwe
;*  to read the character and display it.
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************

.nolist
.include "m4809def.inc"
.list

start:
    ldi r16, 0xFF                     ;PD7 - PD0 output
	out VPORTD_DIR, r16
	cbi VPORTB_DIR, 1                 ;PB1 input, Rx pin
	
	ldi r16, LOW(1667)			      ;Set BAUD rate
	sts USART3_BAUDL, r16
	ldi r16, HIGH(1667)
	sts USART3_BAUDH, r16
	
	ldi r16, 0x03		
	sts USART3_CTRLC, r16		      ;Set frame format
	
	ldi r16, 0xC0
	sts USART3_CTRLB, r16		      ;Enable both the transmitter and the reciever
	
	ldi r16, 0x08
	sts USART3_CTRLA, r16		      ;Enables the internal mux top side, so that RX takes in TX data

main_loop:
	ldi r18, 'U'
	rcall serial_send
	rcall delay_500ms
	
	rcall serial_receive_hdwe
	
	rcall display

	rjmp main_loop	
	
display:
	com r16
	out VPORTD_OUT, r16		          ;Outputs r16 to led bargraph
	ret

;*****************************************************************************
;* 
;* "serial_recieve_hdwe" - loop_back_test
;*
;* Description:
;* Reads the status register and once it is good, it reads the ASCII characters
;* into r16 and checks if there was a framing error and based on that 
;* it sets or clears the carry flag. 
;*
;* Author: Daniel Zhou and Sophia Rahman
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;* Number of words: 14
;* Number of cycles: Varies
;* Low registers modified: None
;* High registers modified: r16
;*
;* Parameters: None
;*
;* Returns: ASCII char in r16 and carry flag
;*
;* Notes: RXCIF is bit 7, FERR is bit 2, RXDATAL holds all the data
;*
;***************************************************************************** 
serial_receive_hdwe:

  lds r16, USART3_STATUS  ;Reads USART3 status register
  sbrs r16, 7             ;Skip next line if RXCIF is 1, receive complete is RXCIF
  rjmp serial_receive_hdwe

  lds r16, USART3_RXDATAH
  sbrs r16, 2 ;FERR
  rjmp frame_good

  sec
  rjmp read_data

frame_good:
  clc

read_data:
  lds r16, USART3_RXDATAL
  ret



;*****************************************************************************
;* 
;* "serial_send" - loop_back_test
;*
;* Description:
;* Reads the status register and checks that it's ready to accept a new byte to 
;* send and then writes into the transmit buffer register.
;*
;* Author: Daniel Zhou and Sophia Rahman
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;* Number of words: 7
;* Number of cycles: Varies
;* Low registers modified: None
;* High registers modified: r16, r18
;*
;* Parameters: None
;*
;* Returns: ASCII char into transmit buffer register
;*
;* Notes: DRIEF is bit 5, TXDATAL is for the day to transmit
;*
;***************************************************************************** 
serial_send:
	lds r16, USART3_STATUS  ;Reads USART3 status register
	sbrs r16, 5             ;Skip next line if DRIEF is 1
	rjmp serial_send

	sts USART3_TXDATAL, r18  ;writes content of r18 into the trasnmit buffer register

	ret


;*****************************************************************************
;* 
;* "delay_500ms" - loop_back_test
;*
;* Description:
;* Delays 500ms using nested loop counters.
;*
;* Author: Daniel Zhou and Sophia Rahman
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;* Number of words: 9
;* Number of cycles: 2,000,000
;* Low registers modified: None
;* High registers modified: r25, r30, r31
;*
;* Parameters: None
;*
;* Returns: None
;*
;* Notes: Uses Z point register (r30:r31)
;*
;***************************************************************************** 
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
