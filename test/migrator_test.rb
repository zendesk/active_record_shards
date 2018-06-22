# frozen_string_literal: true
require_relative 'helper'

describe ActiveRecord::Migrator do
  with_phenix

  before { ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym) }

  describe "when DB is empty" do
    # Using env without slave
    # because cleanup all DBs and recreate only master
    # There is no real reprica so slave doesn't catch up
    switch_rails_env('test3')
    before do
      ActiveRecord::Base.on_all_databases do
        if ActiveRecord::VERSION::MAJOR == 5 && ActiveRecord::VERSION::MINOR.zero?
          ActiveSupport::Deprecation.behavior = :silence
        end
        ActiveRecord::Base.connection.tables.each do |table|
          ActiveRecord::Base.connection.drop_table(table)
        end
      end
    end
    it "makes meta tables" do
      migrator.migrate
      ActiveRecord::Base.on_all_shards do
        assert table_exists?(:schema_migrations), "Schema Migrations doesn't exist"
        assert table_exists?(:tickets)
        refute table_exists?(:accounts)
        assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110824010216'")
        assert ActiveRecord::Base.connection.select_value("select version from schema_migrations where version = '20110829215912'")
      end
    end
  end

  it "migrates" do
    refute ActiveRecord::Base.current_shard_id

    migrator.migrate

    ActiveRecord::Base.on_all_shards do
      assert table_exists?(:schema_migrations), "Schema Migrations doesn't exist"
      assert table_exists?(:tickets)
      refute table_exists?(:accounts)
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
    migrator(:down, 'migrations', 20110824010216).run
    ActiveRecord::Base.on_all_shards do
      assert !table_has_column?("tickets", "sharded_column")
    end

    migrator(:down, 'migrations', 20110829215912).run
    ActiveRecord::Base.on_shard(nil) do
      assert !table_has_column?("accounts", "non_sharded_column")
    end

    migrator(:up, 'migrations', 20110824010216).run
    ActiveRecord::Base.on_all_shards do
      assert table_has_column?("tickets", "sharded_column")
    end

    migrator(:up, 'migrations', 20110829215912).run
    ActiveRecord::Base.on_shard(nil) do
      assert table_has_column?("accounts", "non_sharded_column")
    end
  end

  it "does not migrate bad migrations" do
    assert_raises StandardError do
      migrator(:up, 'cowardly_migration').migrate
    end
  end

  it "fails with failing migrations" do
    # like, if you have to break a migration in the middle somewhere.
    assert failure_migration_pending?('failure_migration')
    begin
      migrator(:up, 'failure_migration').migrate
    rescue => e
      unless e.message.include?("ERROR_IN_MIGRATION")
        raise e
      end
      # after first fail, should still be pending
      assert failure_migration_pending?('failure_migration')
      retry
    end

    assert !failure_migration_pending?('failure_migration')
    ActiveRecord::Base.on_all_shards do
      assert table_has_column?("tickets", "sharded_column")
    end
  end

  describe "#shard_status" do
    it "shows nothing if everything is ok" do
      ActiveRecord::Migrator.shard_status([1]).must_equal([{}, {}])
    end

    it "shows missing migrations" do
      ActiveRecord::Migrator.shard_status([]).must_equal([{}, { nil => [1], 0 => [1], 1 => [1] }])
    end

    it "shows pending migrations" do
      ActiveRecord::Migrator.shard_status([1, 2]).must_equal([{ nil => [2], 0 => [2], 1 => [2] }, {}])
    end
  end

  private

  def failure_migration_pending?(migration_path)
    migrator(:up, migration_path).pending_migrations.detect { |f| f.name == "FailureMigration" }
  end
end
