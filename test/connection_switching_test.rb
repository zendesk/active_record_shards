# frozen_string_literal: true

require_relative 'helper'
require 'active_record_shards/configuration'

describe "connection switching" do
  include ConnectionSwitchingSpecHelpers

  def clear_connection_pool
    ActiveRecord::Base.connection_handler.connection_pool_list.clear
  end

  with_fresh_databases

  before do
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    require 'models'
    ActiveRecordShards::Configuration.shard_id_map = {
      0 => :shard_0,
      1 => :shard_1
    }
  end

  after do
    ActiveRecordShards::Configuration.shard_id_map = nil
    ActiveRecord::Base.instance_variable_set(:@shard_names, nil)
  end

  describe "on_primary_db" do
    after do
      ActiveRecord::Base.default_shard = nil
    end

    it "switches to the primary database" do
      ActiveRecord::Base.on_primary_db do
        assert_using_database('ars_test')
      end
    end

    it "switches to the primary database and back when a default shard is set" do
      ActiveRecord::Base.default_shard = 0
      assert_using_database('ars_test_shard0')

      ActiveRecord::Base.on_primary_db do
        assert_using_database('ars_test')
      end

      assert_using_database('ars_test_shard0')
    end

    it "switches to the primary datatbase and back when nested of an on_shard block" do
      ActiveRecord::Base.on_shard(1) do
        assert_using_database('ars_test_shard1')

        ActiveRecord::Base.on_primary_db do
          assert_using_database('ars_test')
        end

        assert_using_database('ars_test_shard1')
      end
    end
  end

  describe "shard switching" do
    it "only switch connection on sharded models" do
      assert_using_database('ars_test', Ticket)
      assert_using_database('ars_test', Account)

      ActiveRecord::Base.on_shard(0) do
        assert_using_database('ars_test_shard0', Ticket)
        assert_using_database('ars_test', Account)
      end
    end

    it "switch to shard and back" do
      assert_using_database('ars_test')
      ActiveRecord::Base.on_replica { assert_using_database('ars_test_replica') }

      ActiveRecord::Base.on_shard(0) do
        assert_using_database('ars_test_shard0')
        ActiveRecord::Base.on_replica { assert_using_database('ars_test_shard0_replica') }

        ActiveRecord::Base.on_shard(nil) do
          assert_using_database('ars_test')
          ActiveRecord::Base.on_replica { assert_using_database('ars_test_replica') }
        end

        assert_using_database('ars_test_shard0')
        ActiveRecord::Base.on_replica { assert_using_database('ars_test_shard0_replica') }
      end

      assert_using_database('ars_test')
      ActiveRecord::Base.on_replica { assert_using_database('ars_test_replica') }
    end

    describe "on_first_shard" do
      it "use the first shard" do
        ActiveRecord::Base.on_first_shard do
          assert_using_database('ars_test_shard0')
        end
      end
    end

    describe "on_all_shards" do
      before do
        @shard_0_primary = ActiveRecord::Base.on_shard(0) { ActiveRecord::Base.connection }
        @shard_1_primary = ActiveRecord::Base.on_shard(1) { ActiveRecord::Base.connection }
        refute_equal(@shard_0_primary.select_value("SELECT DATABASE()"), @shard_1_primary.select_value("SELECT DATABASE()"))
      end

      it "execute the block on all shard primaries" do
        result = ActiveRecord::Base.on_all_shards do |shard|
          [ActiveRecord::Base.connection.select_value("SELECT DATABASE()"), shard]
        end
        database_names = result.map(&:first)
        database_shards = result.map(&:last)

        assert_equal(2, database_names.size)
        assert_includes(database_names, @shard_0_primary.select_value("SELECT DATABASE()"))
        assert_includes(database_names, @shard_1_primary.select_value("SELECT DATABASE()"))

        assert_equal(2, database_shards.size)
        assert_includes(database_shards, 0)
        assert_includes(database_shards, 1)
      end

      it "execute the block unsharded" do
        ActiveRecord::Base.expects(:supports_sharding?).at_least_once.returns false
        result = ActiveRecord::Base.on_all_shards do |shard|
          [ActiveRecord::Base.connection.select_value("SELECT DATABASE()"), shard]
        end
        assert_equal [["ars_test", nil]], result
      end
    end
  end

  describe "default shard selection" do
    describe "of nil" do
      before do
        ActiveRecord::Base.default_shard = nil
      end

      it "use unsharded db for sharded models" do
        assert_using_database('ars_test', Ticket)
        assert_using_database('ars_test', Account)
      end
    end

    describe "value" do
      before do
        ActiveRecord::Base.default_shard = 0
      end

      after do
        ActiveRecord::Base.default_shard = nil
      end

      it "use default shard db for sharded models" do
        assert_using_database('ars_test_shard0', Ticket)
        assert_using_database('ars_test', Account)
      end

      it "still be able to switch to shard nil" do
        ActiveRecord::Base.on_shard(nil) do
          assert_using_database('ars_test', Ticket)
          assert_using_database('ars_test', Account)
        end
      end
    end
  end

  describe "ActiveRecord::Base.columns" do
    before do
      ActiveRecord::Base.default_shard = nil
    end

    describe "for sharded models" do
      before do
        DbHelper.execute_sql("test", "shard_0_replica", "alter table tickets add column foo int")
        ActiveRecord::Base.on_first_shard do
          ActiveRecord::Base.on_replica do
            Ticket.reset_column_information
          end
        end
      end

      after do
        DbHelper.execute_sql("test", "shard_0_replica", "alter table tickets drop column foo")
        ActiveRecord::Base.on_first_shard do
          ActiveRecord::Base.on_replica do
            Ticket.reset_column_information
          end
        end
      end
    end

    describe "for SchemaMigration" do
      before do
        ActiveRecord::Base.on_shard(nil) do
          ActiveRecord::Base.connection.execute("alter table schema_migrations add column foo int")
        end
      end

      after do
        ActiveRecord::Base.on_shard(nil) do
          ActiveRecord::Base.connection.execute("alter table schema_migrations drop column foo")
        end
      end

      it "doesn't switch to shard" do
        table_has_column?('schema_migrations', 'foo')
      end
    end
  end

  describe "replica driving" do
    describe "with replica configuration" do
      it "successfully execute queries" do
        assert_using_primary_db
        Account.create!

        assert_equal(1, Account.count)
        assert_equal(0, ActiveRecord::Base.on_replica { Account.count })
      end

      it "support global on_replica blocks" do
        assert_using_primary_db
        assert_using_primary_db

        ActiveRecord::Base.on_replica do
          assert_using_replica_db
          assert_using_replica_db
        end

        assert_using_primary_db
        assert_using_primary_db
      end

      it "support conditional methods" do
        assert_using_primary_db

        Account.on_replica_if(true) do
          assert_using_replica_db
        end

        assert_using_primary_db

        Account.on_replica_if(false) do
          assert_using_primary_db
        end

        Account.on_replica_unless(true) do
          assert_using_primary_db
        end

        Account.on_replica_unless(false) do
          assert_using_replica_db
        end
      end

      describe "a model loaded with the primary" do
        before do
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'primary_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          @model = Account.first
          assert(@model)
          assert_equal('primary_name', @model.name)
        end

        it "not unset readonly" do
          @model = Account.on_primary.readonly.first
          assert(@model.readonly?)
        end

        it "not be marked as read only" do
          assert(!@model.readonly?)
        end
      end
    end

    describe "replica proxy" do
      it "successfully execute queries" do
        assert_using_primary_db
        Account.create!

        refute_equal Account.count, Account.on_replica.count
      end

      it "work on association collections" do
        assert_using_primary_db
        account = Account.create!

        DbHelper.execute_sql("test", "shard_0", "INSERT INTO tickets (id, title, account_id, created_at, updated_at) VALUES (50000, 'primary ticket', #{account.id}, NOW(), NOW())")
        DbHelper.execute_sql("test", "shard_0_replica", "INSERT INTO tickets (id, title, account_id, created_at, updated_at) VALUES (50000, 'replica ticket', #{account.id}, NOW(), NOW())")

        ActiveRecord::Base.on_shard(0) do
          assert_equal "primary ticket", account.tickets.first.title
          assert_equal "replica ticket", account.tickets.on_replica.first.title
        end
      end
    end
  end
end
