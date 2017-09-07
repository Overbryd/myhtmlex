defmodule Mix.Tasks.Compile.Myhtml do
  def run(_) do
    if match? {:win32, _}, :os.type do
      IO.warn "Windows is not yet a target."
      exit(1)
    else
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
      description: "A module to decode HTML into a tree, porting all properties of the underlying library myhtml, being fast and correct in regards to the html spec.",
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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # in dev environment, manage myhtml c library with mix
      {:myhtml, github: "lexborisov/myhtml", branch: "master", app: false, only: :dev},
      # documentation helpers
      {:ex_doc, ">= 0.0.0", only: :dev},
      # benchmarking helpers
      {:benchfella, "~> 0.3.0", only: :dev}
    ]
  end
end
