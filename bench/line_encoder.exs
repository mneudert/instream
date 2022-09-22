alias Instream.Encoder.Line

point_complete = %{
  measurement: "disk_free",
  fields: %{
    value: 442_221_834_240
  },
  tags: %{
    hostname: "server01"
  },
  timestamp: 1_435_362_189_575_692_182
}

point_escaping = %{
  measurement: ~S("measurement with quotes"),
  tags: %{
    "tag key with spaces" => ~S(tag,value,with"commas")
  },
  fields: %{
    ~S(field_key\\\\) => ~S(string field value, only " need be quoted)
  },
  timestamp: nil
}

point_simple = %{
  measurement: "disk_free",
  fields: %{
    value: 442_221_834_240
  },
  timestamp: nil
}

Benchee.run(
  %{
    "Encoding" => &Line.encode/1
  },
  inputs: %{
    "complete" => [point_complete],
    "escaping" => [point_escaping],
    "multiple" => List.duplicate(point_simple, 50),
    "simple" => [point_simple]
  },
  formatters: [{Benchee.Formatters.Console, comparison: false}],
  warmup: 2,
  time: 10
)
