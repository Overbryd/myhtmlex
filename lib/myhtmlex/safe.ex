defmodule Myhtmlex.Safe do
  @moduledoc """
    Safely decode html using a C-Node. Any problem with myhtml and the c-binding will not affect the Erlang VM.
  """

  use Application

  app = Mix.Project.config[:app]

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec
    unless Node.alive? do
      Nodex.Distributed.up
    end
    cclient = :filename.join(:code.priv_dir(unquote(app)), 'cclient')
    children = [
      worker(Nodex.Cnode, [%{exec_path: cclient}, [name: __MODULE__]])
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Myhtmlex.Safe.Supervisor)
  end

  @doc false
  def decode(bin) do
    decode(bin, format: [])
  end

  @doc false
  def decode(bin, format: flags) do
    {:ok, res} = Nodex.Cnode.call(__MODULE__, {:decode, bin, flags})
    res
  end

end

