use Mix.Config


config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:query_time, :response_status]

common_host = [
  database:  (System.get_env("INSTREAM_DATABASE") || "instream_test"),
  host:      System.get_env("INSTREAM_HOST") || "localhost",
  port:      System.get_env("INSTREAM_HTTP_PORT") || 8086,
]

config :instream, Instream.TestHelpers.Connection, common_host ++ [
  auth:    [ username: "instream_test", password: "instream_test" ],
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.LogConnection, common_host ++ [
  auth:   [ username: "instream_test", password: "instream_test" ],
  pool:   [ max_overflow: 0, size: 1 ],
  scheme: "http"
]

config :instream, Instream.TestHelpers.EnvConnection, common_host ++ [
  auth:    [ username: { :system, "INSTREAM_TEST_USERNAME" },
             password: { :system, "INSTREAM_TEST_PASSWORD" } ],
  host:    { :system, "INSTREAM_TEST_HOST" },
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.UDPConnection, common_host ++ [
  auth:     [ username: "instream_test", password: "instream_test" ],
  loggers:  [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:     [ max_overflow: 0, size: 1 ],
  port_udp: 8089,
  writer:   Instream.Writer.UDP
]

config :instream, Instream.TestHelpers.AnonConnection, common_host ++ [
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.GuestConnection, common_host ++ [
  auth:    [ username: "instream_guest", password: "instream_guest" ],
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.InvalidConnection, common_host ++ [
  auth:    [ username: "instream_test", password: "instream_invalid" ],
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.InvalidDbConnection, common_host ++ [
  auth:     [ username: "instream_test", password: "instream_test" ],
  database: "invalid_test_database",
  loggers:  [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:     [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.NotFoundConnection, common_host ++ [
  auth:    [ username: "instream_not_found", password: "instream_not_found" ],
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.QueryAuthConnection, common_host ++ [
  auth:    [ method: :query, username: "instream_test", password: "instream_test" ],
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.UnreachableConnection, [
  host:    "some.really.unreachable.host",
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]
]

config :instream, Instream.TestHelpers.ConnectionWithOpts, common_host ++ [
  loggers:   [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:      [ max_overflow: 0, size: 1 ],
  http_opts: [ proxy: "http://invalidproxy" ]
]
