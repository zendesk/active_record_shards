# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) (from 3.17.0 onwards)

## [Unreleased]

## v3.21.0

### Added

Add a global setting to disable marking instances from replicas as read-only. To enable:

`ActiveRecordShards.disable_replica_readonly_records = true`

## v3.20.0

### Changed

Rename `ActiveRecordShards.rails_env` to `ActiveRecordShards.app_env`, and include `APP_ENV` and `ENV['APP_ENV']` in the list of places it looks for environment information.

## v3.19.3

### Fixed

Fixed terrible performance when used with Rails 6.0 and having many shards defined in the database configuration.

## v3.19.2

### Fixed

Fix a bug when the given database configuration was already "exploded" with deprecated keys, e.g. `test_slave` or others ending with `_slave`.

## v3.19.1

### Fixed

Converts the `ActiveRecord::Base.configurations` object introduced in Rails 6 into a hash as expected.

## v3.19.0

### Changed / Fixed

Lots of improvements to the `on_replica_by_default` logic, now covered by an improved test suite. Schema loading should now _always_ happen on the replica databases, and non-mutating queries will should now happen on the replica except when `on_replica_by_default` is not configured.

## v3.18.0

### Changed / Deprecated

Adds deprecation warning for all methods containing `master`/`slave` which recommends using the updated `primary`/`replica` methods. The main public methods changed:

1. `on_slave` => `on_replica`
1. `on_master` => `on_primary`

other methods changed:

1. `on_master_if` => `on_primary_if`
1. `on_slave_if` => `on_replica_if`
1. `on_master_unless` => `on_primary_unless`
1. `on_slave_unless` => `on_replica_unless`
1. `on_master_or_slave` => `on_primary_or_replica`
1. `exists_with_default_slave` => `exists_with_default_replica`
1. `from_slave` => `from_replica`
1. `initialize_shard_and_slave` => `initialize_shard_and_replica`
1. `ShardSelection#options` no longer uses `:slave`, if this method was overridden ensure it returns `:replica` instead of `:slave`: `{ shard: .., replica: ... }`

SQL comments (see [debugging](/README.md#debugging)) will now log `... /* replica */` instead of `... /* slave */`
