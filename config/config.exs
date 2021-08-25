use Mix.Config

if Mix.env() == :test do
  config :logger, :console,
    format: "\n$time $metadata[$level] $levelpad$message\n",
    metadata: [:query_time, :response_status]
end
