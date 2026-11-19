;
; target_state.asm
;***************************************************************************
;*
;* Title: Lab 10 HLK-LD2410C Human Presence, Design Task 4
;* Author: Sophia Rahman, Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;*
;* DESCRIPTION
;* In this program, USART0 reads the Human Presence sensor module, and it 
;* gets written into the memory buffer of the SRAM and then it checks
;* the data for human presence detection and when it is found, the program
;* turns on the yellow LED.
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************


.nolist
.include "avr128db48def.inc"
.list

.dseg                          ;Establishes a data segment for memory variable
mem_buffer: .byte 23           ;The module outputs 23 bytes of data in frame
buff_flag: .byte 1             ;Memory flag, 1 = frame ready

.cseg                          ;Switches back to Flash
.org 0x0000                    ;Places it back to the start of the Flash
rjmp start                     ;Jumps over reset so the CPU can actually begin


;***************************************************************************
;* 
;* "reset" - target_state
;*
;* Description:
;* Initializes the Y pointer to the start of the memory buffer, resets it
;* to the beginning of the SRAM buffer
;*
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;* Number of words: 3
;* Number of cycles: 6
;* Low registers modified: None
;* High registers modified: YL (r28), YH (r29)
;*
;* Parameters: None
;*
;* Returns: Y pointers
;*
;* Notes: None
;*
;***************************************************************************
reset:
    ldi YL, LOW(mem_buffer)        ;Initialize the pointer to the buffer
    ldi YH, HIGH(mem_buffer)
    ret

start:
	ldi r16, 0x01                  ;USART0 ALT1 value is 0x01
	sts PORTMUX_USARTROUTEA, r16   ;Changes USART0 pins

	ldi r16, 0xC2				   ;Enables Rx and Tx pin in double-speed mode
	sts USART0_CTRLB, r16

	ldi r16, LOW(125)              ;64*4MHz / 8*256000 = 125, S = 8 (Double-speed mode)
	sts USART0_BAUDL, r16
	ldi r16, HIGH(125)               
	sts USART0_BAUDH, r16

	ldi r16, 0x03                  ;Frame format 8N1
	sts USART0_CTRLC, r16

	cbi VPORTA_DIR, 5              ;PA5 input, Rx pin for USART0
	sbi VPORTA_DIR, 4              ;PA4 output, Tx pin
	sbi VPORTA_DIR, 3              ;PA3 is set as output for the LED

	;LCD initialization (USART3)
	ldi  r16, 0x40                 ;Enable Tx pin
    sts  USART3_CTRLB, r16

	ldi  r16, LOW(1667)            ;9600 baud @ 4MHz (Normal mode)
    sts  USART3_BAUDL, r16
    ldi  r16, HIGH(1667)
    sts  USART3_BAUDH, r16

	ldi r16, 0x03                  ;Frame format 8N1
	sts USART3_CTRLC, r16

	sbi  VPORTB_DIR, 0             ;PB0 output, for Tx pin
    sbi  VPORTB_OUT, 0             ;Idle HIGH

	rcall delay_500ms               ;LCD setup time
    ldi  r18, '|'                   ;Clear LCD screen
    rcall serial_send
    ldi  r18, '-'
    rcall serial_send

	clr r16
	sts buff_flag, r16             ;Clear the memory flag at startup
	rcall reset

main_loop:
	rcall serial_receive
	rcall check_for_human
	rcall display_target_state
	rcall delay_500ms
	rjmp main_loop


;***************************************************************************
;* 
;* "read_USART0" - target_state
;*
;* Description:
;* This subroutine checks the status register and then reads the incoming
;* byte and stores it into r18, it also checks if there is any framing
;* errors and notifies that with the Carry flag and then reads the byte into
;* r16. 
;* Author: Sophia Rahman, Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;* Number of words: 14
;* Number of cycles: Varies
;* Low registers modified: None
;* High registers modified: r16, r18
;*
;* Parameters: None
;*
;* Returns: Byte in r16, Carry flag
;*
;* Notes: polls RXCIF and checks FERR
;*
;***************************************************************************
read_USART0:
	lds r16, USART0_STATUS          ;Reads the status register of USART0
	sbrs r16, 7                     ;Skip next line if RXCIF (bit 7) is 1
	rjmp read_USART0                ;Waits for a byte

	lds r18, USART0_RXDATAH 		;Store the receiver data into r18 (FERR is bit 2 of RXDATAH)
	sbrs r18, 2                     ;FERR
	rjmp frame_good

	sec
    rjmp read_data

frame_good:
    clc

read_data:
	lds r16, USART0_RXDATAL         ;Reads byte into r16
	ret

;***************************************************************************
;* 
;* "serial_receive" - target_state
;*
;* Description:
;* This subroutine puts all 23 bytes into the memory buffer in the SRAM. It
;* verifies that the header of the frame is correct  (0xF4, 0xF3, 0xF2, 0xF1) 
;* and then it saves the the frame header in the mem_buffer and then it loops
;* until the rest of the bytes are in the mem_buffer. 
;*
;* Author: Sophia Rahman, Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;* Number of words: 39
;* Number of cycles: Varies
;* Low registers modified: None
;* High registers modified: r16, r17, r19, YL (r28), YH (r29)
;*
;* Parameters: None
;*
;* Returns: 23 byte data in SRAM and buff_flag
;*
;* Notes: calls reset sub and read_USART0 sub
;*
;***************************************************************************
serial_receive:
	rcall reset                     ;Makes sure Y points to mem_buffer[0]

wait_f4:
	rcall read_USART0
	cpi r16, 0xF4                   ;First header byte is F4
	brne wait_f4

wait_f3:
	rcall read_USART0
	cpi r16, 0xF3                   ;Second header byte is F3
	breq wait_f2                    ;Moves on to the next header if F3
	cpi r16, 0xF4                   ;Another F4 instead?
	breq wait_f3                    ;Stay and wait for F3
	rjmp wait_f4                    ;Starts over if not F4 or F3

wait_f2:
	rcall read_USART0
	cpi r16, 0xF2                   ;Third header byte is F2
	breq wait_f1                    ;Moves on to the next header if F2
	cpi r16, 0xF4                   ;Another F4 instead?
	breq wait_f3                  
	rjmp wait_f4                    ;Starts over if not F4 or F2

wait_f1:
	rcall read_USART0
	cpi r16, 0xF1                   ;Last header byte is F1
	breq save_frame                 ;Moves on to put the header in the memory buffer
	cpi r16, 0xF4                   ;Another F4 instead?
	breq wait_f3                    
	rjmp wait_f4                    ;Starts over if not F4 or F1

save_frame:
	ldi r16, 0xF4                   ;Saves the 4 header bytes into mem_buffer[0 to 3]
	st Y+, r16                      ;Moves pointer 1
	ldi r16, 0xF3
	st Y+, r16
	ldi r16, 0xF2
	st Y+, r16
	ldi r16, 0xF1
	st Y+, r16

	ldi r17, 19                     ;lcv for the rest of the 19 bytes

save_loop:
	rcall read_USART0
	st Y+, r16                      ;Stores the byte and points to the next slot
	dec r17                         ;decrements counters
	brne save_loop                  ;Repeats until all 19 bytes received

	ldi r16, 1
	sts buff_flag, r16              ;Set buff_flag (all 23 bytes ready)
	ret


;***************************************************************************
;* 
;* "check_for_human" - target_state
;*
;* Description:
;* This subroutine checks that the buff_flag is set and then reads the target
;* state to check if there was a target or not and then if there is a target
;* it turns the LED on.
;*
;* Author: Sophia Rahman, Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;* Number of words: 12
;* Number of cycles: 10 (buff_flag not set), 16 (Led off), 17 (Led on)
;* Low registers modified: None
;* High registers modified: r16
;*
;* Parameters: None
;*
;* Returns: None
;*
;* Notes: None
;*
;***************************************************************************
check_for_human:
	lds r16, buff_flag              ;Loads the buff_flag into r16
	cpi r16, 0                      ;Checks if it's 0
	breq check_done                 ;Returns

	lds r16, mem_buffer + 8         ;Target State Byte at index 8
	cpi r16, 0x00                   ;Checks if there was no target
	breq led_off                    ;Turns off the LED

	sbi VPORTA_OUT, 3               ;Turns LED on
	rjmp check_done

led_off:
	cbi VPORTA_OUT, 3               ;Turns LED off

check_done:
	ret


;***************************************************************************
;* 
;* "display_target_state" - target_state
;*
;* Description:
;* This subroutine checks that the buff_flag is set, then sets up the LCD
;* to write the target state, and then finds the target state, and uses
;* serial_send to display it on the LCD, and then it clears the buff_flag.
;*
;* Author: Sophia Rahman, Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;* Number of words: 23
;* Number of cycles: Varies
;* Low registers modified: None
;* High registers modified: r16, r18
;*
;* Parameters: None
;*
;* Returns: None
;*
;* Notes: None
;*
;***************************************************************************
display_target_state:
	lds r16, buff_flag              ;Loads the buff_flag into r16
	cpi r16, 0                      ;Checks if it's 0
	breq display_done               ;Returns

	ldi  r18, '|'                   ;Clear LCD screen
    rcall serial_send
    ldi  r18, '-'
    rcall serial_send

	ldi  r18, '0'                   ;Sends "0x0" before target_state
    rcall serial_send
    ldi  r18, 'x'
    rcall serial_send
	ldi  r18, '0'                   
    rcall serial_send

	lds r16, mem_buffer + 8         ;Target State Byte at index 8
	ldi r18, '0'                    ;'0' ASCII is 0x30
	add r18, r16                    ;Adding '0' will return the ASCII num (0, 1, 2, 3)
	rcall serial_send               ;0x00, 0x01, 0x02, 0x03

	clr r16
	sts buff_flag, r16              ;Resets buff flag

display_done:
	ret

;*****************************************************************************
;* 
;* "serial_send" - target_state
;*
;* Description:
;* Reads the status register and checks that it's ready to accept a new byte to 
;* send and then writes into the transmit buffer register.
;*
;* Author: Daniel Zhou and Sophia Rahman
;* Version: 1.0 Original Version
;* Last updated: 11/17/2026
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
;* "delay_500ms" - target_state
;*
;* Description:
;* Delays 500ms using nested loop counters.
;*
;* Author: Daniel Zhou and Sophia Rahman
;* Version: 1.0 Original Version
;* Last updated: 11/17/2026
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
