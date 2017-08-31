defmodule Myhtmlex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :myhtmlex,
      version: "0.2.0",
      elixir: "~> 1.5",
      compilers: [:myhtmlex_make, :elixir, :app],
      start_permanent: Mix.env == :prod,
      description: """
        A module to decode HTML into a tree,
        porting all properties of the underlying
        library myhtml, being fast and correct
        in regards to the html spec.
      """,
      package: package(),
      deps: deps()
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Myhtmlex.Safe, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
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
end

defmodule Mix.Tasks.Compile.MyhtmlexMake do
  @artifacts [
    "priv/myhtmlex.so",
    "priv/cclient"
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

