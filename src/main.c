
#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>

#include "arduino_pins.h"
#include "gpio.h"
#include "definitions.h"

uint8_t test;

int main(void)
{
    GPIO_pin led_pin = { &DDRB, &PORTB, &PINB, D13 };

    GPIO_pin btn_pin1 = { &DDRD, &PORTD, &PIND, D2 };

    GPIO_pin btn_pin2 = { &DDRD, &PORTD, &PIND, D3 };

    // Configure PB5 as an output
    gpio_init(&led_pin, GPIO_OUTPUT);

    // configure PD2 as input with pull-up
    gpio_init(&btn_pin1, GPIO_INPUT_PULLUP);

    // configure PD3 as input with pull-up
    gpio_init(&btn_pin2, GPIO_INPUT_PULLUP);

    while (1)
    {
        // // Turn the LED ON
        // gpio_digital_write(&led_pin, HIGH);
        // _delay_ms(200);
        // // Turn the LED OFF
        // gpio_digital_write(&led_pin, LOW);
        // _delay_ms(500);
    
        if (gpio_digital_read(&btn_pin1) == LOW) // button PD2 pressed
            gpio_digital_write(&led_pin, HIGH);

        if (gpio_digital_read(&btn_pin2) == LOW) // button PD3 pressed
            gpio_digital_write(&led_pin, LOW);

    }

    return 0;
}
