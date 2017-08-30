#ifndef MYHTMLEX_H
#define MYHTMLEX_H

#include <stdlib.h>
#include <ctype.h>
#include "erl_nif.h"
#include <myhtml/myhtml.h>
#include <myhtml/mynamespace.h>

char*
lowercase(char* c);
// myhtmlex.c
ERL_NIF_TERM
make_atom(ErlNifEnv* env, const char* name);
ERL_NIF_TERM
nif_decode(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM
nif_decode_tree(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM
nif_open(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM
build_node_attrs(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node);
ERL_NIF_TERM
build_tree(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node);
ERL_NIF_TERM
build_node_children(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node);
void
nif_cleanup_myhtml_tree(ErlNifEnv* env, void* obj);

// consts
ERL_NIF_TERM ATOM_NIL;

typedef struct {
  myhtml_t*       myhtml;
  myhtml_tree_t*  tree;

  ErlNifResourceType* myhtml_tree_rt;
} myhtmlex_state_t;

typedef struct {
  myhtml_tree_t*      tree;
  myhtml_tree_node_t  *root;
} myhtmlex_ref_t;

#endif // included myhtmlex.h
