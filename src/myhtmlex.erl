%%%-----------------------------------------------------------------------------
%%% @doc A module to decode html into a tree structure.
%%%
%%% Based on [Alexander Borisov's myhtml](https://github.com/lexborisov/myhtml),
%%% this binding gains the properties of being html-spec compliant and very fast.
%%% @end
%%%-----------------------------------------------------------------------------
-module(myhtmlex).

%% API
-export([
  decode/1,
  decode/2,
  open/1,
  decode_tree/1,
  decode_tree/2
]).

-type tag() :: binary() | atom().
-type attr() :: {binary(), binary()}.
-type attr_list() :: [] | [attr()].
-type comment_node() :: {'comment', binary()}.
-type comment_node3() :: {'comment', [], binary()}.
-type tree() :: {tag(), attr_list(), tree()}
  | {tag(), attr_list(), nil}
  | comment_node()
  | comment_node3().
-type format_flag() :: 'html_atoms' | 'nil_self_closing' | 'comment_tuple3'.

%%------------------------------------------------------------------------------
%% @doc Returns a tree representation from the given html string.
%% @end
%%------------------------------------------------------------------------------
-spec decode(binary()) -> tree().
decode(Bin) ->
  decode(Bin, [{format, []}]).

%%------------------------------------------------------------------------------
%% @doc Returns a tree representation from the given html string.
%% This variant allows you to pass in one or more of the following format flags:
%%
%% * `:html_atoms` uses atoms for known html tags (faster), binaries for everything else.
%% * `:nil_self_closing` uses `nil` to designate self-closing tags and void elements.
%%      For example `<br>` is then being represented like `{"br", [], nil}`.
%%      See http://w3c.github.io/html-reference/syntax.html#void-elements for a full list of void elements.
%% * `:comment_tuple3` uses 3-tuple elements for comments, instead of the default 2-tuple element.
%% @end
%%------------------------------------------------------------------------------
-spec decode(binary(), [{format, [format_flag()]}]) -> tree().
decode(Bin, [{format, Flags}]) ->
  myhtmlex_nif:decode(Bin, Flags).

%%------------------------------------------------------------------------------
%% @doc Returns a reference to an internally parsed myhtml_tree_t.
%% @end
%%------------------------------------------------------------------------------
-spec open(binary()) -> reference().
open(Bin) ->
  myhtmlex_nif:open(Bin).

%%------------------------------------------------------------------------------
%% @doc Returns a tree representation from the given reference.
%% @end
%%------------------------------------------------------------------------------
-spec decode_tree(reference()) -> tree().
decode_tree(Ref) ->
  myhtmlex_nif:decode_tree(Ref).

%%------------------------------------------------------------------------------
%% @doc Returns a tree representation from the given reference and format flags.
%%
%% @see decode/2
%% @end
%%------------------------------------------------------------------------------
-spec decode_tree(reference(), [{format, [format_flag()]}]) -> tree().
decode_tree(Ref, [{format, Flags}]) ->
  myhtmlex_nif:decode_tree(Ref, Flags).
