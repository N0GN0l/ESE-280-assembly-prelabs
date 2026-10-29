;
; half_bit_time_test.asm
;***************************************************************************
;*
;* Title: Lab 08: Software and Hardware Serial Recievers, Design Task 1
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;*
;* DESCRIPTION
;*  In this design task, we will create a subroutine that will provide a
;* delay of 52us which is half the bit time for bits trasmitted at 9600 baud. 
;* The 52us delay will be a subroutine called half_bit_time_52us and will be
;* verified in this program.
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************

.nolist
.include "m4809def.inc"
.list


start:
	nop
    rcall half_bit_time_52us	// 2 clocks
	nop
	rjmp start

;*****************************************************************************
;* 
;* "half_bit_tine_52us" - 52us Delay Subroutine
;*
;* Description:
;*	 Generates a 52us delay which is 208 clock cycles using our 4Mhz frequency
;* and it represents half a bit time for 9600 serial baud. 
;* Author: Sophia Rahman and Daniel Zhou
;* Version: 1.0 Original Version
;* Last updated: 10/29/2026
;* Target: Atmega4809
;* Number of words: 5
;* Number of cycles: 206 (208 if we include rcall)
;* Low registers modified: None
;* High registers modified: r16
;*
;* Parameters: None
;*
;* Returns: None
;*
;* Notes: Clock rate = 0.25us/cycle, 52us * 0.25us/cycle = 208 cycles
;*
;***************************************************************************** 

half_bit_time_52us:
	ldi r16, 67			    // 1 clock
bt_loop:
	dec r16					// 1 clock
	brne bt_loop			// 2/1 clocks
	nop                     // 1 padding
	ret						// 4
