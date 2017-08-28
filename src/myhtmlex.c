#include "erl_nif.h"
#include <myhtml/api.h>

ERL_NIF_TERM
build_node_attrs(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node);
ERL_NIF_TERM
build_tree(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node);
ERL_NIF_TERM
build_node_children(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node);

ERL_NIF_TERM
decode(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  // TODO: move this to load?
  // myhtml basic init
  myhtml_t* myhtml = myhtml_create();
  myhtml_init(myhtml, MyHTML_OPTIONS_DEFAULT, 1, 0);

  // init myhtml tree
  myhtml_tree_t* tree = myhtml_tree_create();
  myhtml_tree_init(tree, myhtml);

  // placeholder for the html binary we want to read from erlang caller
  ErlNifBinary html_bin;
  // read binary into &html_bin from argv[0] (first argument)
  if (!enif_inspect_iolist_as_binary(env, argv[0], &html_bin))
  {
    // blame the user if html_bin is not a binary
    return enif_make_badarg(env);
  }

  // parse html into tree
  mystatus_t status = myhtml_parse(tree, MyENCODING_UTF_8, (char*) html_bin.data, (size_t) html_bin.size);
  // TODO: check if it returned MyHTML_STATUS_OK
  if (status != MyHTML_STATUS_OK)
  {
    printf("NOT OK");
    return enif_make_badarg(env);
  }

  myhtml_tree_node_t *root = myhtml_tree_get_document(tree);
  ERL_NIF_TERM result = build_tree(env, tree, myhtml_node_last_child(root));

  // garbage collect argument
  enif_release_binary(&html_bin);

  // TODO: move this to unload?
  // maybe clean these resource after use (reuse myhtml, tree, etc...)
  // myhtml_clean(myhtml);
  // mythml_tree_clean(tree);

  // release myhtml resources
  myhtml_node_free(root);
  myhtml_tree_destroy(tree);
  myhtml_destroy(myhtml);

  // return tree to erlang
  return result;
}

ERL_NIF_TERM
build_node_children(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* parent)
{
  ERL_NIF_TERM list;

  list = enif_make_list(env, 0);

  myhtml_tree_node_t* child = myhtml_node_last_child(parent);
  while (child)
  {
    ERL_NIF_TERM node_tuple = build_tree(env, tree, child);
    list = enif_make_list_cell(env, node_tuple, list);

    // free allocated resources
    myhtml_node_free(child);
    // get previous child, building the list from reverse
    child = myhtml_node_prev(child);
  }

  return list;
}

ERL_NIF_TERM
build_node_attrs(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node)
{
  ERL_NIF_TERM list;
  myhtml_tree_attr_t* attr;

  list = enif_make_list(env, 0);
  attr = myhtml_node_attribute_last(node);

  while (attr)
  {
    ErlNifBinary name;
    ERL_NIF_TERM name_bin;
    ErlNifBinary value;
    ERL_NIF_TERM value_bin;
    ERL_NIF_TERM attr_tuple;

    size_t attr_name_len;
    const char *attr_name = myhtml_attribute_key(attr, &attr_name_len);
    size_t attr_value_len;
    const char *attr_value = myhtml_attribute_value(attr, &attr_value_len);

    if (attr_value) {
      enif_alloc_binary(attr_value_len, &value);
      memcpy(value.data, attr_value, attr_value_len);
      value_bin = enif_make_binary(env, &value);
    } else {
      enif_alloc_binary(attr_name_len, &value);
      memcpy(value.data, attr_name, attr_name_len);
      value_bin = enif_make_binary(env, &value);
    }
    enif_alloc_binary(attr_name_len, &name);
    memcpy(name.data, attr_name, attr_name_len);
    name_bin = enif_make_binary(env, &name);

    attr_tuple = enif_make_tuple2(env, name_bin, value_bin);
    list = enif_make_list_cell(env, attr_tuple, list);

    // free allocated resources
    myhtml_attribute_free(tree, attr);
    // get prev attribute, building the list from reverse
    attr = myhtml_attribute_prev(attr);
  }

  return list;
}

ERL_NIF_TERM
build_tree(ErlNifEnv* env, myhtml_tree_t* tree, myhtml_tree_node_t* node)
{
  ERL_NIF_TERM result;
  myhtml_tag_id_t tag_id = myhtml_node_tag_id(node);

  if (tag_id == MyHTML_TAG__TEXT)
  {
    ErlNifBinary text;
    size_t text_len;
    const char* node_text = myhtml_node_text(node, &text_len);
    enif_alloc_binary(text_len, &text);
    memcpy(text.data, node_text, text_len);

    return result = enif_make_binary(env, &text);
  }
  else if (tag_id == MyHTML_TAG__COMMENT)
  {
    ErlNifBinary comment;
    size_t comment_len;
    const char* node_comment = myhtml_node_text(node, &comment_len);
    enif_alloc_binary(comment_len, &comment);
    memcpy(comment.data, node_comment, comment_len);

    return result = enif_make_tuple3(env,
      enif_make_atom(env, "comment"),
      enif_make_list(env, 0),
      enif_make_binary(env, &comment)
    );
  }
  else
  {
    ErlNifBinary tag;
    ERL_NIF_TERM tag_bin;
    ERL_NIF_TERM children;
    ERL_NIF_TERM attrs;

    // get name of tag
    size_t tag_len;
    const char *tag_name = myhtml_tag_name_by_id(tree, tag_id, &tag_len);
    // and put it in a binary
    enif_alloc_binary(tag_len, &tag);
    memcpy(tag.data, tag_name, tag_len);
    tag_bin = enif_make_binary(env, &tag);

    // attributes
    attrs = build_node_attrs(env, tree, node);

    // add children
    children = build_node_children(env, tree, node);

    return result = enif_make_tuple3(env,
      tag_bin,
      attrs,
      children
    );
  }
}

// Erlang NIF

static ErlNifFunc funcs[] =
{
  {"decode", 1, decode}
};

static int
load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
  return 0;
}

static int
reload(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
  return 0;
}

static int
upgrade(ErlNifEnv *env, void **priv, void **old_priv, ERL_NIF_TERM info)
{
  return load(env, priv, info);
}

static void
unload(ErlNifEnv *env, void *priv)
{
  return;
}

ERL_NIF_INIT(Elixir.Myhtmlex.Decoder, funcs, &load, &reload, &upgrade, &unload)

