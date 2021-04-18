/*
 *Archivo:          LAB07.s
 *Dispositivo:	    PIC16F887
 *Autor:            Brayan Castillo
 *Compilador:	    XC8
 *Programa:         Contador
 *Hardware:         Displays y botones
 *Creado:           12 de abril del 2021
 *Ultima modificacion:	13 de abril del 2021
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
#define _tmr0_value 247 //Prescaler debe estar en 128 para 1 ms 

//******************************************************************************
//Variables
//******************************************************************************
uint8_t    num = 0;     //Variable para el numero
uint8_t    band = 0;    //Variable banderas para el display
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
void unidades(void);
void __interrupt() isr(void)
    { 
    if(T0IF == 1){              //Interupcion del timer0
        rst_tmr0();
        PORTD = 0x00;           //Limpiar el PORTD
        if(band==0){            //Si band esta encendida mostrar el display 1
           band = 1;
           PORTC = Display[cent];   //Mostrar las centenas
           PORTD = 0x01;
           
        }
        else if(band==1){       //Si band esta encendida mostrar el display 2
           band = 2;
           PORTC = Display[dece];   //Mostrar las decenas
           PORTD = 0x02; 
        }
        else if(band==2){       //Si band esta encendida mostrar el display 3
           band = 0;
           PORTC = Display[uni];    //Mostrar las unidades
           PORTD = 0x04; 
        }
    }
	if(RBIF == 1){              //Interrupcion del Puerto B
                        
            if(RB0 == 0){
                PORTA++;        //Incrementar el Puerto A
            }
            if(RB1 == 0){
                PORTA--;        //Decrementar el Puerto A
            }
        INTCONbits.RBIF = 0;    //Limpiar al bandera 
      }
    }
//******************************************************************************
//Ciclo Principal
//******************************************************************************
    
    void main(void){
        setup();                //Llamar las configutaciones
        while(1)                //Siempre realizar el ciclo
        {num = PORTA;           //La variable numero siempre igual al puerto A
        unidades();             //Llamar la funcion para separar unidades
        }
    }
//******************************************************************************
//Configuracion
//******************************************************************************

    void setup(void){
    //  Configuracion de puertos
    ANSEL = 0x00;
    ANSELH = 0x00;
    //  Declaramos puertos como entradas o salidas
    TRISA = 0x00;
    TRISC = 0x00;
    TRISD = 0xF8;
    TRISB = 0x03;
    //Limpiamos valores en los puertos
    PORTA = 0x0;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    //Configuracion del oscilador
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF2 = 0;
    OSCCONbits.SCS = 1;
    //Configuracion del Timer0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 0;
    rst_tmr0();
    //Pullups
    OPTION_REGbits.nRBPU = 0;
    WPUBbits.WPUB0 = 1;
    WPUBbits.WPUB1 = 1;
    //Configuracion de interrupciones
    INTCONbits.T0IE = 1;
    INTCONbits.T0IF = 0;
    INTCONbits.RBIE = 1;
    INTCONbits.RBIF = 0;
    //PUERTOB
    IOCBbits.IOCB0 = 1;
    IOCBbits.IOCB1 = 1;
    INTCONbits.GIE = 1;
    
    }
    void rst_tmr0(void){
    TMR0 = _tmr0_value;
    INTCONbits.T0IF = 0;
    }
   
//******************************************************************************
//Funciones
//******************************************************************************   
    void unidades(void){
        if(num >= 100){                     //Si numero es mayor a 100
            cent=num/100;                   //Centena igual a num dividido 100
            dece=(num/10)-(cent*10);        //num dividido 10 menos centena
            uni=num-(cent*100)-(dece*10);   //num menos decena y centena
        }
        else if(num <100 && num >= 10){     //Si nun menor a 100 y mayor a 10
            cent=0;                         //Centena igual a 0
            dece=(num/10);                  //Decena igual a num dividido 10
            uni=num-(dece*10);              //uni es igual a num menos decena
        }
        else if (num < 10){                 //Si num es menor a 10
            cent=0;                         //Centena igual a 0
            dece=0;                         //Decena igual a 0
            uni=num;                        //uni es igual a num
        }
    }
    
    
    
    
    

    
