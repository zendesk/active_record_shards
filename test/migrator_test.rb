require File.expand_path('helper', File.dirname(__FILE__))

class CowardlyMigration < ActiveRecord::Migration
  def self.up
    "not gonna happen"
  end

  def self.down
    "uh uh"
  end
end

class MigratorTest < ActiveSupport::TestCase
  def setup
    init_schema
  end

  def test_migrator
    migration_path = File.join(File.dirname(__FILE__), "/migrations")
    ActiveRecord::Migrator.migrate(migration_path)
    ActiveRecord::Base.on_all_shards do
      assert ActiveRecord::Base.connection.table_exists?(:schema_migrations), "Schema Migrations doesn't exist"
      assert ActiveRecord::Base.connection.table_exists?(:accounts)
      assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110824010216'")
      assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110829215912'")
    end

    ActiveRecord::Base.on_all_shards do
      assert table_has_column?("emails", "sharded_column")
      assert !table_has_column?("accounts", "non_sharded_column")
    end

    ActiveRecord::Base.on_shard(nil) do
      assert !table_has_column?("emails", "sharded_column")
      assert table_has_column?("accounts", "non_sharded_column")
    end

    # now test down/ up
    ActiveRecord::Migrator.run(:down, migration_path, 20110824010216)
    ActiveRecord::Base.on_all_shards do
      assert !table_has_column?("emails", "sharded_column")
    end

    ActiveRecord::Migrator.run(:down, migration_path, 20110829215912)
    ActiveRecord::Base.on_shard(nil) do
      assert !table_has_column?("accounts", "non_sharded_column")
    end

    ActiveRecord::Migrator.run(:up, migration_path, 20110824010216)
    ActiveRecord::Base.on_all_shards do
      assert table_has_column?("emails", "sharded_column")
    end

    ActiveRecord::Migrator.run(:up, migration_path, 20110829215912)
    ActiveRecord::Base.on_shard(nil) do
      assert table_has_column?("accounts", "non_sharded_column")
    end
  end

  def test_bad_migration
    begin
      CowardlyMigration.up
    rescue Exception => e
      assert_match /CowardlyMigration/, e.message
    end

    assert_raises(RuntimeError) do
      CowardlyMigration.up
    end

    assert_raises(RuntimeError) do
      CowardlyMigration.down
    end
  end

  def test_failing_migration
    # like, if you have to break a migration in the middle somewhere.
    begin
      migration_path = File.join(File.dirname(__FILE__), "/failure_migration")
      ActiveRecord::Migrator.migrate(migration_path)
    rescue
      retry
    end

    ActiveRecord::Base.on_all_shards do
      assert table_has_column?("tickets", "sharded_column")
    end
  end

  private
  def table_has_column?(table, column)
    ActiveRecord::Base.connection.select_value("show create table #{table}") =~ /#{column}/
  end
end
