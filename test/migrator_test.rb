# frozen_string_literal: true
require_relative 'helper'

describe ActiveRecord::Migrator do
  with_phenix

  before { ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym) }

  it "migrates" do
    migration_path = File.join(File.dirname(__FILE__), "/migrations")

    refute ActiveRecord::Base.current_shard_id
    ActiveRecord::Migrator.migrate(migration_path)

    ActiveRecord::Base.on_all_shards do
      assert ActiveRecord::Base.connection.data_source_exists?(:schema_migrations), "Schema Migrations doesn't exist"
      assert ActiveRecord::Base.connection.data_source_exists?(:tickets)
      refute ActiveRecord::Base.connection.data_source_exists?(:accounts)
      assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110824010216'")
      assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110829215912'")
    end

    ActiveRecord::Base.on_all_shards do
      assert table_has_column?("tickets", "sharded_column")
    end

    ActiveRecord::Base.on_shard(nil) do
      assert table_has_column?("accounts", "non_sharded_column")
    end

    # now test down/ up
    ActiveRecord::Migrator.run(:down, migration_path, 20110824010216)
    ActiveRecord::Base.on_all_shards do
      assert !table_has_column?("tickets", "sharded_column")
    end

    ActiveRecord::Migrator.run(:down, migration_path, 20110829215912)
    ActiveRecord::Base.on_shard(nil) do
      assert !table_has_column?("accounts", "non_sharded_column")
    end

    ActiveRecord::Migrator.run(:up, migration_path, 20110824010216)
    ActiveRecord::Base.on_all_shards do
      assert table_has_column?("tickets", "sharded_column")
    end

    ActiveRecord::Migrator.run(:up, migration_path, 20110829215912)
    ActiveRecord::Base.on_shard(nil) do
      assert table_has_column?("accounts", "non_sharded_column")
    end
  end

  it "does not migrate bad migrations" do
    migration_path = File.join(File.dirname(__FILE__), "/cowardly_migration")
    assert_raises StandardError do
      ActiveRecord::Migrator.migrate(migration_path)
    end
  end

  it "fails with failing migrations" do
    # like, if you have to break a migration in the middle somewhere.
    migration_path = File.join(File.dirname(__FILE__), "/failure_migration")

    assert failure_migration_pending?(migration_path)
    begin
      ActiveRecord::Migrator.migrate(migration_path)
    rescue
      # after first fail, should still be pending
      assert failure_migration_pending?(migration_path)
      retry
    end

    assert !failure_migration_pending?(migration_path)
    ActiveRecord::Base.on_all_shards do
      assert table_has_column?("tickets", "sharded_column")
    end
  end

  describe "#shard_status" do
    it "shows nothing if everything is ok" do
      ActiveRecord::Migrator.shard_status([1]).must_equal([{}, {}])
    end

    it "shows missing migrations" do
      ActiveRecord::Migrator.shard_status([]).must_equal([{}, { nil => [1], "0" => [1], "1" => [1] }])
    end

    it "shows pending migrations" do
      ActiveRecord::Migrator.shard_status([1, 2]).must_equal([{ nil => [2], "0" => [2], "1" => [2] }, {}])
    end
  end

  private

  def failure_migration_pending?(migration_path)
    migrations = ActiveRecord::Migrator.migrations(migration_path)
    ActiveRecord::Migrator.new(:up, migrations).pending_migrations.detect { |f| f.name == "FailureMigration" }
  end
end
