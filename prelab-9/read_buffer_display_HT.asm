.nolist
.include "AVR128DB48def.inc"
.list


.dseg
mem_buffer: .byte 18 			;The module outputs a string of 18 characters, each char is 1 byte
buff_flag: .byte 1 				;Memory flag, 1 = a complete string is in mem_buffer and ready to be processed



.cseg
.org 0x0000
rjmp start ;Jump over the reset subroutine so the CPU actually reaches start

reset:
    ldi YL, LOW(mem_buffer) ;Initialize the pointer to the buffer
    ldi YH, HIGH(mem_buffer)
    ret

    start:
    ldi r16, 0x80 				;Setup USART1 and 3 at the same time
    sts USART1_CTRLB, r16 		;Enable the reciever of USART1
    ldi r16, 0x40
    sts USART3_CTRLB, r16 		;Enable the trasmission of USART3

    ldi r16, LOW(1667)
    sts USART1_BAUDL, r16
    sts USART3_BAUDL, r16
    ldi r16, HIGH(1667)
    sts USART1_BAUDH, r16
    sts USART3_BAUDH, r16

    ldi r16, 0x03
    sts USART1_CTRLC, r16
    sts USART3_CTRLC, r16

    sbi VPORTB_DIR, 0 			;Make PB0 an output as it is the transmision pin for USART3
    cbi VPORTC_DIR, 1 			;Make PC1 an input as it is the RX pin for USART1

    clr r16
    sts buff_flag, r16 ;Clear the memory flag at startup
    rcall reset ;Point Y at the start of mem_buffer before any characters come in










main_loop:
    rcall serial_receive_hdwe_buff
    rcall memory_buffer_to_LCD
    rjmp main_loop





;**********************************
;*
;*
;*
;*
;*
;*********************************
serial_receive_hdwe_buff:
    lds r16, USART1_STATUS  			;Reads USART1 status register
    sbrs r16, 7             			;Skip next line if RXCIF is 1, receive complete is RXCIF
    rjmp serial_receive_hdwe_buff

    lds r18, USART1_RXDATAH 			;Store the receiver data into r18 (FERR is bit 2 of RXDATAH)
    sbrs r18, 2 ;FERR
    rjmp frame_good

    sec
    rjmp read_data

frame_good:
    clc

read_data:
    lds r16, USART1_RXDATAL
    st Y+, r16 								;Store the character into the mem_buffer and then increment the pointer so that the next go around, it will store

    ldi r18, LOW(mem_buffer + 18) 			;Store the value of the LOW half of mem_buffer, plus 18 which will be the position of the YL pointer when the string is completed
    ldi r19, HIGH(mem_buffer + 18) 			;Store the value of the HIGH half of the mem_buffer, plus 18 which will be the position of the YH pointer when the string is completed

    cp YL, r18 					;Compare the pointer against r18, which curretly stores the value of the LOW half of mem_buffer + 18
    cpc YH, r19 				;Compare with carry the pointer against r19, which currently stores the value of the HIGH half of the mem_buffer + 18
    breq buff_full 				;If both comparisons run true, then the buffer is full and we set the memory flag buff_flag to 1
    rjmp return 				;If the comparisons fail, then we just return from the subroutine
buff_full:
    ldi r16, 1
    sts buff_flag, r16 			;Set the memory flag to show a complete string has been received
    rcall reset 				;Put the Y pointer back to the start of the buffer for the next string
    return:
    ret


;*******************************
;*
;*
;*
;*
;*
;******************************
memory_buffer_to_LCD:
    lds r16, buff_flag 			;Load the memory flag
    tst r16
    breq send_return 			;If the flag is not set then immediately skip to the return of the subroutine
    ldi r21, 18 				;Loop counter varaible
    ldi ZL, LOW(mem_buffer) 			;Z is the read pointer, set it back to the beginning of the buffer (Y stays as the write pointer)
    ldi ZH, HIGH(mem_buffer)
send_loop:
    dec r21 					;Execute then count loop
    ld r18, Z+ 					;load the character at the pointer into r18, then increment
    rcall serial_send 			;call serial_send to send the character that was stored into r18 to the LCD
    cpi r21, 0 					;See if the loop has completed yet
    brne send_loop 				;If not loop back

    clr r16
    sts buff_flag, r16 			;Clear the memory flag after the loop finishes
    ret 						;Separate return for the "string was sent" path, put the breakpoint here
    send_return:
    ret





serial_send:
    lds r16, USART3_STATUS  	;Reads USART3 status register
    sbrs r16, 5             	;Skip next line if DRIEF is 1
    rjmp serial_send

    sts USART3_TXDATAL, r18  	;writes content of r18 into the trasnmit buffer register

    ret
