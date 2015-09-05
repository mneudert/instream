use Mix.Config

config :instream_test, Instream.TestHelpers.Connection,
  auth:   [ username: "instream_test", password: "instream_test" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream_test, Instream.TestHelpers.LineConnection,
  auth:   [ username: "instream_test", password: "instream_test" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http",
  writer: Instream.Writer.Line


config :instream_test, Instream.TestHelpers.AnonConnection,
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream_test, Instream.TestHelpers.GuestConnection,
  auth:   [ username: "instream_guest", password: "instream_guest" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream_test, Instream.TestHelpers.InvalidConnection,
  auth:   [ username: "instream_test", password: "instream_invalid" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream_test, Instream.TestHelpers.NotFoundConnection,
  auth:   [ username: "instream_not_found", password: "instream_not_found" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream_test, Instream.TestHelpers.QueryAuthConnection,
  auth:   [ method: :query, username: "instream_test", password: "instream_test" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"
