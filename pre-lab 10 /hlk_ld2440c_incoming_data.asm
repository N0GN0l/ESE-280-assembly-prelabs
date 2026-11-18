;
; hlk_ld2440c_incoming_data.asm
;***************************************************************************
;*
;* Title: Lab 10 HLK-LD2410C Human Presence, Design Task 3
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
;* "reset" - hlk_ld2440c_incoming_data
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

	ldi r16, 0x82 			       ;Setup USART0
    sts USART0_CTRLB, r16 	       ;Enable the reciever of USART0 in double-speed mode

	ldi r16, LOW(125)              ;64*4MHz / 8*256000 = 125, S = 8 (Double-speed mode)
	sts USART0_BAUDL, r16
	ldi r16, HIGH(125)               
	sts USART0_BAUDH, r16

	ldi r16, 0x03                  ;Frame format 8N1
	sts USART0_CTRLC, r16

	cbi VPORTA_DIR, 5              ;Make PA5 an input as it is the Rx pin for USART0

	sbi VPORTA_DIR, 3              ;PA3 is set as output for the LED

	clr r16
	sts buff_flag, r16             ;Clear the memory flag at startup
	rcall reset

main_loop:
	rcall serial_receive
	rcall check_for_human
	rjmp main_loop


;***************************************************************************
;* 
;* "read_USART0" - hlk_ld2440c_incoming_data
;*
;* Description:
;*
;* Author: Sophia Rahman, Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters:
;*
;* Returns:
;*
;* Notes: 
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
;* "serial_receive" - hlk_ld2440c_incoming_data
;*
;* Description:
;*
;* Author: Sophia Rahman, Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters:
;*
;* Returns:
;*
;* Notes: 
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
;* "check_for_human" - hlk_ld2440c_incoming_data
;*
;* Description:
;*
;* Author: Sophia Rahman, Daniel Zhou
;* Version: 1.0
;* Last updated: 11/17/2026
;* Target: AVR128DB48
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters:
;*
;* Returns:
;*
;* Notes: 
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
	rjmp clear_flag

led_off:
	cbi VPORTA_OUT, 3               ;Turns LED off

clear_flag:
	clr r16
	sts buff_flag, r16              ;Resets buff flag

check_done:
	ret
