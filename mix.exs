defmodule MyProjec.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_projec,
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Только необходимые зависимости
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
