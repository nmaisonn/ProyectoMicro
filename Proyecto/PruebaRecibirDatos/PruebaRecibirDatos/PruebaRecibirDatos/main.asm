;
; PruebaRecibirDatos.asm
;
; Created: 5/12/2021 20:24:20
; Author : nmais
;
	
.DSEG
almacenamiento: .byte 512
conParidad:	.byte 1024

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
;-------------------------------------------------------------------------------------
ldi r30,0
sei
ldi r31, 2
ldi r21,255
comenzar:
	nop
	cpi r30,1
	brne comenzar
	ldi r28, low(conParidad)
	ldi r29, high(conParidad)
	ldi r26, low(almacenamiento)
	ldi r27, high(almacenamiento)
	while0:
		ldi r21,255
		while1:
			call sacoConParidad	;Devuelvo el byte en r17
			call SacarDatosDelBytePasado	;Obtengo partidad y datos en registros separados
			call GenerarParidad		;Genero paridad para despues comparar con el byte pasado anteriormente
			call Comparar			;Comparo que el byte este bien pasado, en caso de no estarlo lo arreglo
			call SacarleLaParidadParaAlmacenar ;Le saco la paridad a r16 para dejarlo listo para almacenarlo
			mov r7,r17				;Tengo en r7 la primera parte del numero (LSB)
			call sacoConParidad	;Devuelvo el byte en r20
			call SacarDatosDelBytePasado	;Obtengo partidad y datos en registros separados
			call GenerarParidad		;Genero paridad para despues comparar con el byte pasado anteriormente
			call Comparar			;Comparo que el byte este bien pasado, en caso de no estarlo lo arreglo
			call SacarleLaParidadParaAlmacenar ;Le saco la paridad a r16 para dejarlo listo para almacenarlo
			mov r8,r17				;Tengo en r8 la segunda parte del numero (MSB)
			call JuntoDatoParaAlmacenar ;tengo en r24 el dato para almacenar
			call Almaceno
			dec r21
		brne while1
		dec r31
	brne while0
	ldi r31,2
	while2:
		call sacoConParidad	;Devuelvo el byte en r17
		call SacarDatosDelBytePasado	;Obtengo partidad y datos en registros separados
		call GenerarParidad		;Genero paridad para despues comparar con el byte pasado anteriormente
		call Comparar			;Comparo que el byte este bien pasado, en caso de no estarlo lo arreglo
		call SacarleLaParidadParaAlmacenar ;Le saco la paridad a r16 para dejarlo listo para almacenarlo
		mov r7,r17				;Tengo en r7 la primera parte del numero (LSB)
		call sacoConParidad	;Devuelvo el byte en r20
		call SacarDatosDelBytePasado	;Obtengo partidad y datos en registros separados
		call GenerarParidad		;Genero paridad para despues comparar con el byte pasado anteriormente
		call Comparar			;Comparo que el byte este bien pasado, en caso de no estarlo lo arreglo
		call SacarleLaParidadParaAlmacenar ;Le saco la paridad a r16 para dejarlo listo para almacenarlo
		mov r8,r17				;Tengo en r8 la segunda parte del numero (MSB)
		call JuntoDatoParaAlmacenar ;tengo en r24 el dato para almacenar
		call Almaceno
		dec r31
	brne while2
	ldi r26, low(almacenamiento)
	ldi r27, high(almacenamiento)
	call sumarNumeros	;Numeros sumados y separados en 4 registros de 4 bits
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

sacoConParidad:
	ld r17, Y+
	ret

SacarDatosDelBytePasado:
	ldi r21,0	;D1
	ldi r22,0	;D2
	ldi r23,0	;D3
	ldi r24,0	;D4
	ldi r25,0	;p3
	ldi r20,0	;p2
	ldi r19,0	;p1
	clc 
	//p1p2d1p3d2d3d40
	ror r17	;saco 0
	ror r17	;saco d4
	rol r24	;meto d4
	ror r17	;saco d3
	rol r23	;meto d3
	ror r17	;saco d2
	rol r22	;meto d2
	ror r17 ;saco p3
	rol r19 ;meto p3 
	ror r17	;saco d1
	rol r21 ;meto d1
	ror r17 ;saco p2
	rol r20	;meto p2
	ror r17	;saco p1
	rol r25	;meto p1
	ret	;devuelvo r25=p1,26=p2,27=p3

;Guarda en los registros r5,r6,r7 la paridad 1,2 y 3
GenerarParidad:
	mov r5,r21
	eor r5,r22
	eor r5,r24	;Ahora en r25 tengo la paridad 1
	mov r6,r21
	eor r6,r23
	eor r6,r24	;Ahora en r26 tengo la paridad 2
	mov r7,r22
	eor r7,r23
	eor r7,r24 ;Ahora en r27 tengo la paridad 3 
	ret	;retorno r5=p1,r6=p2,r7=p3



	CambiarElBit3:
	ldi r18,0
	mov r16,r21
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	brcc Meto1
	brcs Meto0
		rol r18
		ror r16
		rol r18
		ror r16
	rjmp BitCambiado	;retorno r16 arreglado, unicamente falta sacarle la paridad

CambiarElBit5:
	ldi r18,0
	mov r16,r22
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	brcc Meto1
	brcs Meto0
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
	rjmp BitCambiado	;retorno r16 arreglado, unicamente falta sacarle la paridad

Meto0:
	clc
	ror r16
	clc
	ret

Meto1:
	sec
	ror r16
	sec
	ret

ParidadMal:
	sec
	ror r31
	ret

ParidadBien:
	inc r30
	clc 
	rol r31
	ret
;Comparo cada uno de los datos de la paridad y arreglo el dato en caso de estar mal
Comparar:
	ldi r31,0	;Bit en el que hay error (En caso de ser 0, no hay error)
	ldi r30,0	;Verifica si entro al error o no
	;Paridad 3
	cp r7,r25
	breq ParidadBien
	cpi r30,0
	breq ParidadMal
	;Paridad 2
	clr r30
	cp r6,r20
	breq ParidadBien
	cpi r30,0
	breq ParidadMal
	;Paridad 1
	clr r30
	cp r5,r19
	breq ParidadBien
	cpi r30,0
	breq ParidadMal
	
	;Ahora tengo a r31 con la pos que esta mal (unicamente cambio si el error esta en un bit de dato)
	cpi r31,3
	breq CambiarElBit3
	cpi r31,5
	breq CambiarElBit5
	cpi r31,6
	breq CambiarElBit6
	cpi r31,7
	breq CambiarElBit7
	BitCambiado:
	ret	;Retorno en r16 con paridad, falta sacarsela
	
CambiarElBit6:
	ldi r18,0
	mov r16,r23
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	brcc Meto1
	brcs Meto0
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
	rjmp BitCambiado	;retorno r16 arreglado, unicamente falta sacarle la paridad

CambiarElBit7:
	ldi r18,0
	mov r16,r24
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	ror r18
	rol r16
	brcc Meto1
	brcs Meto0
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
		rol r18
		ror r16
	rjmp BitCambiado	;retorno r16 arreglado, unicamente falta sacarle la paridad


;Le saco la paridad a r16 y lo dejo listo para almacenar
SacarleLaParidadParaAlmacenar:
	ldi r17,0
	ror r16	;saco 0
	ror r16	;saco d4
	ror r17	;meto d4
	ror r16	;saco d3
	ror r17	;meto d3
	ror r16	;saco d2
	ror r17	;meto d2
	ror r16	;saco p3
	ror r16	;saco d1
	ror r17 ;meto d1
	clc
	;me muevo 4 lugares para dejar 0000d1d2d3d4
	ror r17
	ror r17
	ror r17
	ror r17
	ret

JuntoDatoParaAlmacenar:
	ldi r16,0
	;Pongo los MSB
	ror r8
	rol r16
	ror r8
	rol r16
	ror r8
	rol r16
	ror r8
	rol r16
	;Pongo los LSB
	ror r7
	rol r16
	ror r7
	rol r16
	ror r7
	rol r16
	ror r7
	rol r16
	ret ;devuelvo r16 listo para almacenar
	
Almaceno:
	st X+, r16
	ret


sumarNumeros:
	ldi r24, 2
	loop0:
		ldi r25, 255
		loop1:
			ld r16, X+
			ldi r17, 0
			add  r30, r16
			adc	 r31, r17
			dec r25
			brne loop1
			dec r24
			brne loop0
			//Los 2 ultimos
			ld r16, X+
			ldi r17, 0
			add  r30, r16
			adc	 r31, r17
			ld r16, X+
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
