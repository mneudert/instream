# Changelog

## v0.10.0-dev

- Enhancements
  - Query builder can construct `CREATE DATABASE` statements
  - Query buidler can construct `CREATE RETENTION POLICY` statements
  - Query builder can construct `DROP DATABASE` statements
  - Query builder can construct `DROP RETENTION POLICY` statements
  - Query builder can construct `SHOW` statements

- Backwards incompatible changes
  - `:cluster` query type has been removed in favor of regular `:read` queries
  - Retention policy convenience function has been replaced with a more detailed version

## v0.9.0 (2015-12-27)

- Enhancements
  - Error messages are returned without leading/trailing whitespace
  - Experimental query builder
  - Incomplete or missing series definitions raise an error during compilation
  - Ping a connection using `Instream.Connection.ping/0`
  - Reading queries can be executed directly using `Instream.Connection.query/2`
  - Writing query can be executed directly using `Insream.Connection.write/2`

- Deprecations
  - Using `Instream.Data.Read` or `Instream.Data.Write` directly is discouraged and will eventually be removed

- Backwards incompatible changes
  - The measurement of a series is no longer optional
  - The parameter `opts` for `Instream.Data.Read` and `Instream.Data.Write` is no longer optional
  - `use`-ing `Instream.Series` without a complete series definition raises during compilation

## v0.8.0 (2015-11-18)

- Enhancements
  - Batch writing using `Line` and `UDP` writers ([#10](https://github.com/mneudert/instream/pull/10))
  - Fields can be defined with default values
  - Tags can be defined with default values
  - Writing can be done over UDP using `Instream.Writer.UDP`

## v0.7.0 (2015-10-22)

- Enhancements
  - Convenience module for "SHOW DIAGNOSTICS" queries
  - Convenience module for "SHOW STATS" queries
  - Precision (= epoch) can be passed to read queries
  - Precision can be passed to write queries

- Bug fixes
  - Pool configuration (size, overflow) is now properly taken from configuration

- Deprecations
  - Support of the JSON protocol is deprecated and will be removed with the InfluxDB 1.0 release

## v0.6.0 (2015-09-27)

- Enhancements
  - "IF NOT EXISTS" can be passed to database creation queries
  - Points can be written with explicit timestamps ([#8](https://github.com/mneudert/instream/pull/8))
  - Switched default write method to the line protocol
  - Tags are optional when writing with the line protocol

- Backwards incompatible changes
  - Switched default write method to the line protocol

## v0.5.0 (2015-09-05)

- Enhancements
  - Convenience module for "SHOW SERVERS" queries
  - Queries can be executed asynchronously
  - Support for line protocol

- Backwards incompatible changes
  - Write queries return `:ok` instead of `nil`

## v0.4.0 (2015-07-25)

- Enhancements
  - Allows using header authentication (basic auth)
  - Allows using pre-defined series modules for write queries
  - Provides a way to define series as a module (struct)

- Backwards incompatible changes
  - Authentication uses headers by default

## v0.3.0 (2015-06-19)

- Enhancements
  - Allows managing retention policies
  - Dependencies not used in production builds are marked as optional

- Bug fixes
  - Authentication is passed using query parameters by default

- Backwards incompatible changes
  - Auth configuration is now expected to be a `Keyword.t`
  - Queries of type `:host` are now of type `:cluster`
  - Remapped `Admin` namespace to `Cluster` to match query types

## v0.2.0 (2015-04-19)

- Enhancements
  - Allows accessing raw query results (undecoded binaries) using `Instream.Connection.execute/2`
  - Read queries (binaries) can be executed on a database
  - Write queries (map data) can be executed on a database

## v0.1.0 (2015-02-23)

- Initial Release
