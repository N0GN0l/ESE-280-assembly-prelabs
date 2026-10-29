start:
  cbi VPORTB_DIR, 1    ;Set PB1 to input
  ;sbi VPORTB_OUT, 0    ;Set the initial value of VPORTB 0 to high

  ldi r16, 0xFF
  out VPORTD_DIR, r16

  ldi r16, 0xFF
  out VPORTD_OUT, r16

  ldi r16, LOW(1667)      ;Load Baud register for 9600 baud
  sts USART3_BAUDL, r16
  ldi r16, HIGH(1667)     ;Baud Formula: (4 * f_clk) / baud = (4 * 4M) / 9600 = 1667 = 0x0683
  sts USART3_BAUDH, r16

  ldi r16, 0x03           ;Sets the frame format: 8N1 and sets Character Size to 8-bits
  sts USART3_CTRLC, r16

  ldi r16, 0x80           ;Enables Receiver (00100000 receiver enable is bit 7 set)
  sts USART3_CTRLB, r16


main_loop:

  rcall serial_receive_hdwe

  com r16
  out VPORTD_OUT, r16

  rjmp main_loop

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
t
