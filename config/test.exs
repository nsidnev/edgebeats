import Config

config :live_beats, :files,
  uploads_dir: Path.expand("../tmp/test-uploads", __DIR__),
  host: [scheme: "http", host: "localhost", port: 4000],
  server_ip: "127.0.0.1"

# right now EdgeDB in tests uses EdgeDB.Sandbox connection
# which doesn't work well with concurrent access
# so in tests songs cleaner process will be disabled
config :live_beats, :songs_cleaner, use: false

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :edgedb,
  database: "live_beats_test#{System.get_env("MIX_TEST_PARTITION")}",
  connection: EdgeDB.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_beats, LiveBeatsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

# In test we don't send emails.
config :live_beats, LiveBeats.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
