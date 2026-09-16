start:
	sbi VPORTB_DIR, 3
	sbi VPORTB_OUT, 3
	cbi VPORTB_DIR, 2
	ldi r16, 0x08
	sts PORTB_PIN2CTRL, r16


loop:
	sbsic VPORTB_IN, 2
	sbi VPORTB_OUT, 3
	sbis VPORTB_IN, 2
	cbi VPORTB_OUT, 3
	rjmp loop
