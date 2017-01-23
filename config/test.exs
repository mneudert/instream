use Mix.Config


config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:query_time, :response_status]


config :instream, Instream.TestHelpers.Connection,
  auth:    [ username: "instream_test", password: "instream_test" ],
  host:    "localhost",
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream, Instream.TestHelpers.LogConnection,
  auth:   [ username: "instream_test", password: "instream_test" ],
  host:   "localhost",
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"


config :instream, Instream.TestHelpers.EnvConnection,
  auth:    [ username: { :system, "INSTREAM_TEST_USERNAME" },
             password: { :system, "INSTREAM_TEST_PASSWORD" } ],
  host:    { :system, "INSTREAM_TEST_HOST" },
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream, Instream.TestHelpers.UDPConnection,
  auth:     [ username: "instream_test", password: "instream_test" ],
  host:     "localhost",
  loggers:  [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:     [ max_overflow: 0, size: 1 ],
  port_udp: 8089,
  writer:   Instream.Writer.UDP


config :instream, Instream.TestHelpers.AnonConnection,
  host:    "localhost",
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream, Instream.TestHelpers.GuestConnection,
  auth:    [ username: "instream_guest", password: "instream_guest" ],
  host:    "localhost",
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream, Instream.TestHelpers.InvalidConnection,
  auth:    [ username: "instream_test", password: "instream_invalid" ],
  host:    "localhost",
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream, Instream.TestHelpers.InvalidDbConnection,
  auth:     [ username: "instream_test", password: "instream_test" ],
  database: "invalid_test_database",
  host:     "localhost",
  loggers:  [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:     [ max_overflow: 0, size: 1 ]

config :instream, Instream.TestHelpers.NotFoundConnection,
  auth:    [ username: "instream_not_found", password: "instream_not_found" ],
  host:    "localhost",
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream, Instream.TestHelpers.QueryAuthConnection,
  auth:    [ method: :query, username: "instream_test", password: "instream_test" ],
  host:    "localhost",
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream, Instream.TestHelpers.UnreachableConnection,
  host:    "some.really.unreachable.host",
  loggers: [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]


config :instream, Instream.TestHelpers.ConnectionWithOpts,
  host:      "localhost",
  loggers:   [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:      [ max_overflow: 0, size: 1 ],
  http_opts: [ proxy: "http://invalidproxy" ]

config :instream, Instream.TestHelpers.TimeoutConnection,
  host:      "localhost",
  loggers:   [{ Instream.TestHelpers.NilLogger, :log, [] }],
  pool:      [ max_overflow: 0, size: 1 ],
  http_opts: [ pool: :instream_test_sleeper ]
