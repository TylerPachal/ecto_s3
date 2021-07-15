defmodule EctoS3.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_s3,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.6"},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.2"},
      {:jason, "~> 1.2"},
      {:hackney, "~> 1.9"},

      # Only used for development
      {:ecto_sql, "~> 3.6", only: [:dev, :test]},
      {:myxql, "~> 0.5", only: [:dev, :test]}
    ]
  end
end
