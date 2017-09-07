defmodule Mix.Tasks.Compile.Myhtml do
  def run(_) do
    if match? {:win32, _}, :os.type do
      IO.warn "Windows is not yet a target."
      exit(1)
    else
      File.mkdir_p("priv")
      {result, _error_code} = System.cmd("make", ["priv/myhtmlex.so"], stderr_to_stdout: true)
      IO.binwrite result
    end
    :ok
  end
end

defmodule Myhtmlex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :myhtmlex,
      version: "0.1.0",
      elixir: "~> 1.5",
      compilers: [:myhtml, :elixir, :app],
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # myhtml c library
      {:myhtml, github: "Overbryd/myhtml", branch: "feat/node-is-void-element", app: false},
      # {:myhtml, github: "lexborisov/myhtml", tag: "v4.0.2", app: false},
      # documentation helpers
      {:ex_doc, ">= 0.0.0", only: :dev},
      # benchmarking helpers
      {:benchfella, "~> 0.3.0", only: :dev}
    ]
  end
end
