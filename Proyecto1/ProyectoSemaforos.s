;Archivo:	ProyectoSemaforos.s
;Dispositivo:	PIC16F887
;Autor:		Brayan Castillo
;Compilador:	pic-as (v2.30), MPLABX V5.45
;
;Programa:	Displays simultáneos con interrupciones
;Hardware:	LEDs en el puerto A y B, 7 segmentos multiplexados en puerto C y D, y
;		Botones en el puerto B 
;
;Creado: 8 marzo, 2021
;Última modificación: 5 de abril, 2021
    

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
  
rst_tmr0 macro			;Macro para el reset del timer
    banksel PORTA		
    movlw   247	    	;10ms 
    movwf   TMR0
    bcf	    T0IF 
    endm
    
rst_tmr1 macro
    banksel PORTA
    movlw   0xDC	;0.5 segundos para el timer1
    movwf   TMR1L	;Primeros 8 bits
    movlw   0x0B	
    movwf   TMR1H	;Ultimos 8 bits
    bcf	    TMR1IF	;Limpiamos la bandera
    endm
    
;rst_tmr2 macro 
;    banksel TRISA
;    movlw   0xF4	;PR2 en 244 0,0625
;    movwf   PR2
;    banksel PORTA
;    clrf    TMR2	;Limpiar el timer2
;    bcf	    TMR2IF	;Limpiamos la bandera
;endm
    
MODE	EQU 4		;RB0
UP	EQU 5		;RB1
DOWN	EQU 6		;RB2


PSECT udata_bank0
  vartmr1:	DS  1	;Variable para 1 segundo
  vartmr2:	DS  1	;Variable para 1 segundo
  varcont:	DS  1	;Variable para el contador
  varcont2:	DS  1	;Variable para el contador
  band:		DS  1	;Variable para las banderas
  display_var:	DS  6	;Variable para el display
  dece:		DS  1	;Variable para la decena
  dece1:	DS  1	;Variable para la decena
  dece2:	DS  1	;Variable para la decena
  dece3:	DS  1	;Variable para la decena
  uni:		DS  1	;Variable para unidad
  uni1:		DS  1	;Variable para unidad
  uni2:		DS  1	;Variable para unidad
  uni3:		DS  1	;Variable para unidad
  div:		DS  1	;Variable para dividir
  vard:		DS  1	;Variable para display
  v1:		DS  1	;Valor inicial 1
  v2:		DS  1	;Valor inicial 2
  v3:		DS  1	;Valor inicial 3
  D1:		DS  1	;Variable display
  verdet:	DS  2	;Variable del verde tintilante
  cont_small:	DS 2; 1 byte
  cont_big:	DS 2



  sem1:		DS  1	;Variable para el nibble
  sem2:		DS  1	;Variable para el nibble
  sem3:		DS  1	;Variable para el nibble
    
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
    
    ;btfsc   TMR2IF	;Si esta en cero saltar la instruccion de abajo
    ;call    int_tmr2	;Llamar la subrutina de la interrpucion del timer2
    
    ;btfsc   RBIF	;Si esta en cero saltar la instruccion de abajo
    ;call    PB_int	;Llamar la subrutina de los interrupciones en puerto B
  
    
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
    
    btfss   band, 1
    goto    display_1
    
    btfss   band, 2
    goto    display_2
    
    btfss   band, 3
    goto    display_3
    
    btfss   band, 4
    goto    display_4
    
    btfss   band, 5
    goto    display_5
    
 ;   btfss   band, 6
;    goto    display_6
display_0:
    clrf    band		;Limpiar banderas cada vez que se empieza	
    bsf	    band, 0		;Lo volvemos 1 para pasar de instrucción
    movf    display_var+0, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    bsf	    PORTD, 0		;Encendemos el bit 1 del puerto D
    
    return
   
display_1:
   
    bsf	    band, 1		;Volvemos 1 para pasar la instrucción
    movf    display_var+1, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    bsf	    PORTD, 1		;Encendemos el bit 0 del puerto D
    
    return
    
display_2:
    
    bsf	    band, 2		;Volvemos 1 para pasar la instrucción
    movf    display_var+2, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    bsf	    PORTD, 2		;Encendemos el bit 2 del puerto D
    
    return
    
display_3:
     
    bsf	    band, 3		;Volvemos 1 para pasar la instrucción
    movf    display_var+3, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    bsf	    PORTD, 3		;Encendemos el bit 3 del puerto D
    
    return

display_4:
  
    bsf	    band, 4		;Volvemos 1 para pasar la instrucción
    movf    display_var+4, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    bsf	    PORTD, 4		;Encendemos el bit 4 del puerto D
    
    return

display_5:
  
    bsf	    band, 5		;Volvemos 1 para pasar la instrucción
    movf    display_var+5, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    bsf	    PORTD, 5		;Encendemos el bit 4 del puerto D
    
    return
 
;display_6:
  
 ;   bsf	    band, 6		;Volvemos 1 para pasar la instrucción
  ;  movf    display_var+6, w	;Movemos el nibble a w
   ; movwf   PORTC		;Encendemos w al puerto C
   ; bsf	    PORTD, 6		;Encendemos el bit 4 del puerto D
    
    
    ;return
    
int_tmr1:
    rst_tmr1			;Reseteamos el timer1
    incf    vartmr1		;Incrementamos la variable del timer1
    movf    vartmr1, w		;Movemos la variable a w
    sublw   1			;Le restamos dos veces para poder tener 1seg
    btfsc   CARRY		;Si esta en 1 saltar la instrucción de abajo
    goto    rtrn_tmr1		;Regresar
    clrf    vartmr1		;Limpiar la variable 
    movf    sem1, w
    sublw   0
    btfss   CARRY		;Si la resta da 0 saltar la instrucción 
    goto    Sem1
    goto    Sem2o3

rtrn_tmr1:
    return			;Regresar   
    
Sem2o3:
    movf    sem2, w		;Mover la variable del contador a w
    sublw   0
    btfss   CARRY		;Si la resta da 0 saltar la instrucción 
    goto    Sem2
    goto    Sem3
    

    
Sem1:
    movf    sem1, w		;Mover la variable del contador a w
    sublw   0
    btfss   CARRY		;Si la resta da 0 saltar la instrucción 
    decf    sem1		;Decrementar la variable del contador
    clrf    PORTA
    clrf    PORTB
    bsf	    PORTA, 2
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    bsf	    D1, 0
    bcf	    D1, 1
    bcf	    D1, 2
    retfie
    
Sem2:
    movf    sem2, w		;Mover la variable del contador a w
    sublw   0
    btfss   CARRY
    decf    sem2
    clrf    PORTA
    clrf    PORTB
    bsf	    PORTA, 0
    bsf	    PORTA, 5
    bsf	    PORTA, 6
    bcf	    D1, 0
    bsf	    D1, 1
    bcf	    D1, 2
    retfie
    
Sem3:

    movf    sem3, w		;Mover la variable del contador a w
    sublw   0
    btfss   CARRY
    decf    sem3
    clrf    PORTA
    clrf    PORTB
    bsf	    PORTA, 0
    bsf	    PORTA, 3
    bsf	    PORTB, 3
    bcf	    D1, 0
    bcf	    D1, 1
    bsf	    D1, 2
    movf    sem3, w
    sublw   0
    btfsc   CARRY
    goto    reinicio
   ; movf    v1, w
    ;movwf   sem1
    retfie

reinicio:
    movf    v1, w
    movwf   sem1
    movf    v2, w
    movwf   sem2
    movf    v3, w
    movwf   sem3
    bsf	    D1, 0
    bcf	    D1, 1
    bcf	    D1, 2
    clrf    PORTA
    clrf    PORTB
    bsf	    PORTA, 0
    bsf	    PORTA, 3
    bsf	    PORTB, 3
    retfie



    
PB_int:
    banksel PORTA
    btfss   PORTB, UP	    ;Si esta encendido saltar la instruccion
    incf    PORTA	    ;Incrementar puerto A
    
    btfss   PORTB, DOWN	    ;Si esta encendido saltar la instruccion
    decf    PORTA	    ;Decrementar puerto A
    
    bcf	    RBIF	    ;Limpiar la bandera
   
    return
    
PSECT code, delta=2, abs
ORG 100h		    ; Posicion para el código
Tabla:
;    andlw   00001111B
;    addwf   PCL
;    retlw   00111111B	    ;0
;    retlw   00000110B	    ;1
;    retlw   01011011B	    ;2
;    retlw   01001111B	    ;3
;    retlw   01100110B	    ;4
;    retlw   01101101B	    ;5
;    retlw   01111101B	    ;6
;    retlw   00000111B	    ;7
;    retlw   01111111B	    ;8
;    retlw   01101111B	    ;9
;    retlw   01110111B	    ;A
;    retlw   01111100B	    ;B
;    retlw   00111001B	    ;C
;    retlw   01011110B	    ;D
;    retlw   01111001B	    ;E
;    retlw   01110001B	    ;F
;    retlw   0
    
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
    movlw   01110000B ;Declaramos 3 bits del puerto B como entradas
    movwf   TRISB
    clrf    TRISD     ;Declaramos el puerto D como bits de salida
    clrf    TRISC     ;Declaramos el puerto C como bits de salida
    clrf    TRISA     ;Declaramos el puerto A como bits de salida
    
    
    bcf	    OPTION_REG, 7   ;Habilitar Pullups
    bsf	    WPUB, MODE
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
   
    
    banksel PORTB     ;Borramos cualquier dato en los puertos y las variables
    clrf    PORTB
    clrf    PORTA
    clrf    PORTC
    clrf    PORTD
  
    call conf_reloj   ;Llamamos las configuraciones
    call conf_int
    call conf_PB
    call conf_tmr0
    call conf_tmr1
;    call conf_tmr2
    banksel PORTA
   
    movlw   0x0E
    movwf   v1
    movf    v1, w
    movwf   sem1
    
    movlw   0x0E
    movwf   v2
    movf    v2, w
    movwf   sem2
    
    movlw   0x0E
    movwf   v3
    movf    v3, w
    movwf   sem3
    bsf	    D1, 0
    bcf	    D1, 1
    bcf	    D1, 2
   
    clrf    varcont
    
   
;-----------------loop principal---------------------------
loop:
    
    
    
    
    call    pp_display	    ;Llamamos a preparar display
    btfsc   D1, 0
    movf    sem1, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 1
    movf    sem2, w
    btfsc   D1, 1
    addwf   sem3, w
    btfsc   D1, 2
    movf    sem3, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece1
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni1
    
    btfsc   D1, 0
    movf    sem1, w
    btfsc   D1, 1
    movf    sem2, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 2
    movf    v1, w
    btfsc   D1, 2
    addwf   sem3, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece2
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni2
    
    btfsc   D1, 0
    movf    sem1, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 0
    addwf   sem2, w
    btfsc   D1, 1
    movf    sem2, w
    btfsc   D1, 2
    movf    sem3, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece3
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni3
;    call    v123
	
    goto    loop

;-----------------sub rutinas------------------------------
pp_display:
    movf    dece1, w	    ;El nibble lo movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var	    ;Lo movemos a la variable de display nibble 0
    
    movf    uni1, w	    ;El nibble lo movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+1   ;Lo movemos a la variable de display nibble 1
    
    movf    dece2, w	    ;La variable centena la movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+2   ;Lo movemos a la variable de display nibble 2
    
    movf    uni2, w	    ;La variable decena lo movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+3   ;Lo movemos a la variable de display nibble 3
    
    movf    dece3, w	    ;La variable unidad la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+4   ;Lo movemos a la variable de display nibble 4
    
    movf    uni3, w	    ;La variable unidad la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+5   ;Lo movemos a la variable de display nibble 4
    
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
    bsf	    RBIE    ;Activamos las interrupciones
    bcf	    RBIF    ;Limpiamos la bandera
    
    bsf	    T0IE    ;Actimavos la interrupcion del timer0
    bcf	    T0IF    ;Limpieamos la bandera
    
    bsf	    TMR1IE  ;Activamos la interrupcion del timer1
    bcf	    TMR1IF  ;Limpiamos la bandera
    
    bsf	    TMR2IE  ;Activamos la interrupcion del timer2
    bcf	    TMR2IF  ;Limpiamos la bandera
    return

    
conf_PB:
    banksel TRISA
    bsf	    IOCB, MODE	    ;Habilitar RB5
    ;bsf	    IOCB, UP	    ;Habilitar RB6
    ;bsf	    IOCB, DOWN	    ;Habilitar RB7
    
    banksel PORTA
    movf    PORTB, w	    ;Mover el valor a w
    bcf	    RBIF	    ;Limpiamos la bandera
    
    return

conf_tmr0:
    banksel TRISA
    bcf	    T0CS
    bcf	    PSA
    bsf	    PS2		    ; configuracion del OPTION_REG
    bsf	    PS1	    
    bsf	    PS0		    ;256
    rst_tmr0		    ;Llamamos el reset del timer0
    
    return

conf_tmr1:
    banksel	T1CON
    bcf		T1CON, 1 ;Utilizamos el reloj interno
    bsf		T1CON, 5 ;Prescaler en 1:8
    bsf		T1CON, 4 ;Prescaler en 1:8
    bcf		T1CON, 3 ;Oscilador apagado
    bcf		T1CON, 2 ;El timer1 va a usar el reloj interno
    bsf		T1CON, 0 ;Encender el timer1
    rst_tmr1		 ;Reseteamos el timer1
    return

;conf_tmr2:
;    banksel	T2CON
;    bsf		T2CON, 3 ;Activamos el timer2
;    bsf		T2CON, 4 ;Configuramos el postscaler en 1:16
;    bsf		T2CON, 5
;    bsf		T2CON, 6
;    bsf		T2CON, 1 ;Configuramso el prescaler en 16
;    bsf		T2CON, 2
;    rst_tmr2		 ;Reseteamos el timer2
;    return
    
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

;v123:
;    btfsc   verdet, 0
;    goto    ve1
;    btfsc   verdet, 1
;    goto    ve2
;    retfie
;ve1:
;    btfsc   PORTA, 2
;    goto    off1
;    goto    on1
;    return
;on1:
;    bsf	    PORTA, 2		;Encender el primer bit del puerto A
;    call    delay_big
;    return		;Regresar
;off1:
;    bcf	    PORTA, 2		;Apagar el primer bit del puerto A
;    call    delay_big
;    return
;    
;ve2:
;    btfsc   PORTA, 5
;    goto    off2
;    goto    on2
;    return
;on2:
;    bsf	    PORTA, 5		;Encender el primer bit del puerto A
;    call    delay_big
;    return			;Regresar
;off2:
;    bcf	    PORTA, 5		;Apagar el primer bit del puerto A
;    call    delay_big
;    return  
;    
;delay_big:
;    movlw   1000		    ;valor inicial del contador
;    movwf   cont_big	
;    call    delay_small	    ;rutina de delay
;    decfsz  cont_big, 1	    ;decrementar el contador
;    goto    $-2		    ;ejecutar dos lineas atrás
;    return
;    
;delay_small:
;    movlw   246	    ;valor inicial del contador
;    movwf   cont_small	
;    decfsz  cont_small,	1   ;decrementar el contador
;    goto    $-1		    ;ejecutar la linea anterior
;    return
    
END