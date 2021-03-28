;Archivo:	LAB06.s 
;Dispositivo:	PIC16F887
;Autor:		Brayan Castillo Alvarado
;Compilador:	pic-as (v2.30), MPLABX V5.45
;
;Programa:	Displays simultáneos con interrupciones
;Hardware:	LED en el puerto A, 7 segmentos multiplexados en puerto C y D
;		
;
;Creado: 23 marzo, 2021
;Última modificación: 28 de marzo, 2021
    

PROCESSOR 16F887
#include <xc.inc>    
; Palabra de configuración 1
    
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (RC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, RC on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; Palabra de configuración 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
rst_tmr0 macro			;Macro para el reset del timer0
    banksel PORTA		
    movlw   247		;2ms para el timer0
    movwf   TMR0
    bcf	    T0IF	;Limpiamos la bandera
endm
rst_tmr1 macro		;Macro para el reset del timer1
    banksel PORTA
    movlw   0xB8	;0.5 segundos para el timer1
    movwf   TMR1L	;Primeros 8 bits
    movlw   0x0B	
    movwf   TMR1H	;Ultimos 8 bits
    bcf	    TMR1IF	;Limpiamos la bandera
endm
rst_tmr2 macro 
    banksel TRISA
    movlw   0xF4	;PR2 en 244 0,0625
    movwf   PR2
    banksel PORTA
    clrf    TMR2	;Limpiar el timer2
    bcf	    TMR2IF	;Limpiamos la bandera
endm
    

PSECT udata_bank0
  vartmr1:	DS  1	;Variable para 1 segundo
  vartmr2:	DS  1	;Variable para 1 segundo
  varcont:	DS  1	;Variable para el contador
  varcont2:	DS  1	;Variable para el contador
  band:		DS  1	;Variable para las banderas
  display_var:	DS  5	;Variable para el display
  dece:		DS  1	;Variable para la decena
  uni:		DS  1	;Variable para unidad
  div:		DS  1	;Variable para dividir
  vard:		DS  1	;Variable para display

  
    
PSECT udata_shr  
  wtmp:	    DS	1    ;1 byte
  stmp:	    DS	1    ;1 byte
 
    
PSECT resVect, class=CODE, abs, delta=2
;-------------------Vector Reset-----------------------
ORG 00h		;Posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
PSECT resVect, class=CODE, abs, delta=2
;-------------------Vector Interrupción-----------------------    
ORG 04h		;Posicion para las interrupciones
push:
    movwf   wtmp	;Mover w a f
    swapf   STATUS, w	;Cambiar nibbles del STATUS con w
    movwf   stmp	;STATUS a stmp
    
isr:
    btfsc   T0IF	;Si esta en cero saltar la instruccion de abajo
    call    int_tmr0	;Llamar la subrutina de la interrupcion del timer0
    
    btfsc   TMR1IF	;Si esta en cero saltar la instruccion de abajo
    call    int_tmr1	;Llamar la subrutina de la interrpucion del timer1
    
    btfsc   TMR2IF	;Si esta en cero saltar la instruccion de abajo
    call    int_tmr2	;Llamar la subrutina de la interrpucion del timer2
  
    
pop:
    swapf   stmp, w	;Cambiar stmp con w
    movwf   STATUS	;Mover w a f
    swapf   wtmp, F	;Mover wtmp a w
    swapf   wtmp, w	;Mover wtmp a w
    retfie		;Salir de la interrupcion

;-------------------Subrutina de Interrupción-----------------------      
int_tmr0:
    rst_tmr0		;Resetear el timer0
    clrf    PORTD	;Limpiar el puerto D
    btfss   band, 0	;Saltar la instrucción si la bandera esta en 1
    goto    display_0	;Ir a la instrucción
    
    btfss   band, 1	;Saltar la instrucción si la bandera esta en 1
    goto    display_1	;Ir a la instrucción
    
    
display_0:
    clrf    band		;Limpiar banderas cada vez que se empieza	
    bsf	    band, 0		;Lo volvemos 1 para pasar de instrucción
    movf    display_var+0, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    bsf	    PORTD, 0		;Encendemos el bit 0 del puerto D
    
    return
   
display_1:
   
    bsf	    band, 1		;Volvemos 1 para pasar la instrucción
    movf    display_var+1, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    bsf	    PORTD, 1		;Encendemos el bit 1 del puerto D
    
    return
    
int_tmr1:
    rst_tmr1			;Reseteamos el timer1
    incf    vartmr1		;Incrementamos la variable del timer1
    movf    vartmr1, w		;Movemos la variable a w
    sublw   2			;Le restamos dos veces para poder tener 1seg
    btfss   ZERO		;Si esta en 1 saltar la instrucción de abajo
    goto    rtrn_tmr1		;Regresar
    clrf    vartmr1		;Limpiar la variable 
    movf    varcont, w		;Mover la variable del contador a w
    sublw   99			;Restarle 99 para que no pase el limite
    btfss   ZERO		;Si la resta da 0 saltar la instrucción 
    incf    varcont		;Incrementar la variable del contador
    btfsc   ZERO		;Si la resta no da 0 no realizar la instrucción
    clrf    varcont		;Limpiar la variable de contador
    
rtrn_tmr1:
    return			;Regresar
    
int_tmr2:
    rst_tmr2			;Resetear el timer2
    incf    vartmr2		;Incrementar la variable del timer2
    movf    vartmr2, w		;Mover la variable a w
    sublw   4			;Restarle 4 para hacer 250ms*4 para 1 segundo
    btfss   ZERO		;Si esta en 1 saltar la instrucción de abajo
    goto    rtrn_tmr2		;Regresar
    clrf    vartmr2		;Limpiar la variable del timer2
    btfsc   PORTA, 0		;Si el bit esta en 0 saltar la instrucción
    goto    apagar		;Ir a la instrucción de apagar
    
encender:
    bsf	    PORTA, 0		;Encender el primer bit del puerto A
    bcf	    vard, 0		;Apagar la variable para controlar el display
    goto    pop			;Regresar
apagar:
    bcf	    PORTA, 0		;Apagar el primer bit del puerto A
    bsf     vard, 0		;Encender la variable para controlar el display
    return
rtrn_tmr2:
    return			;Regresar
    
PSECT code, delta=2, abs
ORG 100h		    ; Posicion para el código
Tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0	    ;PCLATH = 01
    andlw   0x0f
    addwf   PCL		    ;PC = PCLATH + PCL + W
    retlw   00111111B	    ;0
    retlw   00000110B	    ;1
    retlw   01011011B	    ;2
    retlw   01001111B	    ;3
    retlw   01100110B	    ;4
    retlw   01101101B	    ;5
    retlw   01111101B	    ;6
    retlw   00000111B	    ;7
    retlw   01111111B	    ;8
    retlw   01101111B	    ;9
    retlw   01110111B	    ;A
    retlw   01111100B	    ;B
    retlw   00111001B	    ;C
    retlw   01011110B	    ;D
    retlw   01111001B	    ;E
    retlw   01110001B	    ;F

    
    
    
;-----------------Configuración de los Puertos----------------------------
main:
    banksel ANSEL   ;Declaramos las entradas para que sean digitales
    clrf    ANSEL     
    clrf    ANSELH
   
    banksel TRISA	
    clrf   TRISB	;Declaramos el Puerto B como bits de salida
    clrf   TRISD	;Declaramos el Puerto D como bits de salida
    clrf   TRISC	;Declaramos el puerto C como bits de salida
    clrf   TRISA	;Declaramos el puerto A como bits de salida
       
    banksel PORTB     ;Borramos cualquier dato en los puertos y las variables
    clrf    PORTA
    clrf    PORTC
    clrf    PORTD
    clrf    PORTB
  
    call conf_reloj   ;Llamamos las configuraciones
    call conf_int
    call conf_tmr0
    call conf_tmr1
    call conf_tmr2
    banksel PORTA
   
;-----------------loop principal---------------------------
loop:
    call    pp_display	    ;Llamamos a preparar display
    btfsc   vard, 0	    ;Si la variable no esta en cero limpiar el puerto
    clrf    PORTC
    movf    varcont, w	    ;Movemos el valor de la variable a w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    
    goto    loop

;-----------------sub rutinas------------------------------
pp_display:
    movf    dece, w	    ;La variable decena la movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var	    ;Lo movemos a la variable de display nibble 0
    
    movf    uni, w	    ;La variable unidad la movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+1   ;Lo movemos a la variable de display nibble 1
    
    return
    
conf_reloj:
    banksel OSCCON
    bsf	    IRCF2   ;4MHz
    bsf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS	    ;reloj interno
    
    return
    
conf_int:  
    bsf	    GIE	    ;Habilitar las interrupciones
    bsf	    TMR1IE  ;Activamos la interrupcion del timer1
    bcf	    TMR1IF  ;Limpiamos la bandera
    bsf	    TMR2IE  ;Activamos la interrupcion del timer2
    bcf	    TMR2IF  ;Limpiamos la bandera
    bsf	    T0IE    ;Actimavos la interrupcion del timer0
    bcf	    T0IF    ;Limpiamos la bandera
    
    return

conf_tmr0:
    banksel TRISA
    bcf	    T0CS
    bcf	    PSA
    bsf	    PS2		    ; configuracion del OPTION_REG
    bsf	    PS1	    
    bsf	    PS0		    ;Prescaler en 256
    rst_tmr0		    ;Llamamos el reset del timer0
    
    return

conf_tmr1:
    banksel	TRISA
    bsf		PIE1, 0	 ;Activamos la interrupción
    banksel	T1CON
    bcf		T1CON, 1 ;Utilizamos el reloj interno
    bsf		T1CON, 5 ;Prescaler en 1:8
    bsf		T1CON, 4 ;Prescaler en 1:8
    bcf		T1CON, 3 ;Oscilador apagado
    bcf		T1CON, 2 ;El timer1 va a usar el reloj interno
    bsf		T1CON, 0 ;Encender el timer1
    rst_tmr1		 ;Reseteamos el timer1
    return

conf_tmr2:
    banksel	TRISA
    bsf		PIE1, 1	 ;Activamos la interrupción
    banksel	T2CON
    
    bsf		T2CON, 3 ;Activamos el timer2
    bsf		T2CON, 4 ;Configuramos el postscaler en 1:16
    bsf		T2CON, 5
    bsf		T2CON, 6
    bsf		T2CON, 1 ;Configuramso el prescaler en 16
    bsf		T2CON, 2
    rst_tmr2		 ;Reseteamos el timer2
    return
       
div_10:
    clrf    dece    ;Limpiar la variable decenas
    movlw   10	    ;Mover la literal a w
    subwf   div, f  ;Restarle a la variable w
    btfsc   CARRY   ;Si CARRY esta en cero saltarse la instrucción de abajo
    incf    dece    ;Incrementar la variable decena
    btfsc   CARRY   ;Si CARRY esta en cero saltarse la instrucción de abajo
    goto    $-5	    ;Regresar 5 lineas
    movlw   10	    ;Mover la literal a w
    addwf   div, f  ;Sumarle a la variable w
    
    return

div_1:
    clrf    uni	    ;Limpiar la variable unidad
    movlw   1	    ;Mover la literal a w
    subwf   div, f  ;Restarle a la variable w
    btfsc   CARRY   ;Si CARRY esta en cero saltarse la instrucción de abajo
    incf    uni	    ;Incrementar la variable unidad
    btfsc   CARRY   ;Si CARRY esta en cero saltarse la instrucción de abajo
    goto    $-5	    ;Regresar 5 lineas
    movlw   1	    ;Mover la literal a w   
    addwf   div, f  ;Sumarle a la variable w
    
    return  
    
END