defmodule Starship.Mixfile do
  use Mix.Project

  def project do
    [
      app: :starship,
      version: "0.0.1",
      elixir: "~> 1.12",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      name: "Starship",
      description: description(),
      source_url: "https://github.com/probably-not/starship",
      homepage_url: "https://github.com/probably-not/starship",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        ci: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      # The main page in the docs
      docs: [main: "Starship", extras: ["README.md"]],
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}, plt_add_deps: :app_tree]
    ]
  end

  def application do
    [
      extra_applications: applications(Mix.env())
    ]
  end

  defp applications(:dev), do: applications(:all) ++ [:remixed_remix]
  defp applications(_all), do: [:ssl, :logger, :runtime_tools]

  def deps do
    [
      ## Testing and Development Dependencies
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:remixed_remix, "~> 2.0.2", only: :dev},
      # This is a replacement for the erlex dependency found at https://github.com/asummers/erlex
      # erlex is transitively used by others in our test and dev dependencies, but it has warnings during compilation
      # and the project hasn't been maintained in 3 years, so I forked it just to solve the warnings.
      {:erlex,
       git: "https://github.com/probably-not/erlex.git",
       override: true,
       only: [:dev, :test],
       runtime: false}
    ]
  end

  defp package do
    [
      description: description(),
      # These are the default files included in the package
      files: ~w(lib mix.exs README* LICENSE* CHANGELOG*),
      maintainers: ["Coby Benveniste"],
      links: %{"GitHub" => "https://github.com/probably-not/starship"},
      licenses: ["MIT"]
    ]
  end

  defp description do
    """
    A High Performance Low Level Elixir Webserver.
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      quality: ["format", "credo --strict", "dialyzer"],
      ci: ["test", "format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end
end
