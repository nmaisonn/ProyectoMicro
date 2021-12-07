.ORG 0x0000
	jmp		start		;dirección de comienzo (vector de reset)  
.ORG 0x0008
	jmp _Boton		;Salto atencion a rutina del boton (Pag 74)  

.DSEG
almacenamiento: .byte 5
conParidad: .byte 10

.CSEG
	

start:

;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
	ldi		r16,	0b00111101	
	out		DDRB,	r16			;4 LEDs del shield son salidas (Configuracion leds)
	out		PORTB,	r16			;apago los LEDs	(Apago las led's)
	ldi		r16,	0b00000000	
	out		DDRC,	r16			;3 botones del shield son entradas (Pongo como entrada los 3 botones)
	ldi		r16,	0b10010000
	out		DDRD,	r16			;configuro PD.4 y PD.7 como salidas
	cbi		PORTD,	7			;PD.7 a 0, es el reloj serial, inicializo a 0
	cbi		PORTD,	4			;PD.4 a 0, es el reloj del latch, inicializo a 0
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
	ldi	r16,(1<<TXEN0)|(1<<RXEN0)	; enable transmitter
	ldi r16, (1<<USBS0)|(3<<UCSZ00)
	sts UCSR0C,r16
	sts	UCSR0B,r16			; and receiver

; Replace with your application code
comienzo:
	sei
	nop 
	rjmp comienzo


_Boton:
	in r24, SREG
	in r25,PINC
	ldi r19,1
	ldi r23,10
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
				