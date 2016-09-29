defmodule Instream.Query.URLTest do
  use ExUnit.Case, async: true

  alias Instream.Query.URL


  test "append epoch (read precision)" do
    precision = :millisecond
    url       = "http://localhost/query"
    expected  = "#{ url }?epoch=ms"

    assert expected == URL.append_epoch(url, precision)

    url      = "#{ url }?foo=bar"
    expected = "#{ url }&epoch=ms"

    assert expected == URL.append_epoch(url, precision)
  end

  test "append precision" do
    precision = :millisecond
    url       = "http://localhost/query"
    expected  = "#{ url }?precision=ms"

    assert expected == URL.append_precision(url, precision)

    url      = "#{ url }?foo=bar"
    expected = "#{ url }&precision=ms"

    assert expected == URL.append_precision(url, precision)
  end

  test "rfc3339 == default precision (not in url)" do
    precision = :rfc3339
    url       = "http://localhost/query"

    assert url == URL.append_precision(url, precision)
  end

  test "append query" do
    query    = "SHOW DATABASES"
    url      = "http://localhost/query"
    expected = "#{ url }?q=#{ URI.encode query }"

    assert expected == URL.append_query(url, query)

    url      = "#{ url }?foo=bar"
    expected = "#{ url }&q=#{ URI.encode query }"

    assert expected == URL.append_query(url, query)
  end


  test "ping url with specific host" do
    url  = "http://specific.host/ping"
    conn = [
      host:   "localhost",
      scheme: "http"
    ]

    refute url == URL.ping(conn)
    assert url == URL.ping(conn, "specific.host")
  end


  test "query url" do
    url  = "http://localhost:8086/query?u=root&p=root"
    conn = [
      auth:   [ method: :query, username: "root", password: "root" ],
      host:   "localhost",
      port:   8086,
      scheme: "http",
    ]

    assert url == URL.query(conn)
  end

  test "query url with basic authentication" do
    url  = "http://localhost/query"
    conn = [
      auth:   [ method: :basic, username: "root", password: "root" ],
      host:   "localhost",
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end

  test "query url with default authentication" do
    url  = "http://localhost/query"
    conn = [
      auth:   [ username: "root", password: "root" ],
      host:   "localhost",
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end

  test "query url without credentials" do
    url  = "http://localhost:8086/query"
    conn = [
      host:   "localhost",
      port:   8086,
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end

  test "query url without port" do
    url  = "http://localhost/query?u=root&p=root"
    conn = [
      auth:   [ method: :query, username: "root", password: "root" ],
      host:   "localhost",
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end

  test "query with partial credentials" do
    url  = "http://localhost/query?u=root"
    conn = [
      auth:   [ method: :query, username: "root" ],
      host:   "localhost",
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end


  test "status url with speicifc host" do
    url  = "http://specific.host/status"
    conn = [
      host:   "localhost",
      scheme: "http"
    ]

    refute url == URL.status(conn)
    assert url == URL.status(conn, "specific.host")
  end
end
