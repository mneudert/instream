import Config

if Mix.env() == :test do
  config :logger, :console,
    format: "\n$time $metadata[$level] $message\n",
    metadata: [:query_time, :response_status]
end
