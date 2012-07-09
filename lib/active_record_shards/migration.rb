module ActiveRecord
  class Migrator
    class << self
      [:up, :down, :run].each do |m|
        define_method("#{m}_with_sharding") do |*args|
          ActiveRecord::Base.on_shard(nil) do
            self.send("#{m}_without_sharding", *args)
          end
          ActiveRecord::Base.on_all_shards do
            self.send("#{m}_without_sharding", *args)
          end
        end
        alias_method_chain m.to_sym, :sharding
      end

      def bootstrap_migrations_from_nil_shard(migrations_path, this_migration=nil)
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
    def migrated
      self.class.get_all_versions
    end

    # list of pending migrations is any migrations that haven't run on all shards.
    def pending_migrations
      migration_counts = Hash.new(0)
      ActiveRecord::Base.on_shard(nil) do
        migrated.each { |v| migration_counts[v] += 1 }
      end

      shard_count = 1
      ActiveRecord::Base.on_all_shards do
        migrated.each { |v| migration_counts[v] += 1 }
        shard_count += 1
      end

      migrations.select do |m|
        count = migration_counts[m.version]
        count.nil? || count < shard_count
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

  # ok, so some 'splaining to do.  Rails 3.1 puts the migrate() method on the instance of the
  # migration, where it should have been.  But this makes our monkey patch incompatible.
  # So we're forced to *either* include or extend this.
  module ActualMigrationExtension
    def migrate_with_forced_shard(direction)
      if migration_shard.blank?
        raise RuntimeError, "#{self.name}: Can't run migrations without a shard spec: this may be :all, :none,
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
  end
end

ActiveRecord::Migration.class_eval do
  extend ActiveRecordShards::MigrationClassExtension

  if ActiveRecord::VERSION::STRING >= "3.1.0"
    include ActiveRecordShards::ActualMigrationExtension
    define_method :migration_shard do
      self.class.migration_shard
    end
    alias_method_chain :migrate, :forced_shard
  else
    extend ActiveRecordShards::ActualMigrationExtension
    class << self
      alias_method_chain :migrate, :forced_shard
    end
  end
end

ActiveRecord::MigrationProxy.delegate :migration_shard, :to => :migration
