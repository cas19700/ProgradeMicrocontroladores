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

    btfss   PORTB, UP   ;Si se presiona incrementar la variable
    incf    _nv
    movf    _nv, w
    sublw   21		;Comprobar que no pase de 20
    btfsc   ZERO
    movlw   10		
    btfsc   ZERO
    movwf   _nv

    btfss   PORTB, DOWN	;Si se presiona decrementar la variable
    decf    _nv
    movf    _nv, w	;Comprobar que no pase de 10
    sublw   9
    btfsc   ZERO
    movlw   20
    btfsc   ZERO
    movwf   _nv
    btfss   PORTB, MODE		;Si se presiona encender y cambiar las banderas
    bsf	    estado, _estados0
    btfss   PORTB, MODE
    bcf	    estado, _estados1
    bcf	    RBIF		;Limpiar la bandera de interrupcion
endm
    
MODE	EQU 4		;RB4
UP	EQU 5		;RB5
DOWN	EQU 6		;RB6
EST0	EQU 0		;Estado0
EST1	EQU 1		;Estado1
EST2	EQU 2		;Estado2
EST3	EQU 3		;Estado3
EST4	EQU 4		;Estado4


PSECT udata_bank0
  vartmr1:	DS  1	;Variable para 1 segundo
  band:		DS  1	;Variable para las banderas
  display_var:	DS  8	;Variable para el display
  dece:		DS  1	;Variable para la decena
  dece1:	DS  1	;Variable para la decena display 1
  dece2:	DS  1	;Variable para la decena display 2
  dece3:	DS  1	;Variable para la decena display 3
  dece4:	DS  1	;Variable para la decena display 4
  uni:		DS  1	;Variable para unidad
  uni1:		DS  1	;Variable para unidad display 1
  uni2:		DS  1	;Variable para unidad display 2
  uni3:		DS  1	;Variable para unidad display 3
  uni4:		DS  1	;Variable para unidad display 4
  div:		DS  1	;Variable para dividir
  vard:		DS  1	;Variable para displays
  v1:		DS  1	;Valor inicial 1
  v2:		DS  1	;Valor inicial 2
  v3:		DS  1	;Valor inicial 3
  D1:		DS  1	;Variable display tintilantes
  vt:		DS  2	;Variable del verde tintilante
  ama:		DS  1	;Variable amarillo
  cont_small:	DS 2	;Variable contador pequeño
  cont_big:	DS 2	;Variable contador grande
  estado:	DS 1	;Variable para los estados
  of:		DS 1	;Variable encendido/apagado
  nv1:		DS 1	;Nueva variable inicial 1
  nv2:		DS 1	;Nueva variable inicial 2
  nv3:		DS 1	;Nueva variable inicial 3
  YN:		DS 1	;Yes/No
  sem1:		DS  1	;Variable para el semaforo 1
  sem2:		DS  1	;Variable para el semaforo 2
  sem3:		DS  1	;Variable para el semaforo 3
    
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
    
    btfss   estado, 0	    ;Si la bandera esta encendida saltar
    goto    estado_0_int    ;Ir a la interrupcion del estado 0
    btfss   estado, 1	    ;Si la bandera esta encendida saltar
    goto    estado_1_int    ;Ir a la interrupcion del estado 1
    btfss   estado, 2	    ;Si la bandera esta encendida saltar
    goto    estado_2_int    ;Ir a la interrupcion del estado 2
    btfss   estado, 3	    ;Si la bandera esta encendida saltar
    goto    estado_3_int    ;Ir a la interrupcion del estado 3
    btfss   estado, 4	    ;Si la bandera esta encendida saltar
    goto    estado_4_int    ;Ir a la interrupcion del estado 4
       
estado_0_int:
    btfss   PORTB, MODE	    ;Si se presiona cambiar al siguiente estado
    bsf	    estado, 0
    bcf	    estado, 1
    bcf	    RBIF	    ;Limpiar la bandera de interrupcion
    goto    pop
estado_1_int:
    Display nv1, EST1, EST2 ;Macro mostrada antes
    goto    pop
estado_2_int:
    Display nv2, EST2, EST3 ;Macro mostrada antes
    goto    pop
estado_3_int:
    Display nv3, EST3, EST4 ;Macro mostrada antes
    goto    pop
estado_4_int:
    btfss   PORTB, MODE	    ;Si se presiona cambiar de estado
    bsf	    estado, 4
    btfss   PORTB, MODE
    bcf	    estado, 0
    btfss   PORTB, UP	    ;Si se presiona "aceptar" los cambios
    bsf	    YN, 0
    btfss   PORTB, DOWN	    ;Si se presiona "cancelar" los cambios
    bsf	    YN, 1
    bcf	    RBIF	    ;Limpiar la bandera de interrupcion
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
    btfsc   vard, 0	        ;Saltar la instrucción 
    clrf    PORTC		;Limpiar el puerto C
    bsf	    PORTD, 0		;Encendemos el bit 0 del puerto D
    return
   
display_1:
    bsf	    band, 1		;Volvemos 1 para pasar la instrucción
    movf    display_var+1, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    btfsc   vard, 0	        ;Saltar la instruccipon
    clrf    PORTC		;Limpiar el puerto C
    bsf	    PORTD, 1		;Encendemos el bit 1 del puerto D
    return
    
display_2:
    
    bsf	    band, 2		;Volvemos 1 para pasar la instrucción
    movf    display_var+2, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    btfsc   vard, 1	        ;Saltar la instruccion
    clrf    PORTC		;Limpiar el puerto C
    bsf	    PORTD, 2		;Encendemos el bit 2 del puerto D
    return
    
display_3:
     
    bsf	    band, 3		;Volvemos 1 para pasar la instrucción
    movf    display_var+3, w	;Movemos el nibble a w
    movwf   PORTC		;Movemos w al puerto C
    btfsc   vard, 1	        ;Saltar la instruccion
    clrf    PORTC		;Limpiar el puerto C
    bsf	    PORTD, 3		;Encendemos el bit 3 del puerto D
    return

display_4:
  
    bsf	    band, 4		;Volvemos 1 para pasar la instrucción
    movf    display_var+4, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    btfsc   vard, 2	        ;Saltar la instruccion
    clrf    PORTC		;Limpiar el puerto C
    bsf	    PORTD, 4		;Encendemos el bit 4 del puerto D
    return

display_5:
  
    bsf	    band, 5		;Volvemos 1 para pasar la instrucción
    movf    display_var+5, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    btfsc   vard, 2	        ;Saltar la instruccion
    clrf    PORTC		;Limpiar el puerto C
    bsf	    PORTD, 5		;Encendemos el bit 5 del puerto D
    return
 
display_6:
  
    bsf	    band, 6		;Volvemos 1 para pasar la instrucción
    movf    display_var+6, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    btfsc   vard, 3		;Saltar la instruccion
    bcf	    PORTD, 6		;Apagar el bit 6 del puerto D
    btfss   vard, 3		;Saltar la instruccion
    bsf	    PORTD, 6		;Encendemos el bit 6 del puerto D
    return
    
display_7:
  
    bsf	    band, 7		;Volvemos 1 para pasar la instrucción
    movf    display_var+7, w	;Movemos el nibble a w
    movwf   PORTC		;Encendemos w al puerto C
    btfsc   vard, 3		;Saltar la instruccion
    bcf	    PORTD, 7		;Apagar el bit 7 del puerto D
    btfss   vard, 3		;Saltar la instruccion
    bsf	    PORTD, 7		;Encendemos el bit 7 del puerto D
    return 
    
int_tmr1:
    rst_tmr1			;Reseteamos el timer1
    incf    vartmr1		;Incrementamos la variable del timer1
    movf    vartmr1, w		;Movemos la variable a w
    sublw   1			;Le restamos dos veces para poder tener 1seg
    btfsc   CARRY		;Si esta en 1 saltar la instrucción de abajo
    return
    clrf    vartmr1		;Limpiar la variable 
    bcf	    D1, 3		;Limpiamos la variable del reset
    btfsc   YN, 3		;Si la variable Yes/No esta en cero saltar
    bcf	    YN, 0		;Limpiar la variable del "aceptar"
    btfsc   YN, 0		;Saltar instruccion
    goto    BDOWN		;Ir a BDOWN
    movf    sem1, w		;Mover sem1 a w
    sublw   0			;Restarle a 0 el valor de sem1
    btfss   CARRY		;Si la resta da 0 saltar la instrucción 
    goto    Sem1		;Ir a la subrutina
    goto    Sem2o3		;Ir a la subrutina
    
Sem2o3:
    movf    sem2, w		;Mover la variable del contador a w
    sublw   0			;Restarle a 0 el valor de sem2
    btfss   CARRY		;Si la resta da 0 saltar la instrucción 
    goto    Sem2		;Ir a la subrutina
    goto    Sem3		;Ir a la subrutina
  
Sem1:
    bcf	    of, 4		;Limpiar la bandera en caso de reset
    movf    sem1, w		;Mover la variable del contador a w
    btfss   ZERO		;Si la resta da 0 saltar la instrucción 
    decf    sem1		;Decrementar la variable del contador
    bsf	    D1, 0		;Encender la bandera para el semaforo1
    bcf	    D1, 2		;Apagar la bandera para el semaforo3
    retfie
    
Sem2:
    movf    sem2, w		;Mover la variable del contador a w
    btfss   ZERO		;Si da 0 saltar la instruccion
    decf    sem2		;Decrementar la variable
    bcf	    D1, 0		;Limpiar la bandera del semaforo1
    bsf	    D1, 1		;Encender la bandera del semaforo2
    retfie
    
Sem3:
    decf    sem3		;Decrementar la variable
    movf    sem3, w		;Mover la variable a w
    sublw   255			;Restarle 255
    btfsc   ZERO		;Si da 0 saltar la instruccion
    goto    reseteo		;Ir a la subrutina
    bcf	    D1, 1		;Limpiar la bandera del semaforo2
    bsf	    D1, 2		;Encender la bandera del semaforo3  
    retfie
    
reseteo:
    incf    sem3		;Incrementar la variable
    bsf	    D1, 3		;Encender la bandera del reset
    bsf	    D1, 0		;Encender la bandera del semaforo1
    bcf	    D1, 1		;Apagar la bandera del semaforo 2
    goto    pop
BDOWN:
    bcf	    PORTA, 1		;Apagar los LEDS que no sean los rojos
    bcf	    PORTA, 2
    bcf	    PORTA, 4
    bcf	    PORTA, 5
    bcf	    PORTA, 7
    bcf	    PORTB, 3
    bsf	    PORTA, 0		;Encender los LEDS rojos
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    bsf	    YN, 3		;Bandera para el reset 
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
   
    movlw   0x0F	;Declaramos los valores iniciales para las variables
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
    bsf	    D1, 0   ;Valores iniciales para las banderas
    bcf	    D1, 1
    bcf	    D1, 2
    bcf	    ama,0
    bcf	    ama,1
    bcf	    ama,2
   
    
   
;-----------------loop principal---------------------------
loop:
;Ejecutar independientemente del estado en que se encuentra 
    call    pp_display	    ;Llamamos a preparar display
    btfsc   YN, 3	    ;Si la bandera esta apagada saltar la instruccion
    call    r_ama	    ;Ir a la subrutina
    btfsc   D1, 0	    ;Saltar instruccion
    call    comp1	    ;Comprobacion del semaforo1
    btfsc   D1, 0	    ;Saltar instruccion
    movf    sem1, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 1	    ;Saltar instruccion
    movf    sem2, w	    ;Mover sem2 a w
    btfsc   D1, 1	    ;Saltar instruccion
    addwf   sem3, w	    ;Mover sem3 a w
    btfsc   D1, 2	    ;Saltar instruccion
    movf    sem3, w	    ;Mover sem3 a w
    btfsc   of, 4	    ;Saltar instruccion
    movf    nv1, w	    ;Mover nuevo valor a w
    btfsc   D1, 3	    ;Saltar instruccion
    movf    sem3	    ;Mover sem3 a w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece1	    ;Movemos el valor a dece1
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni1	    ;Movemos el valor a uni1
    
    btfsc   D1, 1	    ;Saltar instruccion
    call    comp2	    ;Comprobacion del semaforo2
    btfsc   D1, 0	    ;Saltar instruccion
    movf    sem1, w	    ;Mover sem1 a w
    btfsc   D1, 1	    ;Saltar instruccion
    movf    sem2, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 2	    ;Saltar instruccion
    movf    v1, w	    ;Movemos v1 a w
    btfsc   D1, 2	    ;Saltar instruccion
    addwf   sem3, w	    ;Sumamos sem3 a w
    btfsc   of, 4	    ;Saltar instruccion
    movf    nv2, w	    ;Movemos nuevo valor 2 a w
    btfsc   D1, 3	    ;Saltar instruccion
    movf    sem3	    ;Movemos sem3 a w
    btfsc   D1, 3	    ;Saltar instruccion
    addwf   v1		    ;Sumar el valor inicial de la variable 1
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece2	    ;Movemos el valor a dece2
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni2	    ;Movemos el valor a uni2
    
    btfsc   D1, 2	    ;Saltar instruccion
    call    comp3	    ;Comprobar semaforo3
    btfsc   D1, 0	    ;Saltar instruccion
    movf    sem1, w	    ;Movemos el valor de la variable a w
    btfsc   D1, 0	    ;Saltar instruccion
    addwf   sem2, w	    ;Sumar sem2 a w
    btfsc   D1, 1	    ;Saltar instruccion
    movf    sem2, w	    ;Mover sem2 a w
    btfsc   D1, 2	    ;Saltar instruccion
    movf    sem3, w	    ;Mover sem3 a w
    btfsc   of, 4	    ;Saltar instruccion
    movf    nv3, w	    ;Mover nuevo valor 3 a w
    btfsc   D1, 3	    ;Saltar instruccion
    movf    sem3	    ;Mover sem3 a w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece3	    ;Movemos el valor a dece3
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni3	    ;Movemos el valor a uni3
    btfsc   ama, 0	    ;Saltar instruccion
    bsf	    PORTA, 1	    ;Encender el LED
    btfss   ama, 0	    ;Saltar instruccion
    bcf	    PORTA, 1	    ;Apagar el LED
    btfsc   ama, 0	    ;Saltar instruccion
    bcf	    PORTA, 2	    ;Apagar el LED
    btfsc   ama, 1	    ;Saltar instruccion
    bsf	    PORTA, 4	    ;Encender el LED
    btfss   ama, 1	    ;Saltar instruccion
    bcf	    PORTA, 4	    ;Apagar LED
    btfsc   ama, 1	    ;Saltar instruccion
    bcf	    PORTA, 5	    ;Apagar LED
    btfsc   ama, 2	    ;Saltar instruccion
    bsf	    PORTA, 7	    ;Encender LED
    btfss   ama, 2	    ;Saltar instruccion
    bcf	    PORTA, 7	    ;Apagar LED
    btfsc   ama, 2	    ;Saltar instruccion
    bcf	    PORTB, 3	    ;Apagar LED
    btfsc   YN, 0	    ;Saltar instruccion
    call    Yes		    ;Aceptar cambios
    btfsc   YN, 1	    ;Saltar instruccion
    call    No		    ;Descartar cambios
    btfsc   YN, 3	    ;Saltar instruccion
    call    LEDR	    ;Reset de LEDS
    btfss   YN, 3	    ;Saltar instruccion
    call    v123	    ;Verdes tintilantes
    btfsc   D1, 3	    ;Saltar instruccion
    call    rst		    ;Reset de valores
    
    
;revisar estado
    btfss   estado, 0	    ;Cambios de estados
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
    bcf	    PORTB, 2	    ;Apagar LEDS para indicar estado0
    bcf	    PORTB, 1
    bcf	    PORTB, 0
    bsf	    vard, 3	    ;Apagar el 7 segmentos que no se utiliza
    movlw   0
    movwf   display_var+6
    movlw   0
    movwf   display_var+7
    goto    loop	    ;Ir al loop
    
estado_1:
    bcf	    vard, 3	    ;Apagar la bandera del 7 segmentos
    bsf	    PORTB, 0	    ;Encender el LED para indicar el estado
    movf    nv1, w	    ;Mover nuevo valor 1 a w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece4	    ;Movemos el valor a dece4
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni4	    ;Movemos el valor a uni4
    goto    loop	    ;Ir al Loop
    
estado_2:
    bcf	    PORTB, 0	    ;Apagamos y encendemos LED para indicar el estado
    bsf	    PORTB, 1
    movf    nv2, w	    ;Movemos nuevo valor 2 a w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece4	    ;Movemos el valor a dece4
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni4	    ;Movemos el valor a uni4
    goto    loop	    ;Ir a loop
    
estado_3:
    bcf	    PORTB, 1	    ;Encender y apagar LED para indicar estado
    bsf	    PORTB, 2
    movf    nv3, w	    ;Movemos el nuevo valor 3 a w
    movwf   div		    ;Movemos el valor a la variable div
    call    div_10	    ;Llamamos la division por 10
    movf    dece, w	    ;Movemos la decena a w
    movwf   dece4	    ;Movemos el valor a dece4
    call    div_1	    ;Llamamos la division por 1
    movf    uni, w	    ;Movemos la unidad a w
    movwf   uni4	    ;Movemos el valor a uni4
    goto    loop	    ;Ir al loop
    
estado_4:
    bsf	    PORTB, 0	    ;Encendemos LEDs para indicar el estado
    bsf	    PORTB, 1 
    bsf	    vard, 3	    ;No utilizar el 7 segmentos
    movlw   0
    movwf   display_var+6
    movlw   0
    movwf   display_var+7 
    goto    loop	    ;Ir al loop


;-----------------sub rutinas------------------------------
pp_display:
    movf    dece1, w	    ;La variable decena la movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var	    ;Lo movemos a la variable de display nibble 0
    
    movf    uni1, w	    ;La variable unidad la movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+1   ;Lo movemos a la variable de display nibble 1
    
    movf    dece2, w	    ;La variable decena la movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+2   ;Lo movemos a la variable de display nibble 2
    
    movf    uni2, w	    ;La variable unidad lo movemos a w 
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+3   ;Lo movemos a la variable de display nibble 3
    
    movf    dece3, w	    ;La variable decena la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+4   ;Lo movemos a la variable de display nibble 4
    
    movf    uni3, w	    ;La variable unidad la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+5   ;Lo movemos a la variable de display nibble 5
    
    movf    dece4, w	    ;La variable decena la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+6   ;Lo movemos a la variable de display nibble 6
    
    movf    uni4, w	    ;La variable unidad la movemos a w
    call    Tabla	    ;Llamamos a la tabla para tenerlo en hexadecimal
    movwf   display_var+7   ;Lo movemos a la variable de display nibble 7
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
    bsf	    RBIE    ;Activamos las interrupciones de los botones
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
    bsf	    PS0		    ;Valor en 256
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
    btfsc   vt, 0   ;Saltar instruccion
    call    ve1	    ;Verde tintilante 1
    btfsc   vt, 1   ;Saltar instruccion
    call    ve2	    ;Verde tintilante 2
    btfsc   vt, 2   ;Saltar instruccion
    call    ve3	    ;Verde tintilante 3
    return
ve1:    
    bcf     of, 0	;Limpiamos la bandera para no entrar en off y on
    btfsc   PORTA, 2	;Saltar instruccion
    call    off1	;Subrutina apagado
    btfsc   of, 0	;Saltar instruccion
    return		;Regresar
    call    on1		;Subrutina encendido
    return
on1:
    bsf	    PORTA, 2		;Encender el bit
    bcf	    vard, 0		;Apagar el display
    call    delay_big		;Llamar a un delay
    return		
off1:
    bcf	    PORTA, 2		;Apagar el bit
    bsf	    vard, 0		;Encender el display
    bsf	    of, 0		;Encender la bandera para evitar on y off
    call    delay_big		;Llamar a un delay
    return
    
ve2:
    bcf	    of, 1		;Limpiamos la bandera
    btfsc   PORTA, 5		;Saltar instruccion
    call    off2		;Subrutina apagado
    btfsc   of, 1		;Saltar instruccion
    return			;Regresar
    call    on2			;Subrutina encendido
    return			;Regresar
on2:
    bsf	    PORTA, 5		;Encender el bit
    bcf	    vard, 1		;Apagar el display
    call    delay_big		;Llamar a un delay
    return			;Regresar
off2:
    bcf	    PORTA, 5		;Apagar el bit
    bsf	    vard, 1		;Encender el display
    bsf	    of, 1		;Encender la bandera para evitar on y off
    call    delay_big		;LLamara un delay
    return			;Regresar
ve3:
    bcf	    of, 2		;Apagar la bandera para evitar on y off
    btfsc   PORTB, 3		;Saltar instruccion
    call    off3		;Subrutina apagado
    btfsc   of, 2		;Saltar instruccion
    return			;Regresar
    call    on3			;Subrutina encendido
    return			;Regresar
on3:
    bsf	    PORTB, 3		;Encender el bit
    bcf	    vard, 2		;Apagar el display
    call    delay_big		;LLamar a un delay
    return			;Regresar
off3:
    bcf	    PORTB, 3		;Apagar el bit
    bsf	    vard, 2		;Encender el display
    bsf	    of, 2		;Encender la bandera para evitar on y off
    call    delay_big		;Llamara un delay
    return			;Regresar
    
delay_big:
    movlw   200		    ;valor inicial del contador
    movwf   cont_big	
    call    delay_small	    ;rutina de delay
    decfsz  cont_big, 1	    ;decrementar el contador
    goto    $-2		    ;ejecutar dos lineas atrás
    return
    
delay_small:
    movlw   246		    ;valor inicial del contador
    movwf   cont_small	
    decfsz  cont_small,	1   ;decrementar el contador
    goto    $-1		    ;ejecutar la linea anterior
    return   
comp1:
    btfss   YN, 0	    ;Saltar instruccion si ocurre reset
    call    compr1	    ;Comprobacion semaforo1
    return
compr1:
    bcf	    YN, 3	    ;Limpiar bandera de reset
    movf    sem1, w	    ;Comprobar que falten 5 segundos
    sublw   5
    btfsc   CARRY
    goto    verdet1	    ;Subrutina verde tintilante
    bcf	    ama, 2	    ;Limpiar banderas y puertos
    bcf	    vt,0
    bcf	    vt,1
    bcf	    vt,2
    bcf	    vard, 1
    bcf	    vard, 0
    bcf	    vard, 2
    bcf	    PORTA, 0
    bcf	    PORTA, 5
    bcf	    PORTB, 3
    bsf	    PORTA, 2	    ;Encender LEDS
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    return
verdet1:
    bsf	    vt,0	    ;Encender bandera de verde tintilante
    movf    sem1, w	    ;Comprobar que falten 2 segundos
    sublw   2
    btfsc   CARRY
    call    am1		    ;Subrituna de amarillo
    return
am1:
    bsf	    ama,0	    ;Encender y limpiar banderas
    bcf	    ama,2
    bcf	    vt,0
    bcf	    vard, 0
    return 
comp2:
    btfss   YN, 0	    ;Saltar instruccion  
    call    compr2	    ;Comprobacion semaforo2
    return
compr2:
    movf    sem2, w	    ;Comprobar que falten 5 segundos
    sublw   5
    btfsc   CARRY
    goto    verdet2	    ;Subrutina verde tintilante
    bcf	    ama, 0	    ;Limpiar banderas y puertos
    bcf     PORTA, 3
    bcf	    PORTA, 2
    bsf	    PORTA, 0	    ;Encender LEDS
    bsf	    PORTA, 5
    bsf	    PORTA, 6
    return
    
verdet2:
    bsf	    vt,1	;Encender bandera de verde tintilante
    movf    sem2, w	;Comprobar que falten 2 segundos
    sublw   2		
    btfsc   CARRY
    call    am2		;Subrutina de amarillo
    return

am2:
    bcf	    ama, 0	;Limpiar y encender banderas
    bsf	    ama, 1
    bcf	    vt, 1
    bcf	    vard, 1
    return
    
comp3:
    btfss   YN, 0	;Saltar instruccion
    call    compr3	;Comprobacion semaforo3
    return   
compr3:
    movf    sem3, w	;Comprobar que falten 5 segundos
    sublw   5
    btfsc   CARRY
    goto    verdet3	;Subrutina verdetintilante
    btfsc   of, 4	;Bandera para el reset
    return
    bcf	    ama, 1	;Limpiar banderas y puertos
    bcf	    PORTA, 5
    bcf	    PORTA, 6
    bsf	    PORTA, 0	;Encender LEDs
    bsf	    PORTA, 3
    bsf	    PORTB, 3
    return
        
verdet3:
    bsf	    vt,2	;Encender bandera de verdetintilante
    movf    sem3, w	;Comprobar que falten 2 segundos
    sublw   2
    btfsc   CARRY
    call    am3		;Subrutina de amarillo
    return

am3:
    bcf	    ama,1	;Limpiar y encender banderas
    bsf	    ama,2
    bcf	    vt,2
    bcf	    vard, 2
    movf    sem3, w	;Comprobar que se termino el tiempo para el reset
    sublw   255
    btfsc   ZERO
    call    rst
    return
rst:
    bsf	    of, 4	;Encender bandera de reset y limpiar banderas y puertos
    bcf	    ama,0
    bcf	    ama,1
    bcf	    ama,2
    bcf	    PORTA, 1
    bcf	    PORTA, 2
    bcf	    PORTA, 4
    bcf	    PORTA, 5
    bcf	    PORTA, 7
    bcf	    PORTB, 3
    movf    v1, w	;Mover valores iniciales
    movwf   sem1
    movf    v2, w
    movwf   sem2
    movf    v3, w
    movwf   sem3
    bsf	    D1, 0	;Volver a iniciar en el semaforo1
    bcf	    D1, 1
    bcf	    D1, 2
    btfsc   D1, 3
    bcf	    D1, 3
    return
Yes:
    movf    nv1, w	;Mover nuevos valores a los valores iniciales	    
    movwf   v1
    movf    nv2, w
    movwf   v2
    movwf   nv3, w
    movwf   v3
    call    rst		;Llamar al reset
    return
    
No:
    movlw   0x0F	;Regresar los valores iniciales de los nuevos valores
    movwf   nv1
    movlw   0x0F
    movwf   nv2
    movlw   0x0F
    movwf   nv3
    bcf	    YN, 1	    ;Apagar bandera
    return
LEDR:
    bcf	    PORTA, 1	    ;Resetear los LEDs y valores
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
    bcf	    ama, 2	    ;Resetear banderas de amarillo, verdet, y displays
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