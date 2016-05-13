# Changelog

## v0.12.0 (2015-05-13)

- Enhancements
    - Namespace of administrational convenience modules has been changed from
      `Cluster` to the better matching `Admin`

- Deprecations
    - Configuring a connection with multiple hosts has been deprecated.
      Instead of multiple `:hosts` only a single `:host` is now expected
    - The `Cluster` namespace of queries has been changed to `Admin`. For some
      backwards compatibility the old modules are delegated to the new ones
      until removed in the next release

- Backwards incompatible changes
    - Atoms for defining a series' database are no longer supported
    - Atoms for defining a series' measurement are no longer supported
    - Support for the JSON protocol has been removed matching its
      removal in InfluxDB v0.12.0
    - Support for the "SHOW SERVERS" statement has been removed matching
      its removal in InfluxDB v0.13.0

## v0.11.0 (2016-04-14)

- Enhancements
    - Hackney options can be configured
      ([#17](https://github.com/mneudert/instream/pull/17))
    - Line writer now prefers a database passed via arguments
      over the one passed in the datapoint payload
    - Logging for requests is available
    - Pings can be send to specific servers
    - Status requests can be send to a cluster

- Bug fixes
    - Series are now compiled with full environment information
      preventing "/path/to/lib/nofile" to be compiled as the
      source of `MySeries.Fields` or `MySeries.Tags`

- Backwards incompatible changes
    - Runtime connection configuration reading has been removed
      in favor of compile time inlining

## v0.10.0 (2016-02-27)

- Enhancements
    - Default precision (`:rfc3339`) can be explicitly set
    - Query builder can construct `CREATE DATABASE` statements
    - Query builder can construct `CREATE RETENTION POLICY` statements
    - Query builder can construct `DROP DATABASE` statements
    - Query builder can construct `DROP RETENTION POLICY` statements
    - Query builder can construct `SHOW` statements
    - Series database definitions allow anything "evaluating to a string"
      ([#14](https://github.com/mneudert/instream/pull/14))
    - Series measurement definitions allow anything "evaluating to a string"
      ([#14](https://github.com/mneudert/instream/pull/14))

- Deprecations
    - Atoms for defining a series' database are deprecated
    - Atoms for defining a series' measurement are deprecated
    - Using `if_not_exists` (`CREATE DATABASE`) has been deprecated and
      will be completely removed once InfluxDB removes it

- Backwards incompatible changes
    - `:cluster` query type has been removed in favor of regular `:read` queries
    - Retention policy convenience function has been replaced
      with a more detailed version

## v0.9.0 (2015-12-27)

- Enhancements
    - Error messages are returned without leading/trailing whitespace
    - Experimental query builder
    - Incomplete or missing series definitions raise an error during compilation
    - Ping a connection using `Instream.Connection.ping/0`
    - Reading queries can be executed directly using `Instream.Connection.query/2`
    - Writing query can be executed directly using `Insream.Connection.write/2`

- Deprecations
    - Using `Instream.Data.Read` or `Instream.Data.Write` directly is
      discouraged and will eventually be removed

- Backwards incompatible changes
    - The measurement of a series is no longer optional
    - The parameter `opts` for `Instream.Data.Read` and `Instream.Data.Write`
      is no longer optional
    - `use`-ing `Instream.Series` without a complete series definition
      raises during compilation

## v0.8.0 (2015-11-18)

- Enhancements
    - Batch writing using `Line` and `UDP` writers
      ([#10](https://github.com/mneudert/instream/pull/10))
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
    - Pool configuration (size, overflow) is now
      properly taken from configuration

- Deprecations
    - Support of the JSON protocol is deprecated and will be
      removed once InfluxDB removes it

## v0.6.0 (2015-09-27)

- Enhancements
    - "IF NOT EXISTS" can be passed to database creation queries
    - Points can be written with explicit timestamps
      ([#8](https://github.com/mneudert/instream/pull/8))
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
    - Allows accessing raw query results (undecoded binaries)
      using `Instream.Connection.execute/2`
    - Read queries (binaries) can be executed on a database
    - Write queries (map data) can be executed on a database

## v0.1.0 (2015-02-23)

- Initial Release
