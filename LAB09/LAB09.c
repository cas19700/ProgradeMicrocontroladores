/*
 *Archivo:          LAB09.c
 *Dispositivo:	    PIC16F887
 *Autor:            Brayan Castillo
 *Compilador:	    XC8
 *Programa:         PWM
 *Hardware:         Potenciometros y servomotores
 *Creado:           27 de abril del 2021
 *Ultima modificacion:	29 de abril del 2021
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

#define _XTAL_FREQ 8000000  //Frecuencia


//******************************************************************************
//Variables
//******************************************************************************

//******************************************************************************
//Prototipos de Funciones
//******************************************************************************

void setup(void);
void __interrupt() isr(void)
    {    
	if(PIR1bits.ADIF == 1){
        if(ADCON0bits.CHS == 0){
        CCPR1L = (ADRESH>>1) + 128;         //Valor entre 128 y 250
        CCP1CONbits.DC1B1 = ADRESH & 0b01;  //bits menos significativos
        CCP1CONbits.DC1B0 = ADRESL>>7;
        }
        else{
        CCPR2L = (ADRESH>>1) + 128;         //Valor entre 128 y 250
        CCP2CONbits.DC2B1 = ADRESH & 0b01;  //bits menos significativos
        CCP2CONbits.DC2B0 = ADRESL>>7;
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
            else{                       //Cambiar de canal
            ADCON0bits.CHS = 0;
            }
            __delay_us(50);             //Delay del cambio de canal
            ADCON0bits.GO = 1;          //Volver a setear el GO
        }
        }
    }
//******************************************************************************
//Configuracion
//******************************************************************************

    void setup(void){
    //  Configuracion de puertos
    ANSEL = 0b00000011;
    ANSELH = 0b00000000;
    //  Declaramos puertos como entradas o salidas
    TRISA = 0x03;
    TRISC = 0x00;
    TRISD = 0x00;
    TRISB = 0x00;
    TRISE = 0x00;
    //Limpiamos valores en los puertos
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
    //Configuracion del oscilador en 8Mhz
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
    
    //Configuracion de interrupciones
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;
    INTCONbits.PEIE = 1;
    INTCONbits.GIE = 1;
    
    }
//******************************************************************************
//Funciones
//******************************************************************************   


