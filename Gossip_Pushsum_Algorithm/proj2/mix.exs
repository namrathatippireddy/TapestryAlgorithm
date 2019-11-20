defmodule GossipPushSum.MixProject do
  use Mix.Project

  def project do
    [
      app: :proj2,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      #deps: deps()
      escript: escript()
    ]
  end

  defp escript do
    [main_module: Gossip]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

end
