defmodule Myhtmlex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :myhtmlex,
      version: "0.2.0",
      elixir: "~> 1.5",
      deps: deps(),
      package: package(),
      compilers: [:myhtmlex_make] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      name: "Myhtmlex",
      description: """
        A module to decode HTML into a tree,
        porting all properties of the underlying
        library myhtml, being fast and correct
        in regards to the html spec.
      """,
      docs: docs()
    ]
  end

  def package do
    [
      maintainers: ["Lukas Rieder"],
      licenses: ["GNU LGPL"],
      links: %{
        "Github" => "https://github.com/Overbryd/myhtmlex",
        "Issues" => "https://github.com/Overbryd/myhtmlex/issues",
        "MyHTML" => "https://github.com/lexborisov/myhtml"
      },
      files: [
        "lib",
        "c_src",
        "priv/.gitignore",
        "test",
        "Makefile",
        "Makefile.Darwin",
        "Makefile.Linux",
        "mix.exs",
        "README.md",
        "LICENSE"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Myhtmlex.Safe, []},
      # used to detect conflicts with other applications named processes
      registered: [Myhtmlex.Safe.Cnode, Myhtmlex.Safe.Supervisor],
      env: [
        mode: Myhtmlex.Safe
      ]
    ]
  end

  defp deps do
    [
      # documentation helpers
      {:ex_doc, ">= 0.0.0", only: :dev},
      # benchmarking helpers
      {:benchfella, "~> 0.3.0", only: :dev},
      # cnode helpers
      {:nodex, "~> 0.1.1"}
    ]
  end

  defp docs do
    [
      main: "Myhtmlex"
    ]
  end
end

defmodule Mix.Tasks.Compile.MyhtmlexMake do
  @artifacts [
    "priv/myhtmlex.so",
    "priv/myhtml_worker"
  ]

  def run(_) do
    if match? {:win32, _}, :os.type do
      IO.warn "Windows is not yet a target."
      exit(1)
    else
      {result, _error_code} = System.cmd("make",
        @artifacts,
        stderr_to_stdout: true,
        env: [{"MIX_ENV", to_string(Mix.env)}]
      )
      IO.binwrite result
    end
    :ok
  end

  def clean() do
    {result, _error_code} = System.cmd("make", ["clean"], stderr_to_stdout: true)
    Mix.shell.info result
    :ok
  end
end

