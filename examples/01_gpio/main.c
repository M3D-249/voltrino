/*
**  gpio use example
**  
**  what the program does:
**  1. Configure PB5(D13 on Arduino -> builtin led) as an output.
**  2. Configure PD2(D2), PD3(D3), PD4(D4) as inputs with their internal pull-up enabled.
**  4. When the PD2 button is pressed, turn the LED on.
**  5. When the PD3 button is pressed, turn the LED off.
**  5. When the PD4 button is pressed, toggle the state of the LED.
**  6. If neither button is pressed, preserve the LED's previous state.
**
**  NOTE: button debounce not implemented
*/


#define F_CPU 16000000UL

#include <avr/io.h>

#include "arduino_pins.h"
#include "gpio.h"
#include "definitions.h"

uint8_t LED_STATE = 0;

int main(void)
{
    GPIO_pin led_pin = { &DDRB, &PORTB, &PINB, D13 };

    GPIO_pin btn_pin1 = { &DDRD, &PORTD, &PIND, D2 };

    GPIO_pin btn_pin2 = { &DDRD, &PORTD, &PIND, D3 };

    GPIO_pin btn_pin3 = { &DDRD, &PORTD, &PIND, D4 };

    // Configure PB5 as an output
    gpio_init(&led_pin, GPIO_OUTPUT);

    // configure PD2 as input with pull-up
    gpio_init(&btn_pin1, GPIO_INPUT_PULLUP);

    // configure PD3 as input with pull-up
    gpio_init(&btn_pin2, GPIO_INPUT_PULLUP);

    // configure PD3 as input with pull-up
    gpio_init(&btn_pin3, GPIO_INPUT_PULLUP);

    while (1)
    {
        if (gpio_digital_read(&btn_pin1) == LOW) // button PD2 pressed
        {
            gpio_digital_write(&led_pin, HIGH);
            LED_STATE = 1;
        }

        if (gpio_digital_read(&btn_pin2) == LOW) // button PD3 pressed
        {
            gpio_digital_write(&led_pin, LOW); 
            LED_STATE = 0;
        }

        if (gpio_digital_read(&btn_pin3) == LOW) // button PD3 pressed
        {
            if (LED_STATE == 1)
            {
                gpio_digital_write(&led_pin, LOW);
                LED_STATE = 0;
            } 
            else
            {
                gpio_digital_write(&led_pin, HIGH);
                LED_STATE = 1;
            }
        }
    }

    return 0;
}
