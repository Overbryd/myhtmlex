#ifndef MYHTMLEX_H
#define MYHTMLEX_H

#include <stdlib.h>
#include <ctype.h>
#include <string.h>
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
build_tree(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node, unsigned char* flags);
ERL_NIF_TERM
build_node_children(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node, unsigned char* flags);
void
nif_cleanup_myhtml_tree(ErlNifEnv* env, void* obj);
unsigned char
read_parse_flags(ErlNifEnv* env, const ERL_NIF_TERM* options);

// consts
ERL_NIF_TERM ATOM_NIL;
ERL_NIF_TERM ATOM_COMMENT;
ERL_NIF_TERM ATOM_HTML_ATOMS;
ERL_NIF_TERM ATOM_NIL_SELF_CLOSING;
ERL_NIF_TERM ATOM_COMMENT_TUPLE3;
ERL_NIF_TERM EMPTY_LIST;
const unsigned char FLAG_HTML_ATOMS       = 1 << 0;
const unsigned char FLAG_NIL_SELF_CLOSING = 1 << 1;
const unsigned char FLAG_COMMENT_TUPLE3   = 1 << 2;

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
