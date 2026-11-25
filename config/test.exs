import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :sakusen, Sakusen.Repo,
  database: Path.expand("../sakusen_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sakusen, SakusenWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "iwiqSHuQiwNl8snkp9VJu9SSDdZj118YydaJ1gS+EIK6NlDGKhvQBycfEjH3Hyjc",
  server: false

# In test we don't send emails
config :sakusen, Sakusen.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :sakusen, media_root: Path.expand("../tmp/test_media", __DIR__)

config :sakusen, Sakusen.Storage.S3,
  req_options: [plug: {Req.Test, Sakusen.Storage.S3}, retry: false]

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
