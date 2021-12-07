;
; RecibirDatos.asm
;
; Created: 6/12/2021 22:26:32
; Author : nmais
;


	
.DSEG
almacenamiento: .byte 5
conParidad:	.byte 10

.CSEG
.ORG 0x0000
	jmp		start		;dirección de comienzo (vector de reset)  
.ORG 0x0008
	jmp Boton_

start:
;Configuro botones
	ldi r16, 2
	sts PCICR,r16
	ldi r16, 0b00001110
	sts PCMSK1, r16
;---------------------------------------------------------------------------------------------------

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
;Configuro USART
	.equ	baud	= 9600			; baudrate
				  ;(F_CPU/16/baud) - 1
	.equ	bps	= (16000000/16/baud) - 1	; baud prescale	
	ldi	r16,LOW(bps)			; load baud prescale
	ldi	r17,HIGH(bps)			; into r17:r16

	sts	UBRR0L,r16			; load baud prescale
	sts	UBRR0H,r17			; to UBRR0
	ldi	r16,0b00010000 ;(1<<RXEN0)	; enable reciver
	sts	UCSR0B,r16			; and receiver

	ldi r16,0b00000110 ;(1<<USBS0)|(3<<UCSZ00)
	sts UCSR0C,r16


sei
comenzar:
		nop
	rjmp comenzar
	

Boton_:
	in r24, SREG
	in r25, PINC
	ldi r21,10	;La cantidad de datos que quiero recibir
	ldi r28, low(conParidad)
	ldi r29, high(conParidad)
	call EmpiezoARecibir
	reti

EmpiezoARecibir:
	call RecibirDato ;En el registro r14
	call AlmacenoConParidad
	dec r21
	brne EmpiezoARecibir
	//ldi r30, 1
ret

RecibirDato:
	lds	r17,UCSR0A				; load UCSR0A into r17
	sbrs r17,RXC0				; wait for empty transmit buffer
	rjmp RecibirDato			; repeat loop

	lds r16,UDR0			; transmited character
	ret							;devuelvo r14 con el dato listo para guardar

AlmacenoConParidad:
	st Y+, r16
	ret