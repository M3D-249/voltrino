#ifndef _ARDUINO_PINS_H_
#define _ARDUINO_PINS_H_

#include <avr/io.h>

// Arduino digital pins
#define D0 PD0  // RX (UART)
#define D1 PD1  // TX (UART)
#define D2 PD2  // INT0
#define D3 PD3  // INT1. PWM
#define D4 PD4  // T0. XCK
#define D5 PD5  // PWM. T1
#define D6 PD6  // PWM. AIN0
#define D7 PD7  // AIN1

#define D8 PB0   // ICP1, CLKO 
#define D9 PB1   // PWM, OC1A 
#define D10 PB2  // PWM, SS
#define D11 PB3  // PWM, MOSI
#define D12 PB4  // MISO
#define D13 PB5  // SCK, onboard LED


// Arduino analog pins
#define A0 PC0  
#define A1 PC1  
#define A2 PC2  
#define A3 PC3  
#define A4 PC4  
#define A5 PC6 
#define RESET PC7

// Voltage and Ground
#define V5 VCC // digital power supply
#define AV5 AVCC // analog power supply 

#endif // _ARDUINO_PINS_H_
