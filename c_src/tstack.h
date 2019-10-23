#ifndef TSTACK_H
#define TSTACK_H

#include "ei.h"
#define GROW_BY 30

typedef struct {
  ETERM* *data;
  size_t used;
  size_t size;
} tstack;

void tstack_init(tstack *stack, size_t initial_size) {
  stack->data = (ETERM **) malloc(initial_size * sizeof(ETERM*));
  stack->used = 0;
  stack->size = initial_size;
}

void tstack_free(tstack *stack) {
  free(stack->data);
}

void tstack_resize(tstack *stack, size_t new_size) {
  stack->data = (ETERM **)realloc(stack->data, new_size * sizeof(ETERM*));
  stack->size = new_size;
}

void tstack_push(tstack *stack, ETERM* element) {
  if(stack->used == stack->size) {
    tstack_resize(stack, stack->size + GROW_BY);
  }
 stack->data[stack->used++] = element;
}

ETERM* tstack_pop(tstack *stack) {
 return stack->data[--(stack->used)];
}

#endif
