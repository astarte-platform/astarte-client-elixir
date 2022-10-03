defmodule Astarte.Client.MixProject do
  use Mix.Project

  @source_url "https://github.com/astarte-platform/astarte-client-elixir"
  @version "0.1.0"

  def project do
    [
      app: :astarte_client,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @source_url,
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Astarte.Client.Application, []}
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:finch, "~> 0.9"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.4"},
      {:x509, "~> 0.8"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      groups_for_modules: groups_for_modules(),
      nest_modules_by_prefix: nest_modules_by_prefix()
    ]
  end

  defp groups_for_modules do
    [
      AppEngine: ~r/^Astarte\.Client\.AppEngine/,
      Housekeeping: ~r/^Astarte\.Client\.Housekeeping/,
      Pairing: ~r/^Astarte\.Client\.Pairing/,
      RealmManagement: ~r/^Astarte\.Client\.RealmManagement/,
      Utilities: [
        Astarte.Client.Credentials,
        Astarte.Client.APIError
      ]
    ]
  end

  defp nest_modules_by_prefix do
    [
      Astarte.Client.AppEngine,
      Astarte.Client.Housekeeping,
      Astarte.Client.Pairing,
      Astarte.Client.RealmManagement
    ]
  end
end
