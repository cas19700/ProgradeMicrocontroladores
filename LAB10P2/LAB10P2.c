/*
 *Archivo:          LAB10P2.c
 *Dispositivo:	    PIC16F887
 *Autor:            Brayan Castillo
 *Compilador:	    XC8
 *Programa:         EUSART
 *Hardware:         LEDS y Terminal Virtual
 *Creado:           4 de mayo del 2021
 *Ultima modificacion:	9 de mayo del 2021
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
#pragma config PWRTE = OFF           // Power-up Timer Enable bit (PWRT enabled)
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

#define _XTAL_FREQ 4000000  //Frecuencia


//******************************************************************************
//Variables
//******************************************************************************
//const char dato = 64;
char dato[] = "Hola \r que tal \r 0";
int band = 1;
//******************************************************************************
//Prototipos de Funciones
//******************************************************************************
void letras(char letra[]);
void ubicacion(char ubic);
void setup(void);
void __interrupt() isr(void)
    {    
	if(PIR1bits.RCIF == 1){
        
        PORTB = RCREG;    
        
    }
    return;
}
    
//******************************************************************************
//Ciclo Principal
//******************************************************************************
    
void main(void){
    setup();                //Llamar las configutaciones
                    //Siempre realizar el ciclo
        
        __delay_ms(500); 
        letras(dato);
        
        //if (PIR1bits.TXIF){
        //    TXREG = dato;
        //}
        while(1){
       }
    }

//******************************************************************************
//Configuracion
//******************************************************************************

    void setup(void){
    //  Configuracion de puertos
    ANSEL = 0b00000000;
    ANSELH = 0b00000000;
    //  Declaramos puertos como entradas o salidas
    TRISA = 0x00;
    TRISC = 0xFF;
    TRISD = 0x00;
    TRISB = 0x00;
    TRISE = 0x00;
    //Limpiamos valores en los puertos
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
    //Configuracion del oscilador en 4Mhz
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS = 1;
    //Configuracion de TX y RX
    TXSTAbits.SYNC = 0;
    TXSTAbits.BRGH = 1;
    BAUDCTLbits.BRG16 = 0;
    SPBRG = 25;
    SPBRGH = 0;
    RCSTAbits.SPEN = 1;
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;
    TXSTAbits.TXEN = 1;
    //Configuracion de interrupciones
    PIR1bits.RCIF = 0;
    PIE1bits.RCIE = 1;
    INTCONbits.PEIE = 1;
    INTCONbits.GIE = 1;
    return;
    }
//******************************************************************************
//Funciones
//******************************************************************************   
   void letras(char letra[]){
        int i = 0;
        while (letra[i] != '0'){
        ubicacion(letra[i]);
        i++;
        
     }
        return;
    }
   void ubicacion(char ubic){
       while(TXIF == 0);
       TXREG = ubic;
       return;
   }
