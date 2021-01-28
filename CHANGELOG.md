# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) (from 3.17.0 onwards)

## [Unreleased]

### Changed

[Deprecation] Adds deprecation warning for all methods containing `master`/`slave` which recommends using the updated `primary`/`replica` methods. The main public methods changed:

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
