#include "myhtmlex.h"

char*
lowercase(char* c)
{
  char* p = c;
  while(*p)
  {
    *p = tolower((unsigned char)*p);
    p++;
  }
  return c;
}

ERL_NIF_TERM
make_atom(ErlNifEnv* env, const char* name)
{
  ERL_NIF_TERM ret;
  if(enif_make_existing_atom(env, name, &ret, ERL_NIF_LATIN1)) {
    return ret;
  }
  return enif_make_atom(env, name);
}

ERL_NIF_TERM
nif_open(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM result;
  myhtmlex_ref_t* ref;

  // fetch nif state
  myhtmlex_state_t* state = (myhtmlex_state_t*) enif_priv_data(env);

  // placeholder for the html binary we want to read from erlang caller
  ErlNifBinary html_bin;
  // read binary into &html_bin from argv[0] (first argument)
  if (!enif_inspect_iolist_as_binary(env, argv[0], &html_bin))
  {
    // blame the user if html_bin is not a binary
    return enif_make_badarg(env);
  }

  ref = enif_alloc_resource(state->myhtml_tree_rt, sizeof(myhtmlex_ref_t));
  ref->tree = myhtml_tree_create();
  myhtml_tree_init(ref->tree, state->myhtml);
  mystatus_t status = myhtml_parse(ref->tree, MyENCODING_UTF_8, (char*) html_bin.data, (size_t) html_bin.size);
  if (status != MyHTML_STATUS_OK)
  {
    // TODO: what is the correct reaction for a not ok state?
    return enif_make_badarg(env);
  }
  ref->root = myhtml_tree_get_document(ref->tree);

  // garbage collect argument
  enif_release_binary(&html_bin);

  result = enif_make_resource(env, ref);
  return result;
}

ERL_NIF_TERM
nif_decode_tree(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM result;
  myhtmlex_ref_t* ref;

  // fetch nif state
  myhtmlex_state_t* state = (myhtmlex_state_t*) enif_priv_data(env);

  // fetch reference
  if (!enif_get_resource(env, argv[0], state->myhtml_tree_rt, (void **) &ref))
  {
    return enif_make_badarg(env);
  }

  // build erlang tree
  result = build_tree(env, ref->tree, myhtml_node_last_child(ref->root));

  // return tree to erlang
  return result;
}

ERL_NIF_TERM
nif_decode(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM result;

  // fetch nif state
  myhtmlex_state_t* state = (myhtmlex_state_t*) enif_priv_data(env);

  // placeholder for the html binary we want to read from erlang caller
  ErlNifBinary html_bin;
  // read binary into &html_bin from argv[0] (first argument)
  if (!enif_inspect_iolist_as_binary(env, argv[0], &html_bin))
  {
    // blame the user if html_bin is not a binary
    return enif_make_badarg(env);
  }

  // clear myhtml tree resources before parsing
  myhtml_tree_clean(state->tree);
  // parse html into tree
  mystatus_t status = myhtml_parse(state->tree, MyENCODING_UTF_8, (char*) html_bin.data, (size_t) html_bin.size);
  if (status != MyHTML_STATUS_OK)
  {
    // TODO: what is the correct reaction for a not ok state?
    return enif_make_badarg(env);
  }

  // build erlang tree
  myhtml_tree_node_t *root = myhtml_tree_get_document(state->tree);
  result = build_tree(env, state->tree, myhtml_node_last_child(root));

  // garbage collect argument
  enif_release_binary(&html_bin);
  // release myhtml resources
  myhtml_node_free(root);

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
  myhtml_namespace_t tag_ns = myhtml_node_namespace(node);

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
      make_atom(env, "comment"),
      enif_make_list(env, 0),
      enif_make_binary(env, &comment)
    );
  }
  else
  {
    ERL_NIF_TERM tag;
    ERL_NIF_TERM children;
    ERL_NIF_TERM attrs;

    // get name of tag
    size_t tag_name_len;
    const char *tag_name = myhtml_tag_name_by_id(tree, tag_id, &tag_name_len);
    size_t tag_string_len;
    // get namespace of tag
    size_t tag_ns_len;
    const char *tag_ns_name_ptr = myhtml_namespace_name_by_id(tag_ns, &tag_ns_len);
    char *tag_ns_buffer;
    char buffer [tag_ns_len + 2];
    char *tag_string = buffer;

    if (tag_ns != MyHTML_NAMESPACE_HTML)
    {
      // tag_ns_name_ptr is unmodifyable
      tag_ns_buffer = malloc(tag_ns_len);
      strcpy(tag_ns_buffer, tag_ns_name_ptr);
      tag_ns_buffer = lowercase(tag_ns_buffer);
      tag_string_len = tag_ns_len + tag_name_len + 1; // +1 for colon
      stpcpy(stpcpy(stpcpy(tag_string, tag_ns_buffer), ":"), tag_name);
    }
    else
    {
      stpcpy(tag_string, tag_name);
      tag_string_len = tag_name_len;
    }

    // put non-html tags it in a binary
    if (tag_id == MyHTML_TAG__UNDEF || tag_ns != MyHTML_NAMESPACE_HTML)
    {
      ErlNifBinary tag_b;
      enif_alloc_binary(tag_string_len, &tag_b);
      memcpy(tag_b.data, tag_string, tag_string_len);
      tag = enif_make_binary(env, &tag_b);
    }
    else
    {
      tag = make_atom(env, tag_string);
    }

    // attributes
    attrs = build_node_attrs(env, tree, node);

    // add children or nil as a self-closing flag
    if (myhtml_node_is_close_self(node))
    {
      children = ATOM_NIL;
    }
    else
    {
      children = build_node_children(env, tree, node);
    }

    // free allocated resources
    if (tag_ns != MyHTML_NAMESPACE_HTML)
    {
      free(tag_ns_buffer);
    }

    return result = enif_make_tuple3(env,
      tag,
      attrs,
      children
    );
  }
}

void
nif_cleanup_myhtmlex_ref(ErlNifEnv* env, void* obj)
{
  myhtmlex_ref_t* ref = (myhtmlex_ref_t*) obj;
  // release myhtml resources
  myhtml_tree_destroy(ref->tree);
  myhtml_node_free(ref->root);
}

// Erlang NIF

static int
load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
  myhtmlex_state_t* state = enif_alloc(sizeof(myhtmlex_state_t));
  if (state == NULL)
  {
    return 1;
  }

  state->myhtml_tree_rt = enif_open_resource_type(
    env,
    NULL,
    "myhtmlex_ref_t",
    &nif_cleanup_myhtmlex_ref,
    ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER,
    NULL
  );
  ATOM_NIL = make_atom(env, "nil");

  // myhtml basic init
  state->myhtml = myhtml_create();
  myhtml_init(state->myhtml, MyHTML_OPTIONS_DEFAULT, 4, 0);
  state->tree = myhtml_tree_create();
  myhtml_tree_init(state->tree, state->myhtml);

  *priv = (void*) state;
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
  myhtmlex_state_t* state = (myhtmlex_state_t*) priv;

  myhtml_tree_destroy(state->tree);
  myhtml_destroy(state->myhtml);
  enif_free(priv);
  return;
}

static ErlNifFunc funcs[] =
{
  {"decode", 1, nif_decode},
  {"open", 1, nif_open},
  {"decode_tree", 1, nif_decode_tree}
};

ERL_NIF_INIT(Elixir.Myhtmlex.Decoder, funcs, &load, &reload, &upgrade, &unload)

