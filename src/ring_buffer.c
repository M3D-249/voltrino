#include "ring_buffer.h"

void ring_buffer_init(RingBuffer *rb)
{
    rb->head = 0;
    rb->tail = 0;
}

uint8_t ring_buffer_is_empty(RingBuffer *rb)
{
    return rb->head == rb->tail;
}


uint8_t ring_buffer_push(RingBuffer *rb, uint8_t value)
{
    uint8_t next = (rb->head + 1) % RING_BUFFER_SIZE;

    if (next == rb->tail) {
        return 0; // Buffer full
    }

    rb->data[rb->head] = value;

    rb->head = next;

    return 1;
}

uint8_t ring_buffer_pop(RingBuffer *rb, uint8_t *value)
{
    if (ring_buffer_is_empty(rb)) {
        return 0;  // Buffer empty
    }

    *value = rb->data[rb->tail];

    rb->tail = (rb->tail + 1) % RING_BUFFER_SIZE;

    return 1;      // Success
}

// return the number of elements
uint8_t ring_buffer_size(RingBuffer* rb)
{
    return (rb->head - rb->tail + RING_BUFFER_SIZE) % RING_BUFFER_SIZE;
}

// returns 1 if true and 0 otherwise
uint8_t ring_buffer_is_full(RingBuffer* rb)
{
    return (rb->head + 1) % RING_BUFFER_SIZE == rb->tail;
}

// empties the buffer
void ring_buffer_clear(RingBuffer* rb)
{
    ring_buffer_init(rb);
}