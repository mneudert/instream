use Mix.Config

alias Instream.TestHelpers
alias Instream.TestHelpers.Connections, as: TestConnections


config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:query_time, :response_status]


config :instream,TestConnections.DefaultConnection,
  auth:    [ username: "instream_test", password: "instream_test" ],
  host:    "localhost",
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream,TestConnections.LogConnection,
  auth: [ username: "instream_test", password: "instream_test" ],
  host: "localhost",
  pool: [ max_overflow: 0, size: 1 ]


config :instream,TestConnections.EnvConnection,
  auth:    [ username: { :system, "INSTREAM_TEST_USERNAME" },
             password: { :system, "INSTREAM_TEST_PASSWORD" } ],
  host:    { :system, "INSTREAM_TEST_HOST" },
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream,TestConnections.UDPConnection,
  auth:     [ username: "instream_test", password: "instream_test" ],
  host:     "localhost",
  loggers:  [{TestHelpers.NilLogger, :log, [] }],
  pool:     [ max_overflow: 0, size: 1 ],
  port_udp: 8089,
  writer:   Instream.Writer.UDP


config :instream,TestConnections.InetsConnection,
  # port will be set properly during test setup
  host:    "localhost",
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ],
  port:    99999


config :instream,TestConnections.AnonConnection,
  host:    "localhost",
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream,TestConnections.GuestConnection,
  auth:    [ username: "instream_guest", password: "instream_guest" ],
  host:    "localhost",
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream,TestConnections.InvalidConnection,
  auth:    [ username: "instream_test", password: "instream_invalid" ],
  host:    "localhost",
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream,TestConnections.InvalidDbConnection,
  auth:     [ username: "instream_test", password: "instream_test" ],
  database: "invalid_test_database",
  host:     "localhost",
  loggers:  [{TestHelpers.NilLogger, :log, [] }],
  pool:     [ max_overflow: 0, size: 1 ]

config :instream,TestConnections.NotFoundConnection,
  auth:    [ username: "instream_not_found", password: "instream_not_found" ],
  host:    "localhost",
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream,TestConnections.QueryAuthConnection,
  auth:    [ method: :query, username: "instream_test", password: "instream_test" ],
  host:    "localhost",
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]

config :instream,TestConnections.UnreachableConnection,
  host:    "some.really.unreachable.host",
  loggers: [{TestHelpers.NilLogger, :log, [] }],
  pool:    [ max_overflow: 0, size: 1 ]


config :instream,TestConnections.OptionsConnection,
  host:      "localhost",
  loggers:   [{TestHelpers.NilLogger, :log, [] }],
  pool:      [ max_overflow: 0, size: 1 ],
  http_opts: [ proxy: "http://invalidproxy" ]
