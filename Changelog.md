# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) (from 3.17.0 onwards)

## [Unreleased]

## v5.4.0

### Changed
* Now raises an error in Rails 7.0 when attempting to use ARS when `ActiveSupport::IsolatedExecutionState.isolation_level` is not set to `:thread`

### Fixed
* Stays on the correct database, even when using a new Fiber. Some Ruby methods, such as `to_enum` create a new Fiber for the block. `to_enum` is used by ActiveRecord when finding things in batches. This should resolve issues where ARS would connect to the unsharded database, even inside an `on_shard` block. The downside is we are now violating fiber concurrency and thus this breaks multi-fiber webservers.

* Fixes an issue where ARS switches to the replica database in the middle of a transaction when it is supposed to remain on the Primary.

## v5.3.3

### Added
* Added new 'ActiveRecordShards.reset_rails_env!' method to clear the cache within a process ([#315](https://github.com/zendesk/active_record_shards/pull/315)).

## v5.3.2

### Added
* Run tests against Ruby 3.2 (the gem actually already worked with Ruby 3.2, but now we _promise_ that it does) ([#309](https://github.com/zendesk/active_record_shards/pull/309)).
* Cache the results of `is_sharded?` and `app_env`, and ensure that the configuration is only validated once in `shard_names`. This should be a small performance improvement ([#311](https://github.com/zendesk/active_record_shards/pull/311), [#312](https://github.com/zendesk/active_record_shards/pull/312)).

## v5.3.1

### Added
Raises a new `LegacyConnectionHandlingError` exception when using ActiveRecord >= 6.1 and `legacy_connection_handling` is set to `false`.

## v5.3.0

### Fixed

Make connection switching thread safe, by fixing a thread safety issue caused by using a (class) instance variable instead of a thread-local variable.

## v5.2.0

### Added

Support for Rails 7.0 when `legacy_connection_handling` is set to `true`. This is required to [opt-out of the native Rails 6.1+ sharding support](https://guides.rubyonrails.org/active_record_multiple_databases.html).

### Fixed

Rails 6.1 deprecation warnings.

## v5.1.0

### Added

Support for Rails 6.1 when `legacy_connection_handling` is set to `true`. This is required to [opt-out of the native Rails 6.1 sharding support](https://guides.rubyonrails.org/active_record_multiple_databases.html).

## v5.0.0

### Changed

Rename `ActiveRecordShards.rails_env` to `ActiveRecordShards.app_env`, and include `APP_ENV` and `ENV['APP_ENV']` in the list of places it looks for environment information.

Removed support for Ruby 2.3, 2.4, and 2.5.

Removed support for Rails 4.2 and 5.0.

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

### Added

Add a global setting to disable marking instances from replicas as read-only. To enable:

`ActiveRecordShards.disable_replica_readonly_records = true`

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
