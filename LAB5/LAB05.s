;Archivo:	LAB05.s
;Dispositivo:	PIC16F887
;Autor:		Brayan Castillo
;Compilador:	pic-as (v2.30), MPLABX V5.45
;
;Programa:	Displays simultáneos con interrupciones
;Hardware:	LEDs en el puerto A, 7 segmentos multiplexados en puerto C y D, y
;		Botones en el puerto B 
;
;Creado: 2 marzo, 2021
;Última modificación: 2 de marzo, 2021
    

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
    movlw   217		;10ms 
    movwf   TMR0
    bcf	    T0IF 
    endm
UP	EQU 0		;RB0
DOWN	EQU 7		;RB7
PSECT udata_bank0
  var1:		DS  1	;Variable para el contador
  band:		DS  1	;Variable para las banderas
  nibble:	DS  2	;Variable para el nibble
  display_var:	DS  5	;Variable para el display
  cent:		DS  1	;Variable para la centena
  dece:		DS  1	;Variable para la decena
  uni:		DS  1	;Variable para unidad
  div:		DS  1	;Variable para dividir
    
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
    
    btfsc   RBIF	;Si esta en cero saltar la instruccion de abajo
    call    PB_int	;Llamar la subrutina de los interrupciones en puerto B
  
    
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
   
    
display_0:
    clrf    band		;Limpiar banderas cada vez que se empieza	
    bsf	    band, 0		;Lo volvemos 1 para pasar de instrucción
    movf    display_var+0, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    bsf	    PORTD, 1		;Encendemos el bit 1 del puerto D
    
    return
   
display_1:
   
    bsf	    band, 1		;Volvemos 1 para pasar la instrucción
    movf    display_var+1, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    bsf	    PORTD, 0		;Encendemos el bit 0 del puerto D
    
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
    movlw   10000001B ;Declaramos 2 bits del puerto B como entradas
    movwf   TRISB
    movlw   11100000B ;Declaramos el puerto D como 5 bits de salida
    movwf   TRISD
    clrf    TRISC     ;Declaramos el puerto C como bits de salida
    clrf    TRISA     ;Declaramos el puerto A como bits de salida
    
    
    bcf	    OPTION_REG, 7   ;Habilitar Pullups
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
   
    
    banksel PORTB     ;Borramos cualquier dato en los puertos y las variables
    clrf    PORTA
    clrf    PORTC
    clrf    PORTD
  
    call conf_reloj   ;Llamamos las configuraciones
    call conf_int
    call conf_PB
    call conf_tmr0
    banksel PORTA
   
;-----------------loop principal---------------------------
loop:
    movf    PORTA, w	    ;Movemos el valor del puerto A a w
    movwf   var1	    ;Movemos w a una variable
    call    sep_nibbles	    ;Llamamos a separar los nibles
    call    pp_display	    ;Llamamos a preparar display
    
    movf    PORTA, w	    ;Movemos el valor del puerto A a w
    movwf   div		    ;Movemos el valor a una variable
    call    div_100	    ;Llamamos la division por 100
    movf    cent, w	    ;Movemos la centena a w
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    
    goto    loop

;-----------------sub rutinas------------------------------
sep_nibbles:
    movf    var1, w	;Movemos la variable a w
    andlw   0x0f	;Realizamos un and con una literal
    movwf   nibble	;Movemos w al primer nibble
    swapf   var1, w	;Hacemos un swap para cambiar los nibbles
    andlw   0x0f	;Realizamos un and con la literal
    movwf   nibble+1	;Movemos w al segundo nibble
    
    return

pp_display:
    movf    nibble, w	    ;El nibble lo movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var	    ;Lo movemos a la variable de display nibble 0
    
    movf    nibble+1, w	    ;El nibble lo movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+1   ;Lo movemos a la variable de display nibble 1
    
    movf    cent, w	    ;La variable centena la movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+2   ;Lo movemos a la variable de display nibble 2
    
    movf    dece, w	    ;La variable decena lo movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+3   ;Lo movemos a la variable de display nibble 3
    
    movf    uni, w	    ;La variable unidad la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+4   ;Lo movemos a la variable de display nibble 4
    
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
    
    return
    
conf_PB:
    banksel TRISA
    bsf	    IOCB, UP	    ;Habilitar RB0
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
    
div_100:
    clrf    cent    ;Limpiar la variable centenas
    movlw   100	    ;Mover la literal a w
    subwf   div, f  ;Restarle a la variable w
    btfsc   CARRY   ;Si CARRY esta en cero saltarse la instruccion de abajo
    incf    cent    ;Incrementar la variabel centena
    btfsc   CARRY   ;Si CARRY esta en cero saltarse la instruccion de abajo
    goto    $-5	    ;Regresar 5 lineas
    movlw   100	    ;Mover la literal a w
    addwf   div, f  ;Sumarle a la variable w
    
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
