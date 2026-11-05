;
; read_display_HT.asm
;***************************************************************************
;*
;* Title: Lab 09: Humidity and Temperature Measurements, Design Task 2
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0
;* Last updated: 11/4/2026
;* Target: AVR128DB48
;*
;* DESCRIPTION
;* In this program, the measurements from the SHT40 sensor are read using 
;* USART1 and then sent to be displayed on the SerLCD display using USART3.
;* The frame format is 8N1 and the baud rate is 9600 baud. There are two
;* subroutines utilized; serial_recieve_hdwe and serial_send.
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************

.nolist
.include "avr128db48def.inc"
.list

start:
    ldi r16, 0x80
    sts USART1_CTRLB, r16           ; RXEN for USART1
    ldi r16, 0x40
    sts USART3_CTRLB, r16           ; TXEN for USART3

    ldi r16, LOW(1667)
    sts USART1_BAUDL, r16
    sts USART3_BAUDL, r16
    ldi r16, HIGH(1667)
    sts USART1_BAUDH, r16
    sts USART3_BAUDH, r16

    ldi r16, 0x03                   ; async frame format, 8N1
    sts USART1_CTRLC, r16
    sts USART3_CTRLC, r16

    sbi VPORTB_DIR, 0               ; PB0 = USART3 TX (output)
    sbi VPORTB_OUT, 0               ; idle high
    cbi VPORTC_DIR, 1               ; PC1 = USART1 RX (input)

main_loop:
    rcall serial_receive_hdwe  
    rjmp main_loop


;***************************************************************************
;* 
;* "serial_recieve_hdwe" - read_display_HT
;*
;* Description:
;* Reads the status register of USART1 and verifies that it is ready to read
;* the ASCII character into r16. Then checks if there was any framing errors
;* and then loads the data into r18. 
;*
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0
;* Last updated: 11/4/2026
;* Target: AVR128DB48
;* Number of words: 11
;* Number of cycles: Varies
;* Low registers modified: None
;* High registers modified: r16, r17, r18
;*
;* Parameters: None
;*
;* Returns: None
;*
;* Notes: STATUS register bit 7 is RXCIF, RXDATAH contrains error flag, bit
;* 2 is FERR, RXDATAL is for data to be recieved
;*
;***************************************************************************
serial_receive_hdwe:
    lds r16, USART1_STATUS
    sbrs r16, 7                    ; waits for RXCIF
    rjmp serial_receive_hdwe
    
    lds r17, USART1_RXDATAH        ; read H first (error flags)
    lds r18, USART1_RXDATAL        ; then the data
    sbrs r17, 2                    ; FERR set? skips sending bad char
	rcall serial_send
    ret


;***************************************************************************
;* 
;* "serial_send" - read_display_HT
;*
;* Description:
;* Reads status registers and verifies that it is ready to accept a new byte
;* and then sends by writing it to the transmit buffer register.
;*
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0
;* Last updated: 11/4/2026
;* Target: AVR128DB48
;* Number of words: 7
;* Number of cycles: Varies
;* Low registers modified: None
;* High registers modified: r16, r18
;*
;* Parameters: None
;*
;* Returns: None
;*
;* Notes: STATUS registers bit 5 is DRIEF and TXDATAL is for data to transmit
;*
;***************************************************************************
serial_send:
    lds r16, USART3_STATUS         
    sbrs r16, 5                    ; DREIF set? skip looping to check status register
    rjmp serial_send
    sts USART3_TXDATAL, r18        ; write char to LCD
    ret
