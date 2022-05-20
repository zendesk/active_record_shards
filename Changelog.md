# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) (from 3.17.0 onwards)

## [Unreleased]

### Changes related to Rails 6.1

Load_schema from replica. Not built into Rails 6.1. Consider using schema_cache (from file) instead, or make a separate new gem with on_replica patches.

Probably we should start using the schema caching feature (setting schema_cache_path) and remove the patches for loading schema etc. from replica.

Inform people about the three-layer db configuration. Change zendesk_configuration to provide this new db config format.

Inform people to make an abstract superclass for all models connecting to the same group of databases. E.g. a superclass for “non-sharded” models (connecting to the Accounts db) and a superclass for “sharded” models (connecting to the “everything else” db). One of them must be named `ApplicationRecord` (Was this changed after 6.1?)

Inform people that you can no longer set default_shard to nil. Inform people that you should no longer set default_shard on ActiveRecord::Base, but instead on your sharded superclass model.

You can no longer switch connection to one database and "leave it there". You switch connection inside a block, which will automatically switch you "back" to ... somewhere.


When switching shard, ARS will by default connect to the replica (or the primary? Decisions...)


Should we split the gem into a couple of gems, each handling different parts of Zendesk-specific database setup?

1. Don't connect to "accounts db" writer on boot.
2. Read schema from replica.
3. "on replica by default"



### Changed

Removed support for Ruby 2.3 and 2.4.

Removed support for Rails 4.2

[Deprecation] Removes all deprecated methods containing `master`/`slave`. Use the updated `primary`/`replica` methods instead. The main public methods changed:

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

Also removes the class `ActiveRecordShards::Deprecation`.

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
