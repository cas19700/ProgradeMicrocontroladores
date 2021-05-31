/*
 *Archivo:          Proyecto2.c
 *Dispositivo:	    PIC16F887
 *Autor:            Brayan Castillo
 *Compilador:	    XC8
 *Programa:         Animatronic Face
 *Hardware:         Servos, motor DC, push button y LEDS
 *Creado:           16 de mayo del 2021
 *Ultima modificacion:	4 de junio del 2021
*/
//******************************************************************************
//Importaciòn de librerias
//****************************************************************************** 

#include <xc.h>
#include <stdint.h>

//******************************************************************************
//Palabras de configuracion
//****************************************************************************** 
    
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO 
                                    // oscillator: I/O function on 
                                    // RA6/OSC2/CLKOUT pin, I/O function 
                                    // on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF           // Watchdog Timer Enable bit (WDT disabled)
#pragma config PWRTE = ON           // Power-up Timer Enable bit (PWRT enabled)
#pragma config MCLRE = OFF          // RE3/MCLR pin function select bit 
                                    // (RE3/MCLR pin function is MCLR)
#pragma config CP = OFF             // Code Protection bit (Program memory code 
                                    // protection is disabled)
#pragma config CPD = OFF            // Data Code Protection bit (Data memory 
                                    // code protection is disabled)
#pragma config BOREN = OFF          // Brown Out Reset Selection bits 
                                    // (BOR disabled)
#pragma config IESO = OFF           // Internal External Switchover bit 
                                    // (Internal/External Switchover mode 
                                    // is disabled)
#pragma config FCMEN = OFF          // Fail-Safe Clock Monitor Enabled bit 
                                    // (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON             // Low Voltage Programming Enable bit 
                                    // (RB3/PGM pin has PGM function, low 
                                    // voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V       // Brown-out Reset Selection bit (Brown-out 
                                    // Reset set to 4.0V)
#pragma config WRT = OFF            // Flash Program Memory Self Write Enable 
                                    // bits (Write protection off)

//******************************************************************************
//Directivas del compilador
//******************************************************************************
#define _tmr0_value 100 //Prescaler debe estar en 256 para 20 ms 
#define _tmr1_value num //Prescaler debe estar en 8 para 2 ms 
#define _XTAL_FREQ 8000000  //Frecuencia

//******************************************************************************
//Variables
//******************************************************************************
uint16_t    num = 65036;     //Variable para el numero 65286
uint16_t    num1 = 0;     //Variable para el numero
uint16_t    num2 = 0;     //Variable para el numero
uint16_t    num3 = 0;     //Variable para el numero
uint8_t    band = 0;    //Variable banderas para el display
uint8_t    band1 = 0;    //Variable banderas para el display
uint8_t    cent = 0;    //Variable centenas
uint8_t    dece = 0;    //Variable decenas
uint8_t    uni = 0;     //Variable unidades
int Display[10] = {0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x67};
                        //Array para la tabla

//******************************************************************************
//Prototipos de Funciones
//******************************************************************************

void setup(void);
void rst_tmr0(void);
void rst_tmr1(void);
void __interrupt() isr(void)
    { 
    if(T0IF == 1){              //Interupcion del timer0
        if(band1 == 0){
        rst_tmr0();
        PORTDbits.RD3 = 1;
        band1 = 1;}
        else{
        rst_tmr0();
        PORTDbits.RD3 = 0;
        band1 = 0;
        }
        INTCONbits.T0IF = 0;
    }
	if(TMR1IF == 1){              //Interrupcion del Puerto B
        if(band == 0){
        rst_tmr1();
        PORTDbits.RD2 = 1;
        band = 1;}
        else{
        rst_tmr1();
        PORTDbits.RD2 = 0;
        band = 0;
        }
        PIR1bits.TMR1IF = 0;
        
        }
    if(PIR1bits.ADIF == 1){
        if(ADCON0bits.CHS == 0){
        CCPR1L = ADRESH;         //Valor entre 128 y 250
        CCP1CONbits.DC1B1 = ADRESH;  //bits menos significativos
        CCP1CONbits.DC1B0 = ADRESL>>7;
        }
        else if(ADCON0bits.CHS == 1){
        CCPR2L = (ADRESH>>1) + 128;         //Valor entre 128 y 250
        CCP2CONbits.DC2B1 = ADRESH & 0b01;  //bits menos significativos
        CCP2CONbits.DC2B0 = ADRESL>>7;
        }
        else if(ADCON0bits.CHS == 2){
        num = 254;         //Valor entre 128 y 250
        num = num<<8;
        num1 = ADRESL;
        num = num | num1;
        }
        else if(ADCON0bits.CHS == 3){
        num2 = ADRESH;         //Valor entre 128 y 250
        num2 = num2<<7;
        num3 = ADRESL;
        num2 = num2 | num3;
        }
        }
        PIR1bits.ADIF = 0;      //Limpiar la bandera de interrupciòn
        }
    


//******************************************************************************
//Ciclo Principal
//******************************************************************************
    
    void main(void){
        setup();                //Llamar las configutaciones
        __delay_us(50); 
         ADCON0bits.GO = 1;
        while(1){                //Siempre realizar el ciclo
        if(ADCON0bits.GO == 0){         //Si se apaga el GO entrar al if
            if(ADCON0bits.CHS == 0){    //Cambiar de canal
                ADCON0bits.CHS = 1;
            }
            else if(ADCON0bits.CHS == 1){                       //Cambiar de canal
            ADCON0bits.CHS = 2;
            }
            else if(ADCON0bits.CHS == 2){                       //Cambiar de canal
            ADCON0bits.CHS = 3;
            }
            else if(ADCON0bits.CHS == 3){                       //Cambiar de canal
            ADCON0bits.CHS = 0;
            }
            __delay_us(50);             //Delay del cambio de canal
            ADCON0bits.GO = 1;          //Volver a setear el GO
        }
          //  PORTA++;
        }//Llamar la funcion para separar unidades
        }
    
//******************************************************************************
//Configuracion
//******************************************************************************

    void setup(void){
    //  Configuracion de puertos
    ANSEL = 0b00001111;
    ANSELH = 0x00;
    //  Declaramos puertos como entradas o salidas
    TRISA = 0b00001111;
    TRISC = 0x00;
    TRISD = 0x00;
    TRISB = 0x03;
    //Limpiamos valores en los puertos
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    //Configuracion del oscilador
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS = 1;
    //Configuración del ADC
    ADCON1bits.ADFM = 0;        //Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;       //Voltajes de referencia en VDD y VSS
    ADCON1bits.VCFG1 = 0;
    ADCON0bits.ADCS = 0b10;     //Valor de la tabla dependiendo la frecuencia
    ADCON0bits.CHS = 0;         //Canal seleccionado
    __delay_us(50);
    ADCON0bits.ADON = 1;
     //Configuración del PWM
    TRISCbits.TRISC2 = 1;       //CCP1 como entrada para poder configurar
    TRISCbits.TRISC1 = 1;       //CCP2 como entrada para poder configurar
    PR2 = 250;                  //tmr2 en 2ms 
    CCP1CONbits.P1M = 0;        //Modo Single Output
    CCP1CONbits.CCP1M = 0b00001100; //Activamos el PWM
    CCP2CONbits.CCP2M = 0b00001100; //Activamos el PWM
    CCPR1L = 0x0f;
    CCPR2L = 0x0f;
    CCP1CONbits.DC1B = 0;
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;
    
    PIR1bits.TMR2IF = 0;
    T2CONbits.T2CKPS = 0b11;    //Prescaler en 1:16
    T2CONbits.TMR2ON = 1;       //Encender el timer2
    
    while(!PIR1bits.TMR2IF);    //Ciclo del tmr2
    PIR1bits.TMR2IF = 0;
    
    TRISCbits.TRISC2 = 0;       //CCP1 como salida
    TRISCbits.TRISC1 = 0;       //CCP2 como salida
    
    //Configuracion del Timer0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 0;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;
    rst_tmr0();
    //Configuracion del Timer1
    PIE1bits.TMR1IE = 1;
    T1CONbits.TMR1CS = 0;
    T1CONbits.T1CKPS1 = 1;
    T1CONbits.T1CKPS0 = 1;
    T1CONbits.T1OSCEN = 1;
    T1CONbits.T1SYNC = 1;
    T1CONbits.TMR1ON = 1;
    rst_tmr1();
    //Pullups
    OPTION_REGbits.nRBPU = 0;
    WPUBbits.WPUB0 = 1;
    WPUBbits.WPUB1 = 1;
    //Configuracion de interrupciones
    INTCONbits.T0IE = 1;
    INTCONbits.T0IF = 0;
    INTCONbits.RBIE = 1;
    INTCONbits.RBIF = 0;
    PIR1bits.TMR1IF = 0;
    //PUERTOB
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;
    INTCONbits.PEIE = 1;
    IOCBbits.IOCB0 = 1;
    IOCBbits.IOCB1 = 1;
    INTCONbits.GIE = 1;
    
    }
    void rst_tmr0(void){
    TMR0 = _tmr0_value;
    INTCONbits.T0IF = 0;
    }
    void rst_tmr1(void){
    TMR1 = num;
    PIR1bits.TMR1IF = 0;
    }
   