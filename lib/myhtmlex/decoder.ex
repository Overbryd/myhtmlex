defmodule Myhtmlex.Decoder do
  @on_load { :init, 0  }

  app = Mix.Project.config[:app]

  def init do
    path = :filename.join(:code.priv_dir(unquote(app)), 'myhtmlex')
    :ok = :erlang.load_nif(path, 0)
  end

  @spec decode(bin :: String.t) :: {atom(), list(), list()}
  def decode(bin)
  def decode(_), do: exit(:nif_library_not_loaded)
end
