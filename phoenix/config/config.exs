import Config

config :my_app, MyApp.Repo,
  database: Path.expand("../my_app.db", __DIR__),
  pool_size: 5

config :my_app, ecto_repos: [MyApp.Repo]

config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  render_errors: [formats: [json: MyAppWeb.ErrorJSON]]

config :phoenix, :json_library, Jason

config :logger, :default_formatter, format: "$time $metadata[$level] $message\n"
