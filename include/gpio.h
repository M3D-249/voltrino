#ifndef _GPIO_H_
#define _GPIO_H_


#include <inttypes.h>

typedef struct
{
    volatile uint8_t* reg;
    volatile uint8_t* port;
    volatile uint8_t* input;
    uint8_t bit;

} GPIO_pin;

typedef enum 
{
    GPIO_INPUT,
    GPIO_INPUT_PULLUP,
    GPIO_OUTPUT

} GPIO_Mode;

void gpio_init(GPIO_pin* pin, GPIO_Mode mode);

uint8_t gpio_digital_read(GPIO_pin* pin);
void gpio_digital_write(GPIO_pin* pin, uint8_t state);

#endif
