defmodule Instream.WriterLineTest do
  use ExUnit.Case
  alias Instream.Writer.Line

  # This test suite is a direct port of:
  # https://influxdb.com/docs/v0.9/write_protocols/write_syntax.html

  test "simplest valid point" do
    "disk_free value=442221834240i" = Line.to_line(%{
      points: [
        %{
          measurement: "disk_free",
          fields: %{
            value: 442221834240
          }
        }
      ]
    })
  end

  test "with timestamp" do
    "disk_free value=442221834240i 1435362189575692182" = Line.to_line(%{
      points: [
        %{
          measurement: "disk_free",
          fields: %{
            value: 442221834240
          },
          timestamp: 1435362189575692182
        }
      ]
    })
  end

  test "with tags" do
    "disk_free,hostname=server01,disk_type=SSD value=442221834240i" = Line.to_line(%{
      points: [
        %{
          measurement: "disk_free",
          fields: %{
            value: 442221834240
          },
          tags: %{
            hostname: "server01",
            disk_type: "SSD"
          }
        }
      ]
    })
  end

  test "with tags and timestamp" do
    "disk_free,hostname=server01,disk_type=SSD value=442221834240i 1435362189575692182" = Line.to_line(%{
      points: [
        %{
          measurement: "disk_free",
          fields: %{
            value: 442221834240
          },
          tags: %{
            hostname: "server01",
            disk_type: "SSD"
          },
          timestamp: 1435362189575692182
        }
      ]
    })
  end

  test "multiple fields" do
    "disk_free free_space=442221834240i,disk_type=\"SSD\" 1435362189575692182" = Line.to_line(%{
      points: [
        %{
          measurement: "disk_free",
          fields: %{
            free_space: 442221834240,
            disk_type:  "SSD"
          },
          timestamp: 1435362189575692182
        }
      ]
    })
  end

  test "escaping commas and spaces" do
    ~S|total\ disk\ free,volumes=/net\,/home\,/ value=442221834240i 1435362189575692182| = Line.to_line(%{
      points: [
        %{
          measurement: "total disk free",
          tags: %{
            volumes: "/net,/home,/"
          },
          fields: %{
            value: 442221834240,
          },
          timestamp: 1435362189575692182
        }
      ]
    })
  end

  test "escaping equals signs" do
    ~S|disk_free,a\=b=y\=z value=442221834240i| = Line.to_line(%{
      points: [
        %{
          measurement: "disk_free",
          tags: %{
            "a=b" => "y=z"
          },
          fields: %{
            value: 442221834240,
          }
        }
      ]
    })
  end

  test "with backslash in tag value" do
    ~S|disk_free,path=C:\Windows value=442221834240i| = Line.to_line(%{
      points: [
        %{
          measurement: "disk_free",
          tags: %{
            path: ~S|C:\Windows|
          },
          fields: %{
            value: 442221834240,
          }
        }
      ]
    })
  end

  test "escaping field key" do
    ~S|disk_free working\ directories="C:\My Documents\Stuff for examples,C:\My Documents",value=442221834240i| = Line.to_line(%{
      points: [
        %{
          measurement: "disk_free",
          fields: %{
            "value" => 442221834240,
            "working directories" => ~S|C:\My Documents\Stuff for examples,C:\My Documents|
          }
        }
      ]
    })
  end

  test "showing all escaping and quoting together" do
    ~S|"measurement\ with\ quotes",tag\ key\ with\ spaces=tag\,value\,with"commas" field_key\\\\="string field value, only \" need be quoted"| = Line.to_line(%{
      points: [
        %{
          measurement: ~S|"measurement with quotes"|,
          tags: %{
            "tag key with spaces" => ~S|tag,value,with"commas"|
          },
          fields: %{
            ~S|field_key\\\\| => ~S|string field value, only " need be quoted|
          }
        }
      ]
    })
  end

end
