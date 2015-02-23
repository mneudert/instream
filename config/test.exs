use Mix.Config

config :instream_test, Instream.TestHelpers.Connection,
  hosts:    [ "localhost" ],
  pool:     [ max_overflow: 0, size: 1 ],
  port:     8086,
  scheme:   "http"
