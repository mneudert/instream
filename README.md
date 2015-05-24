# Instream

InfluxDB driver for Elixir


## Warning

__This module is highly experimental at the moment and may behave or change unexpectedly.__


## Setup

Add Instream as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [ { :instream, "~> 0.2" } ]
end
```


## Usage

### Connections

Defining a connection requires defining a module:

```elixir
defmodule MyApp.MyConnection do
  use Instream.Connection, otp_app: :my_app
end
```

The `:otp_app` name and the name of the module can be freely chosen.
They only need to be linked to an entry in your `config.exs`:

```elixir
config :my_app, MyApp.MyConnection,
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http"
```

You now have a connection definition you can hook into your supervision tree:

```elixir
Supervisor.start_link(
  [ MyApp.MyConnection.child_spec ],
  strategy: :one_for_one
)
```

### Administrative Queries

Managing Databases:

```elixir
# create "my_database"
"my_database"
|> Instream.Admin.Database.create()
|> MyApp.MyConnection.create()

# drop "my_database"
"my_database"
|> Instream.Admin.Database.drop()
|> MyApp.MyConnection.execute()
```

### Data Queries

Writing data:

```elixir
%{
  database: "my_database",
  points: [
    %{
      name:   "some_measurement",
      fields: %{ value: 0.66 }
    }
  ]
}
|> Instream.Data.Write.query()
|> MyApp.MyConnection.execute()
```

Reading data:

```elixir
# passing database to execute/1
"SELECT * FROM some_measurement"
|> Instream.Data.Read.query()
|> MyApp.MyConnection.execute(database: "my_database")

# defining database in the query
"SELECT * FROM \"my_database\".\"default\".\"some_measurement\""
|> Instream.Data.Read.query()
|> MyApp.MyConnection.execute()
```


## License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
