#include "gpio.h"
#include "definitions.h"

void gpio_init(GPIO_pin* pin, GPIO_Mode mode)
{
    switch (mode)
    {
    case GPIO_INPUT:
        *(pin->reg) &= ~(1 << pin->bit);
        *(pin->port) &= ~(1 << pin->bit);
        break;
    case GPIO_INPUT_PULLUP:
        *(pin->reg) &= ~(1 << pin->bit);
        *(pin->port) |= (1 << pin->bit);
        break;
    case GPIO_OUTPUT:
        *(pin->reg) |= (1 << pin->bit);
        break;
    default:
        break;
    }
}

uint8_t gpio_digital_read(GPIO_pin* pin)
{
    return *(pin->input) & (1 << pin->bit);
}

void gpio_digital_write(GPIO_pin* pin, uint8_t state)
{
    if (state)
        *(pin->port) |= (1 << pin->bit);
    else
        *(pin->port) &= ~(1 << pin->bit);
}
