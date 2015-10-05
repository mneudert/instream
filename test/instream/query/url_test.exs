defmodule Instream.Query.URLTest do
  use ExUnit.Case, async: true

  alias Instream.Query.URL


  test "append precision" do
    precision = :milli_seconds
    url       = "http://localhost/query"
    expected  = "#{ url }?epoch=ms"

    assert expected == URL.append_precision(url, precision)

    url      = "#{ url }?foo=bar"
    expected = "#{ url }&epoch=ms"

    assert expected == URL.append_precision(url, precision)
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


  test "query url" do
    url  = "http://localhost:8086/query?u=root&p=root"
    conn = [
      auth:   [ method: :query, username: "root", password: "root" ],
      hosts:  [ "localhost" ],
      port:   8086,
      scheme: "http",
    ]

    assert url == URL.query(conn)
  end

  test "query url with basic authentication" do
    url  = "http://localhost/query"
    conn = [
      auth:   [ method: :basic, username: "root", password: "root" ],
      hosts:  [ "localhost" ],
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end

  test "query url with default authentication" do
    url  = "http://localhost/query"
    conn = [
      auth:   [ username: "root", password: "root" ],
      hosts:  [ "localhost" ],
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end

  test "query url without credentials" do
    url  = "http://localhost:8086/query"
    conn = [
      hosts:  [ "localhost" ],
      port:   8086,
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end

  test "query url without port" do
    url  = "http://localhost/query?u=root&p=root"
    conn = [
      auth:   [ method: :query, username: "root", password: "root" ],
      hosts:  [ "localhost" ],
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end

  test "query with partial credentials" do
    url  = "http://localhost/query?u=root"
    conn = [
      auth:   [ method: :query, username: "root" ],
      hosts:  [ "localhost" ],
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end
end
