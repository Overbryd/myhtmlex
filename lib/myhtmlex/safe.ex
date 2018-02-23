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
    myhtml_worker = Path.join(:code.priv_dir(unquote(app)), "myhtml_worker")
    children = [
      worker(Nodex.Cnode, [%{exec_path: myhtml_worker}, [name: __MODULE__]])
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Myhtmlex.Safe.Supervisor)
  end

  @doc false
  def decode(bin) do
    decode(bin, [])
  end

  @doc false
  def decode(bin, flags) do
    {:ok, res} = Nodex.Cnode.call(__MODULE__, {:decode, bin, flags})
    res
  end

end

