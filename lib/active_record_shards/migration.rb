# frozen_string_literal: true
module ActiveRecord
  class Migrator
    def self.shards_migration_context
      if ActiveRecord::VERSION::MAJOR >= 6
        ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths, ActiveRecord::SchemaMigration)
      elsif ActiveRecord::VERSION::STRING >= '5.2.0'
        ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths)
      else
        self
      end
    end

    def initialize_with_sharding(*args)
      initialize_without_sharding(*args)

      # Rails creates the internal tables on the unsharded DB. We make them
      # manually on the sharded DBs.
      ActiveRecord::Base.on_all_shards do
        ActiveRecord::SchemaMigration.create_table
        if ActiveRecord::VERSION::MAJOR >= 5
          ActiveRecord::InternalMetadata.create_table
        end
      end
    end
    alias_method :initialize_without_sharding, :initialize
    alias_method :initialize, :initialize_with_sharding

    def run_with_sharding
      ActiveRecord::Base.on_shard(nil) { run_without_sharding }
      ActiveRecord::Base.on_all_shards { run_without_sharding }
    end
    alias_method :run_without_sharding, :run
    alias_method :run, :run_with_sharding

    def migrate_with_sharding
      ActiveRecord::Base.on_shard(nil) { migrate_without_sharding }
      ActiveRecord::Base.on_all_shards { migrate_without_sharding }
    end
    alias_method :migrate_without_sharding, :migrate
    alias_method :migrate, :migrate_with_sharding

    # don't allow Migrator class to cache versions
    undef migrated
    def migrated
      self.class.shards_migration_context.get_all_versions
    end

    # list of pending migrations is any migrations that haven't run on all shards.
    undef pending_migrations
    def pending_migrations
      pending, _missing = self.class.shard_status(migrations.map(&:version))
      pending = pending.values.flatten
      migrations.select { |m| pending.include?(m.version) }
    end

    # public
    # list of pending and missing versions per shard
    # [{1 => [1234567]}, {1 => [2345678]}]
    def self.shard_status(versions)
      pending = {}
      missing = {}

      collect = lambda do |shard|
        migrated = shards_migration_context.get_all_versions

        p = versions - migrated
        pending[shard] = p if p.any?

        m = migrated - versions
        missing[shard] = m if m.any?
      end

      ActiveRecord::Base.on_shard(nil) { collect.call(nil) }
      ActiveRecord::Base.on_all_shards { |shard| collect.call(shard) }

      [pending, missing]
    end
  end
end

module ActiveRecordShards
  module MigrationClassExtension
    attr_accessor :migration_shard

    def shard(arg = nil)
      self.migration_shard = arg
    end
  end

  module ActualMigrationExtension
    def migrate_with_forced_shard(direction)
      if migration_shard.blank?
        raise "#{name}: Can't run migrations without a shard spec: this may be :all, :none,
                 or a specific shard (for data-fixups).  please call shard(arg) in your migration."
      end

      shard = ActiveRecord::Base.current_shard_selection.shard

      if shard.nil?
        return if migration_shard != :none
      else
        return if migration_shard == :none
        return if migration_shard != :all && migration_shard.to_s != shard.to_s
      end

      migrate_without_forced_shard(direction)
    end

    def migration_shard
      self.class.migration_shard
    end
  end
end

ActiveRecord::Migration.class_eval do
  extend ActiveRecordShards::MigrationClassExtension
  include ActiveRecordShards::ActualMigrationExtension

  alias_method :migrate_without_forced_shard, :migrate
  alias_method :migrate, :migrate_with_forced_shard
end

ActiveRecord::MigrationProxy.delegate :migration_shard, to: :migration
