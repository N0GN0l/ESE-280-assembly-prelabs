








start:
    ldi r16, 0xFF                     ;PD7 - PD0 output
	out VPORTD_DIR, r16
	cbi VPORTB_DIR, 1                 ;PB1 input, Rx pin
	
	ldi r16, LOW(1667)			;Set BAUD rate
	sts USART3_BAUDL, r16
	ldi r16, HIGH(1667)
	sts USART3_BAUDH, r16
	
	ldi r16, 0x03		
	sts USART3_CTRLC, r16		;Set frame format
	
	ldi r16, 0xC0
	sts USART3_CTRLB, r16		;Enable both the transmitter and the reciever
	
	ldi r16, 0x08
	sts USART3_CTRLA, r16		;Enables the internal mux top side, so that RX takes in TX data



main_lopp:
	ldi r18, 'U'
	rcall serial_send
	rcall delay_500ms
	
	rcall serial_read_hdwe
	
	rcall display

	rjmp main_loop	
	
	


display:
	com r16
	out VPORTD_OUT, r16		;Outputs r16 to led bargraph
	ret



;*******************************************************
;*
;* "serial_recieve_hdwe" - USART reading subroutine
;*
;*
;*
;*******************************************************





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



;********************************************************
;*
;* "serial_send" - USART transmission subroutine
;* Notes: 
;*
;*
;*******************************************************




serial_send:
	lds r16, USART3_STATUS  ;Reads USART3 status register
	sbrs r16, 5             ;Skip next line if DRIEF is 1
	rjmp serial_send

	sts USART3_TXDATAL, r18  ;writes content of r18 into the trasnmit buffer register

	ret





;*****************************************************************************
;* 
;* "delay_500ms" - 500ms Delay Subroutine
;* Notes: 
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
