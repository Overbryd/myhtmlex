#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

#include "erl_interface.h"
#include "ei.h"

#include <myhtml/myhtml.h>
#include <myhtml/mynamespace.h>

#define BUFFER_SIZE 1000

typedef struct _state_t {
  int fd;
  myhtml_tree_t*  tree;
} state_t;

typedef struct _prefab_t {
  ETERM* atom_nil;
  ETERM* atom_comment;
  ETERM* empty_list;
} prefab_t;

void
handle_emsg(state_t* state, ErlMessage* emsg);
void
handle_send(state_t* state, ErlMessage* emsg);
ETERM*
decode(state_t* state, ErlMessage* emsg, ETERM* bin, ETERM* args);
ETERM*
build_tree(prefab_t* prefab, myhtml_tree_t* tree, myhtml_tree_node_t* node, unsigned char* parse_flags);
ETERM*
build_node_children(prefab_t* prefab, myhtml_tree_t* tree, myhtml_tree_node_t* parent, unsigned char* parse_flags);
ETERM*
build_node_attrs(prefab_t* prefab, myhtml_tree_t* tree, myhtml_tree_node_t* node);
ETERM*
err_term(const char* error_atom);

const unsigned char FLAG_HTML_ATOMS       = 1 << 0;
const unsigned char FLAG_NIL_SELF_CLOSING = 1 << 1;
const unsigned char FLAG_COMMENT_TUPLE3   = 1 << 2;

int main(int argc, char **argv) {
  if (argc != 5 || !strcmp(argv[1],"-h") || !strcmp(argv[1],"--help")) {
    printf("\nUsage: ./priv/cnode_server <sname> <hostname> <cookie> <tname>\n\n");
    printf("    sname      the short name you want this c-node to connect as\n");
    printf("    hostname   the hostname\n");
    printf("    cookie     the authentication cookie\n");
    printf("    tname      the target node short name to connect to");
    return 0;
  }

  char *sname = argv[1];
  char *hostname = argv[2];
  char *cookie = argv[3];
  char *tname = argv[4];
  char full_name[1024];
  stpcpy(stpcpy(stpcpy(full_name, sname), "@"), hostname);
  char target_node[1024];
  stpcpy(stpcpy(stpcpy(target_node, tname), "@"), hostname);

  struct in_addr addr;
  addr.s_addr = htonl(INADDR_ANY);

  // fd to erlang node
  state_t* state = (state_t*)malloc(sizeof(state_t));
  bool looping = true;
  int buffer_size = BUFFER_SIZE;
  unsigned char* bufferpp = (unsigned char*)malloc(BUFFER_SIZE);
  ErlMessage emsg;

  // initialize all of Erl_Interface
  erl_init(NULL, 0);

  // initialize this node
  printf("initialising %s\n", full_name); fflush(stdout);
  if ( erl_connect_xinit(hostname, sname, full_name, &addr, cookie, 0) == -1 )
    erl_err_quit("error erl_connect_init");

  // connect to target node
  printf("connecting to %s\n", target_node); fflush(stdout);
  if ((state->fd = erl_connect(target_node)) < 0)
    erl_err_quit("erl_connect");

  myhtml_t* myhtml = myhtml_create();
  myhtml_init(myhtml, MyHTML_OPTIONS_DEFAULT, 1, 0);
  state->tree = myhtml_tree_create();
  myhtml_tree_init(state->tree, myhtml);

  // signal to stdout that we are ready
  printf("%s ready\n", full_name); fflush(stdout);

  while (looping)
  {
    // erl_xreceive_msg adapts the buffer width
    switch( erl_xreceive_msg(state->fd, &bufferpp, &buffer_size, &emsg) )
    // erl_receive_msg, uses a fixed buffer width
    /* switch( erl_receive_msg(state->fd, buffer, BUFFER_SIZE, &emsg) ) */
    {
      case ERL_TICK:
        // ignore
        break;
      case ERL_ERROR:
        // On failure, the function returns ERL_ERROR and sets erl_errno to one of:
        //
        // EMSGSIZE
        // Buffer is too small.
        // ENOMEM
        // No more memory is available.
        // EIO
        // I/O error.
        //
        // TODO: what is the correct reaction?
        looping = false;
        break;
      default:
        handle_emsg(state, &emsg);
    }
  }

}

void
handle_emsg(state_t* state, ErlMessage* emsg)
{
  switch(emsg->type)
  {
    case ERL_REG_SEND:
    case ERL_SEND:
      handle_send(state, emsg);
      break;
    case ERL_LINK:
    case ERL_UNLINK:
      break;
    case ERL_EXIT:
      break;
  }
  // its our responsibility to free these pointers
  erl_free_compound(emsg->msg);
  erl_free_compound(emsg->to);
  erl_free_compound(emsg->from);
}

void
handle_send(state_t* state, ErlMessage* emsg)
{
  ETERM *decode_pattern = erl_format("{decode, Bin, Args}");
  ETERM *response;

  if (erl_match(decode_pattern, emsg->msg))
  {
    ETERM *bin = erl_var_content(decode_pattern, "Bin");
    ETERM *args = erl_var_content(decode_pattern, "Args");

    response = decode(state, emsg, bin, args);

    // free allocated resources
    erl_free_term(bin);
    erl_free_term(args);
  }
  else
  {
    response = err_term("unknown_call");
    return;
  }

  // send response
  erl_send(state->fd, emsg->from, response);

  // free allocated resources
  erl_free_compound(response);
  erl_free_term(decode_pattern);

  // free the free-list
  erl_eterm_release();

  return;
}

ETERM*
err_term(const char* error_atom)
{
  /* ETERM* tuple2[] = {erl_mk_atom("error"), erl_mk_atom(error_atom)}; */
  /* return erl_mk_tuple(tuple2, 2); */
  return erl_format("{error, ~w}", erl_mk_atom(error_atom));
}

ETERM*
decode(state_t* state, ErlMessage* emsg, ETERM* bin, ETERM* args)
{
  unsigned char parse_flags = 0;
  prefab_t prefab;

  // prepare reusable prefab terms
  prefab.atom_nil = erl_mk_atom("nil");
  prefab.atom_comment = erl_mk_atom("comment");
  prefab.empty_list = erl_mk_empty_list();

  if (!ERL_IS_BINARY(bin) || !ERL_IS_LIST(args))
  {
    return err_term("badarg");
  }

  // get contents of binary argument
  char* binary = (char*)ERL_BIN_PTR(bin);
  size_t binary_len = ERL_BIN_SIZE(bin);

  // parse tree
  mystatus_t status = myhtml_parse(state->tree, MyENCODING_UTF_8, binary, binary_len);
  if (status != MyHTML_STATUS_OK)
  {
    return err_term("myhtml_parse_failed");
  }

  // build tree
  myhtml_tree_node_t *root = myhtml_tree_get_document(state->tree);
  return build_tree(&prefab, state->tree, myhtml_node_last_child(root), &parse_flags);
}

ETERM*
build_tree(prefab_t* prefab, myhtml_tree_t* tree, myhtml_tree_node_t* node, unsigned char* parse_flags)
{
  ETERM* result;
  myhtml_tag_id_t tag_id = myhtml_node_tag_id(node);
  /* myhtml_namespace_t tag_ns = myhtml_node_namespace(node); */

  if (tag_id == MyHTML_TAG__TEXT)
  {
    size_t text_len;
    const char* node_text = myhtml_node_text(node, &text_len);
    result = erl_mk_binary(node_text, text_len);
  }
  else if (tag_id == MyHTML_TAG__COMMENT)
  {
    size_t comment_len;
    const char* node_comment = myhtml_node_text(node, &comment_len);
    ETERM* comment = erl_mk_binary(node_comment, comment_len);

    if (*parse_flags & FLAG_COMMENT_TUPLE3)
    {
      /* ETERM* tuple3[] = {prefab->atom_comment, prefab->empty_list, comment}; */
      /* result = erl_mk_tuple(tuple3, 3); */
      result = erl_format("{comment, [], ~w}", comment);
    }
    else
    {
      /* ETERM* tuple2[] = {prefab->atom_comment, comment}; */
      /* result = erl_mk_tuple(tuple2, 2); */
      result = erl_format("{comment, ~w}", comment);
    }
  }
  else
  {
    ETERM* tag;
    ETERM* attrs;
    ETERM* children;

    // get name of tag
    size_t tag_name_len;
    const char *tag_name = myhtml_tag_name_by_id(tree, tag_id, &tag_name_len);
    // get namespace of tag
    /* size_t tag_ns_len; */
    /* const char *tag_ns_name_ptr = myhtml_namespace_name_by_id(tag_ns, &tag_ns_len); */
    /* char *tag_ns_buffer; */
    /* char buffer [tag_ns_len + tag_name_len + 1]; */
    /* char *tag_string = buffer; */
    /* size_t tag_string_len; */

    tag = erl_mk_binary(tag_name, tag_name_len);

    // attributes
    attrs = build_node_attrs(prefab, tree, node);

    // children
    children = build_node_children(prefab, tree, node, parse_flags);

    /* ETERM* tuple3[] = {tag, attrs, children}; */
    /* result = erl_mk_tuple(tuple3, 3); */
    result = erl_format("{~w, ~w, ~w}", tag, attrs, children);
  }

  return result;
}

ETERM*
build_node_children(prefab_t* prefab, myhtml_tree_t* tree, myhtml_tree_node_t* parent, unsigned char* parse_flags)
{
  if (myhtml_node_is_close_self(parent) && (*parse_flags & FLAG_NIL_SELF_CLOSING))
  {
    /* prefab->atom_nil; */
    return erl_mk_atom("nil");
  }

  myhtml_tree_node_t* child = myhtml_node_last_child(parent);
  if (child == NULL)
  {
    if (myhtml_node_is_void_element(parent) && (*parse_flags & FLAG_NIL_SELF_CLOSING))
    {
      /* return prefab->atom_nil; */
      return erl_mk_atom("nil");
    }
    /* else */
    /* { */
    /*   return prefab->empty_list; */
    /* } */
  }

  ETERM* list = erl_mk_empty_list();

  while (child)
  {
    ETERM* node_tuple = build_tree(prefab, tree, child, parse_flags);
    list = erl_cons(node_tuple, list);

    // get previous child, building the list from reverse
    child = myhtml_node_prev(child);
  }

  return list;
}

ETERM*
build_node_attrs(prefab_t* prefab, myhtml_tree_t* tree, myhtml_tree_node_t* node)
{
  myhtml_tree_attr_t* attr = myhtml_node_attribute_last(node);

  /* if (attr == NULL) */
  /* { */
  /*   return prefab->empty_list; */
  /* } */

  ETERM* list = erl_mk_empty_list();

  while (attr)
  {
    ETERM* name;
    ETERM* value;
    ETERM* attr_tuple;

    size_t attr_name_len;
    const char *attr_name = myhtml_attribute_key(attr, &attr_name_len);
    size_t attr_value_len;
    const char *attr_value = myhtml_attribute_value(attr, &attr_value_len);

    if (attr_value) {
      value = erl_mk_binary(attr_value, attr_value_len);
    } else {
      value = erl_mk_binary(attr_name, attr_name_len);
    }
    name = erl_mk_binary(attr_name, attr_name_len);

    /* ETERM* tuple2[] = {name, value}; */
    /* attr_tuple = erl_mk_tuple(tuple2, 2); */
    attr_tuple = erl_format("{~w, ~w}", name, value);

    list = erl_cons(attr_tuple, list);

    // get prev attribute, building the list from reverse
    attr = myhtml_attribute_prev(attr);
  }

  return list;
}
