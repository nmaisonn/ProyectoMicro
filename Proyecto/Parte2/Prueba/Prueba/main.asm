
.DSEG
//almacenamiento: .byte 5
conParidad: .byte 10

.CSEG
.ORG 0x0000
	jmp		start		;dirección de comienzo (vector de reset)  
.ORG 0x0008
	jmp _Boton		;Salto atencion a rutina del boton (Pag 74)  

start:

;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
	ldi		r16,	0b00000001	
	out		DDRB,	r16			;4 LEDs del shield son salidas (Configuracion leds)
	out		PORTB,	r16			;apago los LEDs	(Apago las led's)
	ldi		r16,	0b00000000	
	out		DDRC,	r16			;3 botones del shield son entradas (Pongo como entrada los 3 botones)
	ldi		r16,	0b10010010
	out		DDRD,	r16			;configuro PD.4 y PD.7 como salidas
	out 	PORTD,	r16	
;-------------------------------------------------------------------------------------

;Configuro botones
	ldi		r16,	0b00000010
	sts		PCICR,	r16				;Pagina 82
	ldi		r16,	0b00001110
	sts		PCMSK1,		R16			;Pagina 83

;--------------------------------------------------------------------------------------------

;Configuro USART
	.equ	baud	= 9600			; baudrate
					;(F_CPU/16/baud) - 1
	.equ	bps	= (16000000/16/baud) - 1	; baud prescale	
	ldi	r16,LOW(bps)			; load baud prescale
	ldi	r17,HIGH(bps)			; into r17:r16

	sts	UBRR0L,r16			; load baud prescale
	sts	UBRR0H,r17			; to UBRR0
	ldi	r16,0b00001000	; enable transmitter
	sts	UCSR0B,r16	

	ldi r16, 0b00000110
	sts UCSR0C,r16; and receiver

sei	;Activa las interrupciones
comienzo:
	nop 
	rjmp comienzo


_Boton:
	in r24, SREG
	in r25,PINC
	ldi r19,5	;r19 con el valor que quiero guardar en el buffer
	ldi r23,10
	;Me paro en el primer lugar del buffer
	ldi r28, low(conParidad)
	ldi r29, high(conParidad)
	while:
		st Y+, r19
		dec r23
	brne while
	call EmpiezoATransferirDatos
	reti

EmpiezoATransferirDatos:
	ldi r28, low(conParidad)
	ldi r29, high(conParidad)
	ldi r23,10
	loopa:
		ld r16, Y+
		call TransfieroDato
		dec r23
	brne loopa
		ret
		
TransfieroDato:
	lds	r17,UCSR0A			; load UCSR0A into r17
	sbrs r17,UDRE0			; wait for empty transmit buffer
	rjmp TransfieroDato		; repeat loop

	sts	UDR0,r16			;Transmito lo que hay en r16
	ret
				