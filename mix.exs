defmodule Sentry.Mixfile do
  use Mix.Project

  def project do
    [app: :sentry,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :comeonin, :plug, :ecto, :ueberauth, :ueberauth_identity]]
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
    [{:comeonin, "~> 1.0"},
     {:ecto, "~> 1.0"},
     {:plug, "~> 1.0"},
     {:ueberauth, "~> 0.2"},
     {:ueberauth_identity, "~> 0.1"},
     {:comeonin, "~> 1.0"}]
  end
end
