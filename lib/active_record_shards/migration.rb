# frozen_string_literal: true
module ActiveRecordShards
  module MigratorExtension
    def initialize(*)
      super
      # Rails makes these only on the shared DB
      # Making them manually for shards
      ActiveRecord::Base.on_all_shards do
        if ActiveRecord::VERSION::MAJOR > 3
          ActiveRecord::SchemaMigration.create_table
        else
          ActiveRecord::Base.connection.initialize_schema_migrations_table
        end
        if ActiveRecord::VERSION::MAJOR >= 5
          ActiveRecord::InternalMetadata.create_table
        end
      end
    end

    def run
      ActiveRecord::Base.on_all_databases { super }
    end

    def migrate
      ActiveRecord::Base.on_all_databases { super }
    end

    # don't allow Migrator class to cache versions
    def migrated
      self.class.shards_migration_context.get_all_versions
    end

    # list of pending migrations is any migrations that haven't run on all shards.
    def pending_migrations
      pending, _missing = self.class.shard_status(migrations.map(&:version))
      pending = pending.values.flatten
      migrations.select { |m| pending.include?(m.version) }
    end

    module ClassMethods
      # public
      # list of pending and missing versions per shard
      # [{1 => [1234567]}, {1 => [2345678]}]
      def shard_status(versions)
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

      def shards_migration_context
        if ActiveRecord::VERSION::STRING >= '5.2.0'
          ActiveRecord::MigrationContext.new(['db/migrate'])
        else
          self
        end
      end
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
ActiveRecord::Migrator.prepend(ActiveRecordShards::MigratorExtension)
ActiveRecord::Migrator.extend(ActiveRecordShards::MigratorExtension::ClassMethods)

ActiveRecord::Migration.class_eval do
  extend ActiveRecordShards::MigrationClassExtension
  include ActiveRecordShards::ActualMigrationExtension

  alias_method :migrate_without_forced_shard, :migrate
  alias_method :migrate, :migrate_with_forced_shard
end

ActiveRecord::MigrationProxy.delegate :migration_shard, to: :migration
