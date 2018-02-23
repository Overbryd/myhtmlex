defmodule Myhtmlex.Safe do
  @moduledoc false

  use Application

  app = Mix.Project.config[:app]

  def start(_type, _args) do
    import Supervisor.Spec
    unless Node.alive? do
      Nodex.Distributed.up
    end
    myhtml_worker = Path.join(:code.priv_dir(unquote(app)), "myhtml_worker")
    children = [
      worker(Nodex.Cnode, [%{exec_path: myhtml_worker}, [name: Myhtmlex.Safe.Cnode]])
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Myhtmlex.Safe.Supervisor)
  end

  def decode(bin) do
    decode(bin, [])
  end

  def decode(bin, flags) do
    {:ok, res} = Nodex.Cnode.call(Myhtmlex.Safe.Cnode, {:decode, bin, flags})
    res
  end

end

