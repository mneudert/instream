defmodule Instream.Query.URLTest do
  use ExUnit.Case, async: true

  alias Instream.Query.URL

  test "append epoch (read precision)" do
    precision = :millisecond
    url = "http://localhost/query"
    expected = "#{url}?epoch=ms"

    assert ^expected = URL.append_epoch(url, precision)

    url = "#{url}?foo=bar"
    expected = "#{url}&epoch=ms"

    assert ^expected = URL.append_epoch(url, precision)
  end

  test "append query" do
    query = ~s(SELECT "value" FROM "foo&bar?baz")
    url = "http://localhost/query"
    expected = "#{url}?q=SELECT+%22value%22+FROM+%22foo%26bar%3Fbaz%22"

    assert ^expected = URL.append_query(url, query)

    url = "#{url}?foo=bar"
    expected = "#{url}&q=SELECT+%22value%22+FROM+%22foo%26bar%3Fbaz%22"

    assert ^expected = URL.append_query(url, query)
  end

  test "query url" do
    url = "http://localhost:8086/query?u=root&p=root"

    conn = [
      auth: [method: :query, username: "root", password: "root"],
      host: "localhost",
      port: 8086,
      scheme: "http",
      version: :v1
    ]

    assert ^url = URL.query(conn, query_language: :influxql)
  end

  test "query url for flux" do
    url = "http://localhost:8086/api/v2/query?u=root&p=root"

    conn = [
      auth: [method: :query, username: "root", password: "root"],
      host: "localhost",
      port: 8086,
      scheme: "http",
      version: :v1
    ]

    assert ^url = URL.query(conn, query_language: :flux)
  end

  test "query url with basic authentication" do
    url = "http://localhost/query"

    conn = [
      auth: [method: :basic, username: "root", password: "root"],
      host: "localhost",
      scheme: "http",
      version: :v1
    ]

    assert ^url = URL.query(conn, query_language: :influxql)
  end

  test "query url with default authentication" do
    url = "http://localhost/query"

    conn = [
      auth: [username: "root", password: "root"],
      host: "localhost",
      scheme: "http",
      version: :v1
    ]

    assert ^url = URL.query(conn, query_language: :influxql)
  end

  test "query url without credentials" do
    url = "http://localhost:8086/query"

    conn = [
      host: "localhost",
      port: 8086,
      scheme: "http",
      version: :v1
    ]

    assert ^url = URL.query(conn, query_language: :influxql)
  end

  test "query url without port" do
    url = "http://localhost/query?u=root&p=root"

    conn = [
      auth: [method: :query, username: "root", password: "root"],
      host: "localhost",
      scheme: "http",
      version: :v1
    ]

    assert ^url = URL.query(conn, query_language: :influxql)
  end

  test "query with partial credentials" do
    url = "http://localhost/query?u=root"

    conn = [
      auth: [method: :query, username: "root"],
      host: "localhost",
      scheme: "http",
      version: :v1
    ]

    assert ^url = URL.query(conn, query_language: :influxql)
  end
end
