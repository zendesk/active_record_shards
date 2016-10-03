# frozen_string_literal: true
module ActiveRecord
  class Migrator
    class << self
      [:up, :down, :run].each do |m|
        define_method("#{m}_with_sharding") do |*args|
          ActiveRecord::Base.on_shard(nil) do
            send("#{m}_without_sharding", *args)
          end
          ActiveRecord::Base.on_all_shards do
            send("#{m}_without_sharding", *args)
          end
        end
        alias_method :"#{m}_without_sharding", m.to_sym
        alias_method m.to_sym, :"#{m}_with_sharding"
      end

      def bootstrap_migrations_from_nil_shard(migrations_path, this_migration = nil)
        migrations = nil
        ActiveRecord::Base.on_shard(nil) do
          migrations = ActiveRecord::Migrator.new(:up, migrations_path).migrated
        end

        puts "inserting #{migrations.size} migrations on all shards..."
        ActiveRecord::Base.on_all_shards do
          migrator = ActiveRecord::Migrator.new(:up, migrations_path)
          migrations.each do |m|
            migrator.__send__(:record_version_state_after_migrating, m)
          end
          if this_migration
            migrator.__send__(:record_version_state_after_migrating, this_migration)
          end
        end
      end
    end

    # don't allow Migrator class to cache versions
    undef migrated
    def migrated
      self.class.get_all_versions
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
        migrated = get_all_versions

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

  # ok, so some 'splaining to do.  Rails 3.1 puts the migrate() method on the instance of the
  # migration, where it should have been.  But this makes our monkey patch incompatible.
  # So we're forced to *either* include or extend this.
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
