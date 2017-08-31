defmodule Myhtmlex.Nif do
  @moduledoc false
  @on_load { :init, 0 }

  app = Mix.Project.config[:app]

  def init do
    path = :filename.join(:code.priv_dir(unquote(app)), 'myhtmlex')
    :ok = :erlang.load_nif(path, 0)
  end

  @doc false
  def decode(bin)
  def decode(_), do: exit(:nif_library_not_loaded)

  @doc false
  def decode(bin, flags)
  def decode(_, _), do: exit(:nif_library_not_loaded)

  @doc false
  def open(bin)
  def open(_), do: exit(:nif_library_not_loaded)

  @doc false
  def decode_tree(tree)
  def decode_tree(_), do: exit(:nif_library_not_loaded)

  @doc false
  def decode_tree(tree, flags)
  def decode_tree(_, _), do: exit(:nif_library_not_loaded)
end

