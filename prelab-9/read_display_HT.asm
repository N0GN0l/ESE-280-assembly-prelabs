






start:
	ldi r16, 0x80			;Setup USART1 and 3 at the same time
	sts USART1_CTRLB, r16		;Enable the reciever of USART1
	ldi r16, 0x40
	sts USART3_CTRLB, r16		;Enable the trasmission of USART3

	ldi r16, LOW(1667)
	sts USART1_BAUDL, r16
	sts USART3_BAUDL, r16
	ldi r16, HIGH(1667)
	sts USART1_BAUDH, r16
	sts USART3_BAUDH, r16
	
	ldi r16, 0x03
	sts USART1_CTRLC, r16
	sts USART3_CTRLC, r16

	sbi VPORTB_DIR, 0	;Make PB0 an output as it is the transmision pin for USART3
	cbi VPORTC_DIR, 0	;Make PC0 an input as it is the RX pin for USART1

main_loop:
	rcall serial_recvieve_hdwe
	rcall serial_transmit
	
	rjmp main_loop

serial_recieve_hdwe:
	lds r16, USART3_STATUS  ;Reads USART3 status register
	sbrs r16, 7             ;Skip next line if RXCIF is 1, receive complete is RXCIF
	rjmp serial_receive_hdwe

	lds r18, USART3_RXDATAH		;Store the receiver data into r18
	sbrs r16, 2 ;FERR
	rjmp frame_good

	sec
	rjmp read_data

frame_good:
	clc

read_data:
	lds r16, USART3_RXDATAL
	ret






serial_transmit:
	serial_send:
	lds r16, USART3_STATUS  ;Reads USART3 status register
	sbrs r16, 5             ;Skip next line if DRIEF is 1
	rjmp serial_send

	sts USART3_TXDATAL, r18  ;writes content of r18 into the trasnmit buffer register

	ret
