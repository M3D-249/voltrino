#ifndef _RING_BUFFER_H
#define _RING_BUFFER_H

#include <stdint.h>

#define RING_BUFFER_SIZE 64

typedef struct {
    uint8_t data[RING_BUFFER_SIZE];

    uint8_t head;
    uint8_t tail;
} RingBuffer;

void ring_buffer_init(RingBuffer *rb);

// returns 1 on success 0 otherwise
uint8_t ring_buffer_push(RingBuffer *rb, uint8_t value);

// returns 1 on success 0 otherwise
uint8_t ring_buffer_pop(RingBuffer *rb, uint8_t *value);

// returns 1 if true and 0 otherwise
uint8_t ring_buffer_is_empty(RingBuffer *rb);

// return the number of elements
uint8_t ring_buffer_size(RingBuffer* rb);

// returns 1 if true and 0 otherwise
uint8_t ring_buffer_is_full(RingBuffer* rb);

// empties the buffer
void ring_buffer_clear(RingBuffer* rb);

#endif