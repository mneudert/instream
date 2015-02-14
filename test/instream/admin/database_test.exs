defmodule Instream.Admin.DatabaseTest do
  use ExUnit.Case, async: true

  alias Instream.Admin.Database

  @database "test_database"

  test "create database" do
    query = Database.create(@database)

    assert query.query == "CREATE DATABASE #{ @database }"
  end

  test "drop database" do
    query = Database.drop(@database)

    assert query.query == "DROP DATABASE #{ @database }"
  end

  test "show databases" do
    query = Database.show()

    assert query.query == "SHOW DATABASES"
  end
end
