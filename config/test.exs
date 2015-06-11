use Mix.Config

config :instream_test, Instream.TestHelpers.Connection,
  auth:   [ username: "instream_test", password: "instream_test" ],
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"
