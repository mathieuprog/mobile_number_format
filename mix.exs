defmodule MobileNumberFormat.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :mobile_number_format,
      elixir: "~> 1.11",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      version: @version,
      package: package(),
      description: "Parse and validate mobile numbers",

      # ExDoc
      name: "Mobile Number Format",
      source_url: "https://github.com/mathieuprog/mobile_number_format",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:saxy, "~> 1.4"},
      {:jason, "~> 1.3", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Mathieu Decaffmeyer"],
      links: %{"GitHub" => "https://github.com/mathieuprog/mobile_number_format"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end
end
