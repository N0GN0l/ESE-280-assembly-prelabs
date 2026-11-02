tart:
    ldi r16, 0x80
    sts USART1_CTRLB, r16 ; RXEN for USART1
    ldi r16, 0x40
    sts USART3_CTRLB, r16 ; TXEN for USART3

    ldi r16, LOW(1667)
    sts USART1_BAUDL, r16
    sts USART3_BAUDL, r16
    ldi r16, HIGH(1667)
    sts USART1_BAUDH, r16
    sts USART3_BAUDH, r16

    ldi r16, 0x03 ; async, 8N1
    sts USART1_CTRLC, r16
    sts USART3_CTRLC, r16

    sbi VPORTB_DIR, 0 ; PB0 = USART3 TX (output)
    sbi VPORTB_OUT, 0 ; idle high
    cbi VPORTC_DIR, 1 ; PC1 = USART1 RX (input)

main_loop:
    rcall serial_receive_hdwe
    rjmp main_loop

serial_receive_hdwe:
    lds r16, USART1_STATUS
    sbrs r16, 7 ; RXCIF
    rjmp serial_receive_hdwe
    
    lds r17, USART1_RXDATAH ; read H first (error flags)
    lds r18, USART1_RXDATAL ; then the data
    sbrc r17, 2 ; FERR set? skip writing bad char
    ret

serial_send:
    lds r16, USART3_STATUS
    sbrs r16, 5 ; DREIF
    rjmp serial_send
    sts USART3_TXDATAL, r18 ; write char to LCD
    ret
