defmodule Instream.Query.URLTest do
  use ExUnit.Case, async: true

  alias Instream.Query.URL

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
      auth:   [ username: "root", password: "root" ],
      hosts:  [ "localhost" ],
      port:   8086,
      scheme: "http",
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
      auth:   [ username: "root", password: "root" ],
      hosts:  [ "localhost" ],
      scheme: "http"
    ]

    assert url == URL.query(conn)
  end
end
