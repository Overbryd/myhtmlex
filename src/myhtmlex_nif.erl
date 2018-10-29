-module(myhtmlex_nif).

-export([
  decode/1,
  decode/2,
  open/1,
  decode_tree/1,
  decode_tree/2
]).

-on_load(init/0).

init() ->
  Path = filename:join(code:priv_dir(myhtmlex), "myhtmlex"),
  ok = erlang:load_nif(Path, 0).

decode(_Bin) ->
  exit(nif_library_not_loaded).

decode(_Bin, _Flags) ->
  exit(nif_library_not_loaded).

open(_Bin) ->
  exit(nif_library_not_loaded).

decode_tree(_Tree) ->
  exit(nif_library_not_loaded).

decode_tree(_Tree, _Flags) ->
  exit(nif_library_not_loaded).
