; CONFIG1
; __config 0xF8F1
 __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
    
    
    LIST p=16F887
    INCLUDE <P16F887.INC>

Boton_asc	EQU     0       ; Definimos Led como RB0
Boton_dsc	EQU     1       ; Definimos Led como RB1
Switch_activar	EQU     2       ; Definimos Led como RB2
Boton_sub	EQU     3       ; Definimos Led como RB3
Boton_baj	EQU     4       ; Definimos Led como RB4    
flag_counter    EQU     0
flag_counter_inc    EQU     1    
Contador1	EQU 0x20
Contador2	EQU 0x21
DISP_COUNTER	EQU 0x22
DISP_DEFAULT	EQU 0x23
DISP_FREQ	EQU 0x24
STD_COUNTER     EQU 0x2B
NUMERO_PASAJEROS EQU 0x2C
UMBRAL_BAJO     EQU 0x2D
UMBRAL_MEDIO    EQU 0x2E
UMBRAL_ALTO     EQU 0x2F
LIMITE_BAJO     EQU 0X30     
Hundred	EQU 0x25
Tens	EQU 0x26
Units	EQU 0x27	
bin	EQU 0x28
count8	EQU 0x29
temp	EQU 0x2A
 
    ORG 0x00 ; Inicio de programa
    goto INIT
 ;** Configurar el puerto**
INIT
	bsf STATUS,RP0 ; Cambia al Banco 1
	movlw 00h ; Configura los pines del puerto D ...
	movwf TRISD ; ...como salidas.
	movwf TRISA ; ...como salidas.
	movlw	b'00011111'        ; Cargamos b'00000111' en W
	movwf	TRISB           ; Cargamos W en TRISA, RA0 como entrada
	movlw   b'10111000'    ; RC7/RX entrada,
        movwf   TRISC          ; RC6/TX salida
	
	BSF STATUS,RP1 ; Accede a banco 3
	CLRF ANSEL  ; 
	CLRF ANSELH ;
	BCF STATUS,RP0 ; Regresa a banco 0 RP0 = 0
	BCF STATUS,RP1 ; Regresa a banco 0 RP1 = 0
	
	movlw 00h ; Configura nuestro registro w con 00h
	movwf PORTD ; ...como salidas.
	movwf PORTA ; ...como salidas.
	movwf PORTC ; ...como salidas.
	call  inicio_uart 
	movlw 04h
	movwf LIMITE_BAJO
	movlw 20h ; Configura nuestro registro w con 02h
	movwf DISP_FREQ
	movlw 0Ch ; Configura nuestro registro w con 02h
	movwf DISP_DEFAULT
        movlw 00h 
	movwf DISP_COUNTER
	movwf NUMERO_PASAJEROS
	MOVWF bin ; 0x20
	CALL Binary2BCD ; tens = 3 unit = 2 
	CLRF STD_COUNTER
	bsf     STD_COUNTER,flag_counter 
MAIN
	btfss PORTB,Switch_activar	    ; Esta pulsado el Boton (RA0=1??)
	GOTO RUN
	GOTO SETTING
RUN
	CALL DISP_UPDATE_UNIT ; 2
	CALL DELAY_20MS
	CALL DISP_UPDATE_TENS; 3
	CALL DELAY_20MS
	DECFSZ DISP_FREQ
	GOTO MAIN
	CALL UPDATE_BTN_ENTRAR
	CALL UPDATE_BTN_SALIR
	CALL CAPACIDAD_0_25
	CALL CAPACIDAD_25_75
	CALL CAPACIDAD_75_100
	GOTO INIT_FREQ

INIT_FREQ
	MOVF NUMERO_PASAJEROS,0
	MOVWF bin ; 0x20
	CALL Binary2BCD ; tens = 3 unit = 2 
	movlw 20h ; Configura nuestro registro w con 02h
	movwf DISP_FREQ
	call  SEND_DATA
	GOTO MAIN
	
	
SEND_DATA movf Tens,0
	  addlw 0x30
	  CALL TX_DATO1
	  movf Units,0
	  addlw 0x30
	  CALL TX_DATO1
	  movlw 0x0A;numero \r
	  CALL TX_DATO1
	  movlw 0x0d;numero \n
	  CALL TX_DATO1
	  return  

;--------------------------------------------------------------------------
; INITIALIZE COUNTER
;--------------------------------------------------------------------------	

INIT_COUNTER
	movf DISP_DEFAULT,0 ; Muevo el valor por defecto al registro W
	movwf DISP_COUNTER  ; cargo el valor del registro W al Contador
	RETURN

;**** R U T I N A * T E S T E O **************
SETTING
	movf   NUMERO_PASAJEROS,0
	subwf   DISP_DEFAULT,0
	btfss   STATUS,2
	goto    CONTINUAR
	goto    FLAG_COUNTER_INC_SET
	
FLAG_COUNTER_INC_SET
	bcf     STD_COUNTER,flag_counter_inc
	goto    CONTINUAR

CONTINUAR	
	CALL UPDATE_BTN_ASC
	CALL UPDATE_BTN_DSC
	CALL VERIFICAR_LIMITES
	CALL INIT_COUNTER
	MOVF DISP_COUNTER,0
	MOVWF bin ; 0x20
	CALL Binary2BCD ; tens = 3 unit = 2
	CALL DISP_UPDATE_UNIT ; 2
	CALL DELAY_20MS
	CALL DISP_UPDATE_TENS; 3
	CALL DELAY_20MS
	;CLRF STD_COUNTER
	CALL SETTING_UMBRAL
	GOTO INIT_FREQ
	
SETTING_UMBRAL
	MOVF DISP_DEFAULT,0
	MOVWF UMBRAL_BAJO
	RRF UMBRAL_BAJO,1
	RRF UMBRAL_BAJO,1
	MOVWF UMBRAL_MEDIO
	RRF   UMBRAL_MEDIO,1
	MOVF  UMBRAL_BAJO,0
	SUBWF DISP_DEFAULT,0
	MOVWF UMBRAL_ALTO
	RETURN

VERIFICAR_LIMITES
	  MOVF DISP_DEFAULT,0
	  SUBWF LIMITE_BAJO,0
	  BTFSC STATUS,2
	  GOTO SALIR4
	  CALL FIJAR_LIMITE
	  
FIJAR_LIMITE
	  BTFSS STATUS,0
	  GOTO SALIR4
	  MOVF LIMITE_BAJO,0
	  MOVWF DISP_DEFAULT
	  GOTO SALIR4	  
SALIR4
	  RETURN	
CAPACIDAD_0_25
	
	  MOVF NUMERO_PASAJEROS,0
	  SUBWF UMBRAL_BAJO,0
	  BTFSC STATUS,2
	  GOTO SALIR
	  CALL ENCENDER_LED_VERDE
	  
ENCENDER_LED_VERDE
	  BTFSS STATUS,0
	  GOTO SALIR
	  BCF PORTC,0
	  BCF PORTC,1
	  BSF PORTC,2
	  GOTO SALIR	  
SALIR
	  RETURN
	  
CAPACIDAD_25_75
	  MOVF NUMERO_PASAJEROS,0
	  SUBWF UMBRAL_BAJO,0
	  BTFSC STATUS,0
	  GOTO SALIR2
	  CALL ENCENDER_LED_AMARILLO
	  
ENCENDER_LED_AMARILLO
	  BTFSC STATUS,2
	  GOTO SALIR2
	  BCF PORTC,0
	  BSF PORTC,1
	  BCF PORTC,2
	  GOTO SALIR2	  
SALIR2
	  RETURN
	  
CAPACIDAD_75_100
	  MOVF NUMERO_PASAJEROS,0
	  SUBWF UMBRAL_ALTO,0
	  BTFSC STATUS,0
	  GOTO SALIR3
	  CALL ENCENDER_LED_ROJO
	  
ENCENDER_LED_ROJO
	  BTFSC STATUS,2
	  GOTO SALIR3
	  BSF PORTC,0
	  BCF PORTC,1
	  BCF PORTC,2
	  GOTO SALIR3	  
SALIR3
	  RETURN

	  
UPDATE_BTN_ASC
	btfss	PORTB,Boton_asc	    ; Esta pulsado el Boton (RA0=1??)
	goto	END_BTN_ASC	    ; No??, seguimos testeando
	call	DELAY_20MS        ; Si??, Eliminamos efecto rebote
	btfss	PORTB,Boton_asc	    ; Testeamos nuevamente
	goto	END_BTN_ASC	    ; Falsa Alarma, seguimos testeando
	incf	DISP_DEFAULT,1   ; Se ha pulsado, incrementamos Valor Default
RELEASE_BTN_ASC
	btfsc	PORTB,Boton_asc         ; Boton se dejo de pulsar??
	goto	RELEASE_BTN_ASC	    ; No??, PCL - 1, --> btfsc PORTA,Boton
	call    DELAY_20MS		; Si??, Eliminamos efecto rebote
	btfsc	PORTB,Boton_asc         ; Testeamos nuevamente si se dejo de pulsar
	goto	RELEASE_BTN_ASC                ; No??, Falsa alarma, volvemos a checar
	goto	END_BTN_ASC	    ; Falsa Alarma, seguimos testeando
	
END_BTN_ASC
	RETURN

UPDATE_BTN_DSC
	btfss	PORTB,Boton_dsc	    ; Esta pulsado el Boton (RA0=1??)
	goto	END_BTN_DSC	    ; No??, seguimos testeando
	call	DELAY_20MS        ; Si??, Eliminamos efecto rebote
	btfss	PORTB,Boton_dsc	    ; Testeamos nuevamente
	goto	END_BTN_DSC	    ; Falsa Alarma, seguimos testeando
	decf	DISP_DEFAULT,1   ; Se ha pulsado, incrementamos Valor Default
RELEASE_BTN_DSC
	btfsc	PORTB,Boton_dsc         ; Boton se dejo de pulsar??
	goto	RELEASE_BTN_DSC	    ; No??, PCL - 1, --> btfsc PORTA,Boton
	call    DELAY_20MS		; Si??, Eliminamos efecto rebote
	btfsc	PORTB,Boton_dsc         ; Testeamos nuevamente si se dejo de pulsar
	goto	RELEASE_BTN_DSC                ; No??, Falsa alarma, volvemos a checar
	goto	END_BTN_DSC	    ; Falsa Alarma, seguimos testeando

END_BTN_DSC
	RETURN

UPDATE_BTN_SALIR
	btfss	PORTB,Boton_baj	    ; Esta pulsado el Boton (RA0=1??)
	goto	END_BTN_SALIR	    ; No??, seguimos testeando
	call	DELAY_20MS        ; Si??, Eliminamos efecto rebote
	btfss	PORTB,Boton_baj	    ; Testeamos nuevamente
	goto	END_BTN_SALIR	    ; Falsa Alarma, seguimos testeando
	btfss   STD_COUNTER,flag_counter
	goto    DEC_COUNTER
	goto    RELEASE_BTN_SALIR
DEC_COUNTER	
	decf	NUMERO_PASAJEROS,1  ; Se ha pulsado, incrementamos Valor Default
	bcf     STD_COUNTER,flag_counter_inc
	btfss   STATUS, 2
	goto    RELEASE_BTN_SALIR
	goto    FLAG_COUNTER
	
RELEASE_BTN_SALIR
	btfsc	PORTB,Boton_baj         ; Boton se dejo de pulsar??
	goto	RELEASE_BTN_SALIR	    ; No??, PCL - 1, --> btfsc PORTA,Boton
	call    DELAY_20MS		; Si??, Eliminamos efecto rebote
	btfsc	PORTB,Boton_baj         ; Testeamos nuevamente si se dejo de pulsar
	goto	RELEASE_BTN_SALIR                ; No??, Falsa alarma, volvemos a checar
	goto	END_BTN_SALIR	    ; Falsa Alarma, seguimos testeando

FLAG_COUNTER
	bsf     STD_COUNTER,flag_counter
	goto    RELEASE_BTN_SALIR
END_BTN_SALIR
	RETURN
	
UPDATE_BTN_ENTRAR
	btfss	PORTB,Boton_sub	    ; Esta pulsado el Boton (RA0=1??)
	goto	END_BTN_ENTRAR	    ; No??, seguimos testeando
	call	DELAY_20MS        ; Si??, Eliminamos efecto rebote
	btfss	PORTB,Boton_sub	    ; Testeamos nuevamente
	goto	END_BTN_ENTRAR	    ; Falsa Alarma, seguimos testeando
	btfss   STD_COUNTER,flag_counter_inc
	goto    INC_COUNTER
	goto    RELEASE_BTN_ENTRAR
	
INC_COUNTER	
	incf	NUMERO_PASAJEROS,1   ; Se ha pulsado, incrementamos Valor Default
	bcf     STD_COUNTER,flag_counter
	movf   NUMERO_PASAJEROS,0
	subwf   DISP_DEFAULT,0
	btfss   STATUS,2
	goto    RELEASE_BTN_ENTRAR
	goto    FLAG_COUNTER_INC
	
FLAG_COUNTER_INC
	bsf     STD_COUNTER,flag_counter_inc
	goto    RELEASE_BTN_ENTRAR
RELEASE_BTN_ENTRAR
	btfsc	PORTB,Boton_sub         ; Boton se dejo de pulsar??
	goto	RELEASE_BTN_ENTRAR	    ; No??, PCL - 1, --> btfsc PORTA,Boton
	call    DELAY_20MS		; Si??, Eliminamos efecto rebote
	btfsc	PORTB,Boton_sub         ; Testeamos nuevamente si se dejo de pulsar
	goto	RELEASE_BTN_ENTRAR                ; No??, Falsa alarma, volvemos a checar
	goto	END_BTN_ENTRAR	    ; Falsa Alarma, seguimos testeando
	
END_BTN_ENTRAR
	RETURN	

;--------------------------------------------------------------------------
; DISPLAY 7 SEGMENTS
;--------------------------------------------------------------------------	
DISP_UPDATE_UNIT
	BCF PORTA,0 ;TURN OFF DIGIT 2.
	MOVF Units,0
	CALL SEVENSEG_LOOKUP
	; para anodo comun complemento (1 -> 0, 0 -> 1)
	MOVWF PORTD ;PUT DATA ON PORTB.
	BSF PORTA,1 ;TURN ON DIGIT 1.
	RETURN
	
DISP_UPDATE_TENS
	BCF PORTA,1 ;TURN OFF DIGIT 1.
	MOVF Tens,0
	CALL SEVENSEG_LOOKUP
	;para anodo comun complemento (1 -> 0, 0 -> 1)
	MOVWF PORTD ;PUT DATA ON PORTB.
	BSF PORTA,0 ;TURN ON DIGIT 2.
	RETURN
;--------------------------------------------------------------------------
; NUMBERIC LOOKUP TABLE FOR 7 SEG
;--------------------------------------------------------------------------
SEVENSEG_LOOKUP 
	ADDWF PCL,f
	RETLW 3Fh ; //Hex value to display the number 0. 0x40
	RETLW 06h ; //Hex value to display the number 1. 0x79
	RETLW 5Bh ; //Hex value to display the number 2.
	RETLW 4Fh ; //Hex value to display the number 3.
	RETLW 66h ; //Hex value to display the number 4.
	RETLW 6Dh ; //Hex value to display the number 5.
	RETLW 7Dh ; //Hex value to display the number 6.
	RETLW 07h ; //Hex value to display the number 7.
	RETLW 7Fh ; //Hex value to display the number 8.
	RETLW 6Fh ; //Hex value to display the number 9.
	RETURN
;--------------------------------------------------------------------------
; DELAY 20 MILLISECONDS
;--------------------------------------------------------------------------
DELAY_20MS
	movlw	0xFF			;
	movwf	Contador1		; Iniciamos contador1.-
Repeticion1
	movlw	0x19			;
	movwf	Contador2		; Iniciamos contador2
Repeticion2
	decfsz	Contador2,1		; Decrementa Contador2 y si es 0 sale.-
	goto	Repeticion2		; Si no es 0 repetimos ciclo.-
	decfsz	Contador1,1		; Decrementa Contador1.-
	goto	Repeticion1		; Si no es cero repetimos ciclo.-
	return				; Regresa de la subrutina.-

;--------------------------------------------------------------------------
; CONVERTER BINARY TO BCD
;--------------------------------------------------------------------------
Binary2BCD
	clrf		Hundred
	clrf		Tens
	clrf		Units
	movlw		0x08
	movwf		count8
	; check if bin is zero	
	movlw		0x00
	addwf		bin, f
	btfsc		STATUS, Z
	goto		endBinary2BCD
startconversion	
	; rotate MSB from bin into Units
	bcf		STATUS, C
	rlf		bin, f
	rlf		Units, f
	; check if a carry happened to 5th bit of Units 
	; helps to move the carry from nibble to a different byte
	btfss		Units, 0x04
	goto		RotateZeroIntoTen
	bsf		STATUS, C
	rlf		Tens, f
	goto		completeUnitCarry	
RotateZeroIntoTen
	bcf		STATUS, C
	rlf		Tens, f
completeUnitCarry	
	bcf		Units, 0x04
	; check if a carry happend to the 5th bit of Tens
	; helps to move the carry from nibble to a different byte
	btfss		Tens, 0x04
	goto		RotateZeroIntoHun
	bsf		STATUS, C
	rlf		Hundred, f
	goto		completeTenCarry	
RotateZeroIntoHun
	bcf		STATUS, C
	rlf		Hundred, f
completeTenCarry	
	bcf		Tens, 0x04
	decfsz		count8,f
	goto		continue
	goto		endBinary2BCD
continue
	; check if you need to add 3 to Units if it is greater or equal to 5
	movf		Units, w
	movwf		temp
	movlw		0x05
	subwf		temp, f
	btfss		STATUS, C
	goto		AfterAdding3
	movf		Units, w
	addlw		0x03
	movwf		Units
AfterAdding3	
	; check if you need to add 3 to Tens if it is greater or equal to 5
	movf		Tens, w
	movwf		temp
	movlw		0x05
	subwf		temp, f
	btfss		STATUS, C
	goto		AfterAdding_3
	movf		Tens, w
	addlw		0x03
	movwf		Tens
AfterAdding_3	
	goto		startconversion
endBinary2BCD	
	return
	



 ;Comienzo del programa principal
inicio_uart  
          bsf     STATUS,RP0     ; Bank01
          bcf     STATUS,RP1
          movlw   b'00100100'    ; Configuración USART
          movwf   TXSTA          ; y activación de transmisión
          movlw   .25            ; 9600 baudios
          movwf   SPBRG
          bcf     STATUS,RP0     ; Bank00
          movlw   b'10010000'    ; Configuración del USART para recepción continua
          movwf   RCSTA          ; Puesta en ON
	  return

TX_DATO1  bcf     PIR1,TXIF      ; Restaura el flag del transmisor
	  movwf   TXREG          ; Mueve el byte a transmitir al registro de transmision
          bsf     STATUS,RP0     ; Bank01
          bcf     STATUS,RP1

TX_DAT_1  btfss   TXSTA,TRMT     ; ¿Byte transmitido?
          goto    TX_DAT_1       ; No, esperar
          bcf     STATUS,RP0     ; Si, vuelta a Bank00
          return
	  
	
	end