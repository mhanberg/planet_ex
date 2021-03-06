# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :planetex, ecto_repos: [PlanetEx.Repo]

# Configures the endpoint
config :planetex, PlanetExWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "TYlZ+tfWNCIki6f8W7avWBhwzG0t6Yio8z21KcV0JcnGy0T9fP1i0qyG8TR16I3/",
  render_errors: [view: PlanetExWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PlanetEx.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :planetex, :server_farm_supervisor, PlanetEx.Core.ServerFarmSupervisor
config :planetex, :server_timeout, 60000

config :wallaby,
  screenshot_on_failure: true,
  chrome: [headless: true],
  driver: Wallaby.Experimental.Chrome

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
