#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/atomic.h>
#include <stdint.h>

volatile uint8_t button_event1 = 0;

/*
 * Interrupt Service Routine for external interrupt 0.
 * Triggered by a falling edge on PD2.
 */
ISR(INT0_vect)
{
    button_event1 = 1;
}

int main(void)
{
    // Configure PB5 as output.
    DDRB |= (1 << DDB5);

    // Start with LED OFF.
    PORTB &= ~(1 << PORTB5);

    // Configure PD2 as input.
    DDRD &= ~(1 << DDD2);

    // Enable internal pull-up.
    PORTD |= (1 << PORTD2);

    // Configure INT0 for falling-edge detection.
    EICRA &= ~((1 << ISC01) | (1 << ISC00));
    EICRA |= (1 << ISC01);

    // Clear any previously pending INT0 flag.
    EIFR = (1 << INTF0);

    // Enable INT0.
    EIMSK |= (1 << INT0);

    // Enable global interrupts.
    sei();

    while (1)
    {
        uint8_t event = 0;

        /*
         * Read and clear the event flag atomically.
         */
        ATOMIC_BLOCK(ATOMIC_RESTORESTATE)
        {
            event = button_event1;
            button_event1 = 0;
        }

        if (event)
        {
            // Toggle the LED -> ATMega238p only special feature
            PINB = (1 << PINB5);
        }
    }

    return 0;
}