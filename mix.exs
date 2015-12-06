defmodule Sentry.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sentry,
      version: "0.3.1",
      elixir: "~> 1.1",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description,
      package: package,
      deps: deps
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    case Mix.env do
      :test ->
        [applications: [:logger, :ecto, :comeonin, :postgrex]]
      _     ->
        [applications: [:logger, :ecto, :comeonin]]
    end
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp description do
    """
    Simplified authentication and authorization package for Phoenix
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Imran Ismail"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/imranismail/sentry"}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    case Mix.env do
      :test ->
        [
          {:comeonin, "~> 1.0"},
          {:ecto, "~> 1.0"},
          {:postgrex, ">= 0.0.0"}
        ]
      _ ->
        [
          {:comeonin, "~> 1.0"},
          {:ecto, "~> 1.0"},
        ]
    end
  end
end
