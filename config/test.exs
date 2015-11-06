use Mix.Config

config :instream, Instream.TestHelpers.Connection,
  auth:   [ username: "instream_test", password: "instream_test" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream, Instream.TestHelpers.JSONConnection,
  auth:   [ username: "instream_test", password: "instream_test" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http",
  writer: Instream.Writer.JSON

config :instream, Instream.TestHelpers.UDPConnection,
  auth:     [ username: "instream_test", password: "instream_test" ],
  hosts:    [ "localhost" ],
  pool:     [ max_overflow: 0, size: 1 ],
  port:     8086,
  port_udp: 8089,
  scheme:   "http",
  writer:   Instream.Writer.UDP


config :instream, Instream.TestHelpers.AnonConnection,
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream, Instream.TestHelpers.GuestConnection,
  auth:   [ username: "instream_guest", password: "instream_guest" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream, Instream.TestHelpers.InvalidConnection,
  auth:   [ username: "instream_test", password: "instream_invalid" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream, Instream.TestHelpers.NotFoundConnection,
  auth:   [ username: "instream_not_found", password: "instream_not_found" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"

config :instream, Instream.TestHelpers.QueryAuthConnection,
  auth:   [ method: :query, username: "instream_test", password: "instream_test" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"
