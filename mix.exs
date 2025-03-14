defmodule MplBubblegum.MixProject do
  use Mix.Project

  def project do
    [
      app: :mpl_bubblegum_lib,
      version: "0.1.0",
      elixir: "~> 1.17.3",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/rishavmehra/mpl-bubblegum-ex",
      package: package()
    ]
  end

  defp package do
    [
      name: "mpl_bubblegum_exs",
      maintainers: ["Rishav"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/rishavmehra/mpl-bubblegum-ex",
        "Docs" => "https://github.com/rishavmehra/mpl-bubblegum-ex/blob/master/README.md"
      },
      description: """
      MplBubblegum is an Elixir library for working with Compressed NFTs (cNFTs) on Solana via
      the Bubblegum program. It allows developers to create Merkle Trees, mint cNFTs,
      and transfer assets.
      """
    ]
  end


  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.36.1"},
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

end
