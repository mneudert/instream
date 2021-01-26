defmodule Instream.Connection.BucketOrgTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.0"

  alias Instream.TestHelpers.Connections.DefaultConnection

  defmodule InvalidConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        bucket: "invalid_test_bucket",
        org: "instream_test",
        loggers: [],
        version: :v2
      ]
  end

  defmodule DefaultSeries do
    use Instream.Series

    series do
      measurement "bucket_org_config_series"

      tag :foo, default: :bar

      field :value, default: 100
    end
  end

  setup_all do
    conn_env = Application.get_env(:instream, InvalidConnection, [])

    Application.put_env(
      :instream,
      InvalidConnection,
      Keyword.merge(
        conn_env,
        auth: DefaultConnection.config(:auth)
      )
    )
  end

  test "read || opts bucket/org has priority over connection bucket/org" do
    bucket = "bucket_org_config_optsdb_test"
    opts = [bucket: bucket, org: "instream_test"]

    %{error: message} = InvalidConnection.query("SELECT value FROM #{bucket}", opts)

    assert String.contains?(message, "could not find bucket")
    assert String.contains?(message, bucket)
  end

  test "write || default: bucket/org from connection" do
    %{code: "not found", message: message} = InvalidConnection.write(%DefaultSeries{})

    assert String.contains?(message, InvalidConnection.config(:bucket))
  end

  test "write || opts bucket/org has priority over connection bucket/org" do
    bucket = "bucket_org_config_optsdb_test"
    opts = [bucket: bucket, org: "instream_test"]

    %{code: "not found", message: message} = DefaultConnection.write(%DefaultSeries{}, opts)

    assert String.contains?(message, bucket)
  end
end
