;
; ProyectoFinalTransmitirDatos.asm
;
; Created: 6/12/2021 18:48:21
; Author : nmais
;

.DSEG
almacenamiento: .byte 512


.CSEG
.ORG 0x0000
	jmp		start		;dirección de comienzo (vector de reset)  

start:
;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
	ldi		r16,	0b00111101	
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
;---------------------------------------------------------------------------------------

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

;--------------------------------------------------------------------------------------------
	ldi		r16,	80	;Guardo los primeros 8 bits del registro de 32
	ldi		r17,	108	;Guardo los segundos 8 bits del registro de 32
	ldi		r18,	5	;Guardo los	terceros 8 bits del registro de 32
	ldi		r19,	194	;Guardo los ultimos 8 bits del registro de 32
;---------------------------------------------------------------------------------------------

comienzo:
	sei
	ldi r26, low(almacenamiento)
	ldi r27, high(almacenamiento)
	call PseudoAleatorio	;Genera los 512 numeros pseudoAleatorios y los guarda en el buffer
	ldi r26, low(almacenamiento)
	ldi r27, high(almacenamiento)
	call sumarNumeros	;Numeros sumados(r30(LSB) y r31(MSB)) y separados en 4 registros de 4 bits (r30=r16(LSB)+r17(MSB) y r31=r18(LSB) + r19(MSB))
	loopnum:
		clr r21 ;Indica la posicion en el que se va a mostrar
		mov r20, r16
		call sacanum	
		inc r21
		mov r20, r17
		call sacanum
		inc r21
		mov r20, r18
		call sacanum
		inc r21
		mov r20, r19
		call sacanum
	rjmp loopnum

PseudoAleatorio:
	ldi r25, 128
	loop:
		call GenerarNumeroParaGuardar
		call LlenoBuffer
		dec r25
		brne loop
	ret

;Genera los numeros pseudoAleatorios. Los mismos los guarda en los registros r16, r17,r18,r19 de 8 bits cada uno
GenerarNumeroParaGuardar:
	mov r20, r16
	mov r21, r17
	mov r22, r18
	mov r23, r19
	ldi r24, 13
	loopA:
		rol r23
		rol r22
		rol r21
		rol r20
		dec r24
		brne loopA
		eor r16,r20
		eor	r17,r21
		eor	r18,r22
		eor r19,r23
		ldi r24, 17
	loopB:
		ror r23
		ror r22
		ror r21
		ror r20
		dec r24
		brne loopB
		eor r16,r20
		eor	r17,r21
		eor	r18,r22
		eor r19,r23
		ldi r24,5
	loopC:
		rol r23
		rol r22
		rol r21
		rol r20
		dec r24
		brne loopC
		EOR r16,r20
		EOR	r17,r21
		EOR	r18,r22
		EOR r19,r23
	ret

LlenoBuffer:
	st X+, r16
	st X+, r17
	st X+, r18
	st X+, r19
	ret

sumarNumeros:
	ldi r24, 2
	loop0:
		ldi r25, 255
		loop1:
			ld r16, Y+
			ldi r17, 0
			add  r30, r16
			adc	 r31, r17
			dec r25
			brne loop1
			dec r24
			brne loop0
			//Los 2 ultimos
			ld r16, Y+
			ldi r17, 0
			add  r30, r16
			adc	 r31, r17
			ld r16, Y+
			ldi r17, 0
			add  r30, r16
			adc	 r31, r17
			call PreparoLosNums
			ret

//r31= r19+r18. r30= r17+r16
PreparoLosNums:
	ldi r25,4
	ldi r16,0	;LSB del r30
	ldi r17,0	;MSB del r30
	ldi r18,0	;LSB del r31
	ldi r19,0	;MSB del r31
	clc
	rotarLSB:
		ror r30
		ror r16
		clc
		ror r31
		ror r18
		clc
		dec r25
		brne rotarLSB
		ldi r25,4
		rotarMSB:
			ror r30
			ror r17
			clc
			ror r31
			ror r19
			clc
			dec r25
			brne rotarMSB
			clc
			ldi r25,4
			loopListos:
				clc 
				ror r16
				clc
				ror r17
				clc
				ror r18
				clc 
				ror r19
				dec r25
				brne loopListos
			ret

sacanum: 
	call ConvertirNum

	cpi r21, 0
	breq DisplayPos0
	
	cpi r21, 1
	breq DisplayPos1

	cpi r21, 2
	breq DisplayPos2
	
	cpi r21, 3
	breq DisplayPos3
	vuelta:
		call	dato_serie		
		mov		r20, r22		;r18=r17
		call	dato_serie		
		sbi		PORTD, 4		;PD.4 a 1, es LCH el reloj del latch
		cbi		PORTD, 4		;PD.4 a 0, 
		ret

		;Voy a sacar un byte por el 7seg
		dato_serie:
			ldi		r30, 0x08 ; lo utilizo para contar 8 (8 bits)

		loop_dato1:
			cbi		PORTD, 7		;SCLK = 0 reloj en 0
			lsr		r20				;roto a la derecha r16 y el bit 0 se pone en el C
			brcs	loop_dato2		;salta si C=1
			cbi		PORTB, 0		;SD = 0 escribo un 0 
			rjmp	loop_dato3
		loop_dato2:
			sbi		PORTB, 0		;SD = 1 escribo un 1
		loop_dato3:
			sbi		PORTD, 7		;SCLK = 1 reloj en 1
			dec		r30
			brne	loop_dato1; cuando r18 llega a 0 corta y vuelve
			ret

DisplayPos0:
	ldi r22,0b00010000
	rjmp vuelta

DisplayPos1:
	ldi r22,0b00100000
	rjmp vuelta

DisplayPos2:
	ldi r22,0b01000000
	rjmp vuelta

DisplayPos3:
	ldi	r22,0b10000000
	rjmp vuelta

ConvertirNum:

	cpi r20,0b00000000
	breq CambiarA0
	
	cpi r20,0b00000001
	breq CambiarA1
	
	cpi r20,0b00000010
	breq CambiarA2
	
	cpi r20,0b00000011
	breq CambiarA3
	
	cpi r20,0b00000100
	breq CambiarA4
	
	cpi r20,0b00000101
	breq CambiarA5
	
	cpi r20,0b00000110
	breq CambiarA6
	
	cpi r20,0b00000111
	breq CambiarA7
	
	cpi r20,0b00001000
	breq CambiarA8
	
	cpi r20,0b00001001
	breq CambiarA9

	cpi r20,0b00001010
	breq CambiarAA

	cpi r20,0b00001011
	breq CambiarAB

	cpi r20,0b00001100
	breq CambiarAC

	cpi r20,0b00001101
	breq CambiarAD

	cpi r20,0b00001110
	breq CambiarAE

	cpi r20,0b00001111
	breq CambiarAF

CambiarA0:
	ldi r20,0b00000011
	ret

CambiarA1:
	ldi r20,0b10011111
	ret

CambiarA2:
	ldi r20,0b00100101
	ret

CambiarA3:
	ldi r20,0b00001101
	ret

CambiarA4:
	ldi r20,0b10011001
	ret

CambiarA5:
	ldi r20,0b01001001
	ret

CambiarA6:
	ldi r20,0b01000001
	ret

CambiarA7:
	ldi r20,0b00011111
	ret

CambiarA8:
	ldi r20,0b00000001
	ret

CambiarA9:
	ldi r20,0b00011001
	ret

CambiarAA:
	ldi r20,0b00010001
	ret

CambiarAB:
	ldi r20,0b11000001
	ret

CambiarAC:
	ldi r20,0b01100011
	ret

CambiarAD:
	ldi r20,0b10000101
	ret

CambiarAE:
	ldi r20,0b01100001
	ret

CambiarAF:
	ldi r20,0b01110001
	ret
