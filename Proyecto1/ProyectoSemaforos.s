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
Display macro _nv, _estados0, _estados1

    btfss   PORTB, UP   
    incf    _nv
    movf    _nv, w
    sublw   21
    btfsc   ZERO
    movlw   10
    btfsc   ZERO
    movwf   _nv

    btfss   PORTB, DOWN
    decf    _nv
    movf    _nv, w
    sublw   9
    btfsc   ZERO
    movlw   20
    btfsc   ZERO
    movwf   _nv
    btfss   PORTB, MODE
    bsf	    estado, _estados0
    btfss   PORTB, MODE
    bcf	    estado, _estados1
    bcf	    RBIF
endm
    
MODE	EQU 4		;RB0
UP	EQU 5		;RB1
DOWN	EQU 6		;RB2
EST0	EQU 0		;RB2
EST1	EQU 1		;RB2
EST2	EQU 2		;RB2
EST3	EQU 3		;RB2
EST4	EQU 4		;RB2


PSECT udata_bank0
  vartmr1:	DS  1	;Variable para 1 segundo
  band:		DS  1	;Variable para las banderas
  display_var:	DS  8	;Variable para el display
  dece:		DS  1	;Variable para la decena
  dece1:	DS  1	;Variable para la decena
  dece2:	DS  1	;Variable para la decena
  dece3:	DS  1	;Variable para la decena
  dece4:	DS  1	;Variable para la decena
  uni:		DS  1	;Variable para unidad
  uni1:		DS  1	;Variable para unidad
  uni2:		DS  1	;Variable para unidad
  uni3:		DS  1	;Variable para unidad
  uni4:		DS  1	;Variable para unidad
  div:		DS  1	;Variable para dividir
  vard:		DS  1	;Variable para display
  v1:		DS  1	;Valor inicial 1
  v2:		DS  1	;Valor inicial 2
  v3:		DS  1	;Valor inicial 3
  D1:		DS  1	;Variable display
  vt:		DS  2	;Variable del verde tintilante
  ama:		DS  1	;Variable amarillo
  cont_small:	DS 2; 1 byte
  cont_big:	DS 2
  estado:	DS 1
  of:		DS 1
  nv1:		DS 1
  nv2:		DS 1
  nv3:		DS 1
  YN:		DS 1
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
    
    btfss   RBIF	;Si esta en cero saltar la instruccion de abajo
    goto    pop
    
    btfss   estado, 0
    goto    estado_0_int
    btfss   estado, 1
    goto    estado_1_int
    btfss   estado, 2
    goto    estado_2_int
    btfss   estado, 3
    goto    estado_3_int
    btfss   estado, 4
    goto    estado_4_int
       
estado_0_int:
    btfss   PORTB, MODE
    bsf	    estado, 0
    bcf	    estado, 1
    bcf	    RBIF
    goto    pop
estado_1_int:
    Display nv1, EST1, EST2
    goto    pop
estado_2_int:
    Display nv2, EST2, EST3
    goto    pop
estado_3_int:
    Display nv3, EST3, EST4
    goto    pop
estado_4_int:
    btfss   PORTB, MODE
    bsf	    estado, 4
    btfss   PORTB, MODE
    bcf	    estado, 0
    btfss   PORTB, UP
    bsf	    YN, 0
    btfss   PORTB, DOWN
    bsf	    YN, 1
    bcf	    RBIF
    goto    pop
    
    
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
    
    btfss   band, 6
    goto    display_6
    
    btfss   band, 7
    goto    display_7
    
display_0:
    clrf    band		;Limpiar banderas cada vez que se empieza	
    bsf	    band, 0		;Lo volvemos 1 para pasar de instrucción
    movf    display_var+0, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    btfsc   vard, 0	    ;Si la variable no esta en cero limpiar el puerto
    clrf    PORTC
    bsf	    PORTD, 0		;Encendemos el bit 1 del puerto D
    return
   
display_1:
    bsf	    band, 1		;Volvemos 1 para pasar la instrucción
    movf    display_var+1, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    btfsc   vard, 0	    ;Si la variable no esta en cero limpiar el puerto
    clrf    PORTC
    bsf	    PORTD, 1		;Encendemos el bit 0 del puerto D
    return
    
display_2:
    
    bsf	    band, 2		;Volvemos 1 para pasar la instrucción
    movf    display_var+2, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    btfsc   vard, 1	    ;Si la variable no esta en cero limpiar el puerto
    clrf    PORTC
    bsf	    PORTD, 2		;Encendemos el bit 2 del puerto D
    return
    
display_3:
     
    bsf	    band, 3		;Volvemos 1 para pasar la instrucción
    movf    display_var+3, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    btfsc   vard, 1	    ;Si la variable no esta en cero limpiar el puerto
    clrf    PORTC
    bsf	    PORTD, 3		;Encendemos el bit 3 del puerto D
    return

display_4:
  
    bsf	    band, 4		;Volvemos 1 para pasar la instrucción
    movf    display_var+4, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    btfsc   vard, 2	    ;Si la variable no esta en cero limpiar el puerto
    clrf    PORTC
    bsf	    PORTD, 4		;Encendemos el bit 4 del puerto D
    return

display_5:
  
    bsf	    band, 5		;Volvemos 1 para pasar la instrucción
    movf    display_var+5, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    btfsc   vard, 2	    ;Si la variable no esta en cero limpiar el puerto
    clrf    PORTC
    bsf	    PORTD, 5		;Encendemos el bit 4 del puerto D
    return
 
display_6:
  
    bsf	    band, 6		;Volvemos 1 para pasar la instrucción
    movf    display_var+6, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    btfsc   vard, 3
    bcf	    PORTD, 6
    btfss   vard, 3
    bsf	    PORTD, 6		;Encendemos el bit 4 del puerto D
    return
    
display_7:
  
    bsf	    band, 7		;Volvemos 1 para pasar la instrucción
    movf    display_var+7, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    btfsc   vard, 3
    bcf	    PORTD, 7
    btfss   vard, 3
    bsf	    PORTD, 7		;Encendemos el bit 4 del puerto D
    return 
    
int_tmr1:
    rst_tmr1			;Reseteamos el timer1
    incf    vartmr1		;Incrementamos la variable del timer1
    movf    vartmr1, w		;Movemos la variable a w
    sublw   1			;Le restamos dos veces para poder tener 1seg
    btfsc   CARRY		;Si esta en 1 saltar la instrucción de abajo
    return
    clrf    vartmr1		;Limpiar la variable 
    btfsc   YN, 3
    bcf	    YN, 0
    btfsc   YN, 0
    goto    BDOWN
    btfsc   of, 4
    call    reseteo
    movf    sem1, w
    sublw   0
    btfss   CARRY		;Si la resta da 0 saltar la instrucción 
    goto    Sem1
    goto    Sem2o3  
    
Sem2o3:
    movf    sem2, w		;Mover la variable del contador a w
    sublw   0
    btfss   CARRY		;Si la resta da 0 saltar la instrucción 
    goto    Sem2
    goto    Sem3
  
Sem1:
    bcf	    of, 4
    movf    sem1, w		;Mover la variable del contador a w
    sublw   0
    btfss   CARRY		;Si la resta da 0 saltar la instrucción 
    decf    sem1		;Decrementar la variable del contador
    bsf	    D1, 0
    bcf	    D1, 1
    retfie
    
Sem2:
    movf    sem2, w		;Mover la variable del contador a w
    sublw   0
    btfss   CARRY
    decf    sem2
    bcf	    D1, 0
    bsf	    D1, 1
    retfie
    
Sem3:
    movf    sem3, w		;Mover la variable del contador a w
    sublw   0
    btfss   CARRY
    decf    sem3
    bcf	    D1, 1
    bsf	    D1, 2
    retfie
reseteo:
    bsf	    D1, 0
    bcf	    D1, 1
    bcf	    D1, 2
    goto    pop
BDOWN:
    bcf	    PORTA, 1
    bcf	    PORTA, 2
    bcf	    PORTA, 4
    bcf	    PORTA, 5
    bcf	    PORTA, 7
    bcf	    PORTB, 3
    bsf	    PORTA, 0
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    bsf	    YN, 3
    goto    pop
    
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
    movlw   01110000B ;Declaramos 3 bits del puerto B como entradas
    movwf   TRISB
    clrf    TRISD     ;Declaramos el puerto D como bits de salida
    clrf    TRISC     ;Declaramos el puerto C como bits de salida
    clrf    TRISA     ;Declaramos el puerto A como bits de salida
    clrf    TRISE
    
    
    bcf	    OPTION_REG, 7   ;Habilitar Pullups
    bsf	    WPUB, MODE
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
   
    
    banksel PORTB     ;Borramos cualquier dato en los puertos y las variables
    clrf    PORTB
    clrf    PORTA
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
  
    call conf_reloj   ;Llamamos las configuraciones
    call conf_int
    call conf_PB
    call conf_tmr0
    call conf_tmr1

    banksel PORTA
   
    movlw   0x0F
    movwf   v1
    movf    v1, w
    movwf   sem1
    
    movlw   0x0F
    movwf   nv1
    
    movlw   0x0F
    movwf   nv2
    
    movlw   0x0F
    movwf   nv3
    
    movlw   0x0F
    movwf   v2
    movf    v2, w
    movwf   sem2
    
    movlw   0x0F
    movwf   v3
    movf    v3, w
    movwf   sem3
    bsf	    D1, 0
    bcf	    D1, 1
    bcf	    D1, 2
    bcf	    ama,0
    bcf	    ama,1
    bcf	    ama,2
   
    
   
;-----------------loop principal---------------------------
loop:
;Ejecutar independientemente del estado en que se encuentra 
    call    pp_display	    ;Llamamos a preparar display
    btfsc   YN, 3
    call    r_ama 
    btfsc   D1, 0
    call    comp1
    btfsc   D1, 0
    movf    sem1, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 1
    movf    sem2, w
    btfsc   D1, 1
    addwf   sem3, w
    btfsc   D1, 2
    movf    sem3, w
    btfsc   of, 4
    movf    nv1, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece1
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni1
    
    btfsc   D1, 1
    call    comp2
    btfsc   D1, 0
    movf    sem1, w
    btfsc   D1, 1
    movf    sem2, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 2
    movf    v1, w
    btfsc   D1, 2
    addwf   sem3, w
    btfsc   of, 4
    movf    nv2, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece2
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni2
    
    btfsc   D1, 2
    call    comp3
    btfsc   D1, 0
    movf    sem1, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 0
    addwf   sem2, w
    btfsc   D1, 1
    movf    sem2, w
    btfsc   D1, 2
    movf    sem3, w
    btfsc   of, 4
    movf    nv3, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece3
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni3
    btfsc   ama, 0
    bsf	    PORTA, 1
    btfss   ama, 0
    bcf	    PORTA, 1
    btfsc   ama, 0
    bcf	    PORTA, 2
    btfsc   ama, 1
    bsf	    PORTA, 4
    btfss   ama, 1
    bcf	    PORTA, 4
    btfsc   ama, 1
    bcf	    PORTA, 5
    btfsc   ama, 2
    bsf	    PORTA, 7
    btfss   ama, 2
    bcf	    PORTA, 7
    btfsc   ama, 2
    bcf	    PORTB, 3
    btfsc   YN, 0
    call    Yes
    btfsc   YN, 1
    call    No
    btfsc   YN, 3
    call    LEDR
    btfss   YN, 3
    call    v123 
    
    
;revisar estado
    btfss   estado, 0
    goto    estado_0
    btfss   estado, 1
    goto    estado_1
    btfss   estado, 2
    goto    estado_2
    btfss   estado, 3
    goto    estado_3
    btfss   estado, 4
    goto    estado_4
    
estado_0:
    bcf	    PORTB, 2
    bcf	    PORTB, 1
    bcf	    PORTB, 0
    bsf	    vard, 3
    movlw   0
    movwf   display_var+6
    movlw   0
    movwf   display_var+7
    goto    loop
    
estado_1:
    bcf	    vard, 3
    bsf	    PORTB, 0
    movf    nv1, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece4
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni4    
    goto    loop
    
estado_2:
    bcf	    PORTB, 0
    bsf	    PORTB, 1
    movf    nv2, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece4
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni4    
    goto    loop
    
estado_3:
    bcf	    PORTB, 1
    bsf	    PORTB, 2
    movf    nv3, w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece4
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni4    
    goto    loop   
    
estado_4:
    bsf	    PORTB, 0
    bsf	    PORTB, 1 
    bsf	    vard, 3
    movlw   0
    movwf   display_var+6
    movlw   0
    movwf   display_var+7 
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
    
    movf    dece4, w	    ;La variable unidad la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+6   ;Lo movemos a la variable de display nibble 4
    
    movf    uni4, w	    ;La variable unidad la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+7   ;Lo movemos a la variable de display nibble 4
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
    return

    
conf_PB:
    banksel TRISA
    bsf	    IOCB, MODE	    ;Habilitar RB5
    bsf	    IOCB, UP	    ;Habilitar RB6
    bsf	    IOCB, DOWN	    ;Habilitar RB7
    
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

v123:
    btfsc   vt, 0
    call    ve1
    btfsc   vt, 1
    call    ve2
    btfsc   vt, 2
    call    ve3
    return
ve1:    
    bcf     of, 0
    btfsc   PORTA, 2
    call    off1
    btfsc   of, 0
    return
    call    on1
    return
on1:
    bsf	    PORTA, 2		;Encender el primer bit del puerto A
    bcf	    vard, 0
    call    delay_big
    return		;Regresar
off1:
    bcf	    PORTA, 2		;Apagar el primer bit del puerto A
    bsf	    vard, 0
    bsf	    of, 0
    call    delay_big
    return
    
ve2:
    bcf	    of, 1
    btfsc   PORTA, 5
    call    off2
    btfsc   of, 1
    return
    call    on2
    return
on2:
    bsf	    PORTA, 5		;Encender el primer bit del puerto A
    bcf	    vard, 1
    call    delay_big
    return			;Regresar
off2:
    bcf	    PORTA, 5		;Apagar el primer bit del puerto A
    bsf	    vard, 1
    bsf	    of, 1
    call    delay_big
    return  
ve3:
    bcf	    of, 2
    btfsc   PORTB, 3
    call    off3
    btfsc   of, 2
    return
    call    on3
    return
on3:
    bsf	    PORTB, 3		;Encender el primer bit del puerto A
    bcf	    vard, 2
    call    delay_big
    return			;Regresar
off3:
    bcf	    PORTB, 3		;Apagar el primer bit del puerto A
    bsf	    vard, 2
    bsf	    of, 2
    call    delay_big
    return 
    
delay_big:
    movlw   200		    ;valor inicial del contador
    movwf   cont_big	
    call    delay_small	    ;rutina de delay
    decfsz  cont_big, 1	    ;decrementar el contador
    goto    $-2		    ;ejecutar dos lineas atrás
    return
    
delay_small:
    movlw   246	    ;valor inicial del contador
    movwf   cont_small	
    decfsz  cont_small,	1   ;decrementar el contador
    goto    $-1		    ;ejecutar la linea anterior
    return   
comp1:
    btfss   YN, 0
    call    compr1
    return
compr1:
    bcf	    YN, 3
    movf    sem1, w
    sublw   5
    btfsc   CARRY
    goto    verdet1
    bcf	    ama, 2
    bcf	    vt,0
    bcf	    vt,1
    bcf	    vt,2
    bcf	    vard, 1
    bcf	    vard, 0
    bcf	    vard, 2
    bcf	    PORTA, 0
    bcf	    PORTA, 5
    bcf	    PORTB, 3
    bsf	    PORTA, 2
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    return
verdet1:
    bsf	    vt,0
    movf    sem1, w
    sublw   2
    btfsc   CARRY
    call    am1
    return
am1:
    bsf	    ama,0
    bcf	    ama,2
    bcf	    vt,0
    bcf	    vard, 0
    return 
comp2:
    btfss   YN, 0
    call    compr2
    return
compr2:
    movf    sem2, w
    sublw   5
    btfsc   CARRY
    goto    verdet2
    bcf	    ama, 0
    bcf     PORTA, 3
    bcf	    PORTA, 2
    bsf	    PORTA, 0
    bsf	    PORTA, 5
    bsf	    PORTA, 6
    return
    
verdet2:
    bsf	    vt,1
    movf    sem2, w
    sublw   2
    btfsc   CARRY
    call    am2
    return

am2:
    bcf	    ama, 0
    bsf	    ama, 1
    bcf	    vt, 1
    bcf	    vard, 1
    return
    
comp3:
    btfss   YN, 0
    call    compr3
    return   
compr3:
    movf    sem3, w
    sublw   5
    btfsc   CARRY
    goto    verdet3
    btfsc   of, 4
    return
    bcf	    ama, 1
    bcf	    PORTA, 5
    bcf	    PORTA, 6
    bsf	    PORTA, 0
    bsf	    PORTA, 3
    bsf	    PORTB, 3
    return
        
verdet3:
    bsf	    vt,2
    movf    sem3, w
    sublw   2
    btfsc   CARRY
    call    am3
    return

am3:
    bcf	    ama,1
    bsf	    ama,2
    bcf	    vt,2
    bcf	    vard, 2
    movf    sem3, w
    sublw   0
    btfsc   CARRY
    call    rst
    return
rst:
    
    bsf	    of, 4
    bcf	    ama,0
    bcf	    ama,1
    bcf	    ama,2
    bcf	    PORTA, 1
    bcf	    PORTA, 2
    bcf	    PORTA, 4
    bcf	    PORTA, 5
    bcf	    PORTA, 7
    bcf	    PORTB, 3
    bsf	    D1, 0
    bcf	    D1, 1
    bcf	    D1, 2
    return
Yes:
    movf    nv1, w
    movwf   v1
    movf    nv2, w
    movwf   v2
    movwf   nv3, w
    movwf   v3
    call    rst
    return
;    
;rst2:
;    bcf	    PORTA, 1
;    bcf	    PORTA, 2
;    bcf	    PORTA, 4
;    bcf	    PORTA, 5
;    bcf	    PORTA, 7
;    bcf	    PORTB, 3
;    bsf	    D1, 0
;    bcf	    D1, 1
;    bcf	    D1, 2
;    return
    
No:
    movlw   0x0F
    movwf   nv1
    movlw   0x0F
    movwf   nv2
    movlw   0x0F
    movwf   nv3
    bcf	    YN, 1
    return
LEDR:
    bcf	    PORTA, 1
    bcf	    PORTA, 2
    bcf	    PORTA, 4
    bcf	    PORTA, 5
    bcf	    PORTA, 7
    bcf	    PORTB, 3
    movf    v1, w
    movwf   sem1
    movf    v2, w
    movwf   sem2
    movf    v3, w
    movwf   sem3
    return
r_ama:
    bcf	    ama, 2
    bcf	    ama, 1
    bcf	    ama, 0
    bcf	    vt, 2
    bcf	    vt, 1
    bcf	    vt, 0
    bcf	    vard, 1
    bcf	    vard, 0
    bcf	    vard, 2
    
    return
END