;
; read_ASCII_char_hdwe.asm
;***************************************************************************
;*
;* Title: Lab 08: Software and Hardware Serial Recievers, Design Task 3
;* Author: Daniel Zhou and Sophia Rahman
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;*
;* DESCRIPTION
;* This program uses USART3 Rx pin to poll the start bit and read the ASCII 
;* character. In the subroutine "serial_recieve_hdwe", it recieves the 
;* character and returns it to r16 along with a carry flag that represents
;* if there was framing error. 
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************

.nolist 
.include "m4809def.inc"
.list

start:
  cbi VPORTB_DIR, 1    ;Set PB1 to input
  sbi VPORTB_OUT, 0    ;Set the initial value of VPORTB 0 to high

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

;*****************************************************************************
;* 
;* "serial_recieve_hdwe" - read_ASCII_char_hdwe
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
