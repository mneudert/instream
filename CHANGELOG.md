# Changelog

## v0.4.0-dev

- Enhancements
  - Allows using header authentication (basic auth)

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
