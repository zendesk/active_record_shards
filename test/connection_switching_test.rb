# frozen_string_literal: true
require_relative 'helper'

describe "connection switching" do
  def clear_connection_pool
    if ActiveRecord::VERSION::MAJOR >= 4
      ActiveRecord::Base.connection_handler.connection_pool_list.clear
    else
      ActiveRecord::Base.connection_handler.connection_pools.clear
    end
  end

  with_phenix

  before do
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    require 'models'
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

    it "does not fail on unrelated ensure error when current_shard_selection fails" do
      ActiveRecord::Base.expects(:current_shard_selection).raises(ArgumentError)
      assert_raises ArgumentError do
        ActiveRecord::Base.on_replica { 1 }
      end
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

      it "execute the block on all shard primarys" do
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

    describe ".shards.enum" do
      it "works like this:" do
        ActiveRecord::Base.on_all_shards { Ticket.create! }
        count = ActiveRecord::Base.shards.enum.map { Ticket.count }.inject(&:+)
        assert_equal(ActiveRecord::Base.shard_names.size, count)
      end
    end

    describe ".shards.find" do
      it "works like this:" do
        t = ActiveRecord::Base.on_shard(1) { Ticket.create! }
        assert(Ticket.shards.find(t.id))

        assert_raises(ActiveRecord::RecordNotFound) do
          Ticket.shards.find(123123123)
        end
      end
    end

    describe ".shards.count" do
      before do
        ActiveRecord::Base.on_shard(0) { 2.times { Ticket.create!(title: "0") } }
        ActiveRecord::Base.on_shard(1) { Ticket.create!(title: "1") }
      end

      it "works like this:" do
        count = Ticket.shards.count
        assert_equal(3, count)
      end

      it "works with scopes" do
        assert_equal(1, Ticket.where(title: "1").shards.count)
      end
    end

    describe ".shards.to_a" do
      it "works like this" do
        ActiveRecord::Base.on_all_shards { |s| Ticket.create!(title: s.to_s) }

        res = Ticket.where(title: "1").shards.to_a
        assert_equal 1, res.size
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

    describe "for unsharded models" do
      before do
        Account.on_replica do
          Account.connection.execute("alter table accounts add column foo int")
          Account.reset_column_information
        end
      end

      after do
        Account.on_replica do
          ActiveRecord::Base.connection.execute("alter table accounts drop column foo")
          Account.reset_column_information
          refute Account.column_names.include?('foo')
        end
      end

      it "use the non-sharded replica connection" do
        assert_using_database('ars_test', Account)
        assert Account.column_names.include?('foo')
      end

      it "ignores primary/transactions" do
        assert_using_database('ars_test', Account)
        Account.on_primary { assert Account.column_names.include?('foo') }
      end
    end

    describe "for sharded models" do
      before do
        ActiveRecord::Base.on_first_shard do
          ActiveRecord::Base.on_replica do
            ActiveRecord::Base.connection.execute("alter table tickets add column foo int")
            Ticket.reset_column_information
          end
        end
      end

      after do
        ActiveRecord::Base.on_first_shard do
          ActiveRecord::Base.on_replica do
            ActiveRecord::Base.connection.execute("alter table tickets drop column foo")
            Ticket.reset_column_information
          end
        end
      end

      it "gets columns from the replica shard" do
        assert Ticket.column_names.include?('foo')
      end

      it "have correct from_shard" do
        ActiveRecord::Base.on_all_shards do |shard|
          assert_equal shard, Ticket.new.from_shard
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

    if ActiveRecord::VERSION::MAJOR >= 5
      describe "for InternalMetadata" do
        before do
          ActiveRecord::InternalMetadata.on_replica do
            ActiveRecord::InternalMetadata.connection.execute("alter table ar_internal_metadata add column foo int")
            ActiveRecord::InternalMetadata.reset_column_information
          end
        end

        after do
          ActiveRecord::InternalMetadata.on_replica do
            ActiveRecord::Base.connection.execute("alter table ar_internal_metadata drop column foo")
            ActiveRecord::InternalMetadata.reset_column_information
            refute ActiveRecord::InternalMetadata.column_names.include?('foo')
          end
        end

        it "use the non-sharded replica connection" do
          assert_using_database('ars_test', ActiveRecord::InternalMetadata)
          assert ActiveRecord::InternalMetadata.column_names.include?('foo')
        end

        it "ignores primary/transactions" do
          assert_using_database('ars_test', ActiveRecord::InternalMetadata)
          ActiveRecord::InternalMetadata.on_primary { assert ActiveRecord::InternalMetadata.column_names.include?('foo') }
        end
      end
    end
  end

  describe "ActiveRecord::Base.table_exists?" do
    before do
      ActiveRecord::Base.default_shard = nil
    end

    describe "for unsharded models" do
      it "use the unsharded replica connection" do
        class UnshardedModel < ActiveRecord::Base
          not_sharded
        end

        UnshardedModel.on_replica { UnshardedModel.connection.execute("create table unsharded_models (id int)") }
        assert UnshardedModel.table_exists?

        ActiveRecord::Base.on_all_shards do
          refute ActiveRecord::Base.connection.public_send(connection_exist_method, "unsharded_models")
        end
      end
    end

    describe "for sharded models" do
      it "uses the first shard replica" do
        class ShardedModel < ActiveRecord::Base
        end

        ActiveRecord::Base.on_first_shard do
          ShardedModel.on_replica do
            ShardedModel.connection.execute("create table sharded_models (id int)")
          end
        end

        assert ShardedModel.table_exists?
      end
    end
  end

  describe "in an environment without replica" do
    switch_rails_env('test3')
    def spec_name
      ActiveRecord::Base.connection_pool.spec.name
    end

    describe "shard switching" do
      it "just stay on the primary db" do
        if ActiveRecord::VERSION::MAJOR >= 5
          main_spec_name = spec_name
          shard_spec_name = ActiveRecord::Base.on_shard(0) { spec_name }
        end
        ActiveRecord::Base.on_replica do
          assert_using_database('ars_test3', Account)
          if ActiveRecord::VERSION::MAJOR >= 5
            assert_equal main_spec_name, spec_name
          end

          ActiveRecord::Base.on_shard(0) do
            assert_using_database('ars_test3_shard0', Ticket)
            if ActiveRecord::VERSION::MAJOR >= 5
              assert_equal shard_spec_name, spec_name
            end
          end
        end
      end
    end
  end

  describe "in an unsharded environment" do
    switch_rails_env('test2')

    describe "shard switching" do
      it "just stay on the main db" do
        assert_using_database('ars_test2', Ticket)
        assert_using_database('ars_test2', Account)

        ActiveRecord::Base.on_shard(0) do
          assert_using_database('ars_test2', Ticket)
          assert_using_database('ars_test2', Account)
        end
      end
    end

    describe "on_all_shards" do
      before do
        @database_names = []
        ActiveRecord::Base.on_all_shards do
          @database_names << ActiveRecord::Base.connection.select_value("SELECT DATABASE()")
        end
      end

      it "execute the block on all shard primarys" do
        assert_equal([ActiveRecord::Base.connection.select_value("SELECT DATABASE()")], @database_names)
      end
    end
  end

  describe "replica driving" do
    describe "without replica configuration" do
      before do
        @saved_config = ActiveRecord::Base.configurations.delete('test_replica')
        Thread.current[:shard_selection] = nil # drop caches
        clear_connection_pool
        ActiveRecord::Base.establish_connection(:test)
      end

      after do
        ActiveRecord::Base.configurations['test_replica'] = @saved_config
        Thread.current[:shard_selection] = nil # drop caches
      end

      it "default to the primary database" do
        Account.create!

        ActiveRecord::Base.on_replica { assert_using_primary_db }
        Account.on_replica { assert_using_primary_db }
        Ticket.on_replica  { assert_using_primary_db }
      end

      it "successfully execute queries" do
        Account.create!
        assert_using_primary_db

        assert_equal(Account.count, ActiveRecord::Base.on_replica { Account.count })
        assert_equal(Account.count, Account.on_replica { Account.count })
      end
    end

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

      describe "a model loaded with the replica" do
        before do
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'primary_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          assert(Account.find(1000))
          assert_equal('primary_name', Account.find(1000).name)

          Account.on_replica.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'replica_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")

          @model = Account.on_replica.find(1000)
          assert(@model)
          assert_equal('replica_name', @model.name)
        end

        it "read from primary on reload" do
          @model.reload
          assert_equal('primary_name', @model.name)
        end

        it "be marked as read only" do
          if ActiveRecord::VERSION::STRING >= '4.2.0'
            skip("Readonly scope on finder method is complicated on Rails 4.2")
          end

          assert(@model.readonly?)
        end

        it "be marked as comming from the replica" do
          assert(@model.from_replica?)
        end
      end

      describe "a inherited model without cached columns hash" do
        # before columns -> with_scope -> type-condition -> columns == loop
        it "not loop when on replica by default" do
          Person.on_replica_by_default = true
          assert User.on_replica_by_default?
          assert User.finder_needs_type_condition?

          User.instance_variable_set(:@columns_hash, nil)
          User.columns_hash
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

        it "not be marked as comming from the replica" do
          assert(!@model.from_replica?)
        end
      end

      describe "with finds routed to the replica by default" do
        before do
          Account.on_replica_by_default = true
          Person.on_replica_by_default = true
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'primary_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          Account.on_replica.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'replica_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          Account.on_replica.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1001, 'replica_name2', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")

          Person.connection.execute("REPLACE INTO people(id, name) VALUES(10, 'primary person')")
          Person.on_replica.connection.execute("REPLACE INTO people(id, name) VALUES(20, 'replica person')")

          Account.connection.execute("INSERT INTO account_people(account_id, person_id) VALUES(1000, 10)")
          Account.on_replica.connection.execute("INSERT INTO account_people(account_id, person_id) VALUES(1001, 20)")
        end

        it "find() by default on the replica" do
          account = Account.find(1000)
          assert_equal 'replica_name', account.name
        end

        it "count() by default on the replica" do
          count = Account.all.size
          assert_equal 2, count
        end

        it "reload() on the primary" do
          account = Account.find(1000)
          assert_equal 'primary_name', account.reload.name
        end

        it "do exists? on the replica" do
          if Account.respond_to?(:exists?)
            assert Account.exists?(1001)
          end
        end

        it "does exists? on the replica with a named scope" do
          AccountThing.on_replica_by_default = true
          Account.on_replica.connection.execute("INSERT INTO account_things (id, account_id) VALUES(123125, 1000)")
          assert AccountThing.enabled.exists?(123125)
          Account.on_replica.connection.execute("DELETE FROM account_things")
          AccountThing.on_replica_by_default = false
        end

        it "count associations on the replica" do
          AccountThing.on_replica_by_default = true
          Account.on_replica.connection.execute("INSERT INTO account_things (id, account_id) VALUES(123123, 1000)")
          Account.on_replica.connection.execute("INSERT INTO account_things (id, account_id) VALUES(123124, 1000)")
          assert_equal 2, Account.find(1000).account_things.size
          AccountThing.on_replica_by_default = false
        end

        it "Allow override using on_primary" do
          model = Account.on_primary.find(1000)
          assert_equal "primary_name", model.name
        end

        it "not override on_primary with on_replica" do
          model = Account.on_primary { Account.on_replica.find(1000) }
          assert_equal "primary_name", model.name
        end

        it "override on_replica with on_primary" do
          model = Account.on_replica { Account.on_primary.find(1000) }
          assert_equal "primary_name", model.name
        end

        it "propogate the on_replica_by_default reader to inherited classes" do
          assert AccountInherited.on_replica_by_default?
        end

        it "is false on ActiveRecord::Base" do
          refute ActiveRecord::Base.on_replica_by_default?
        end

        it "propogate the on_replica_by_default writer to inherited classes" do
          begin
            AccountInherited.on_replica_by_default = false
            refute AccountInherited.on_replica_by_default?
            refute Account.on_replica_by_default?
          ensure
            AccountInherited.on_replica_by_default = true
          end
        end

        it "refuses to set on ActiveRecord::Base" do
          assert_raises ArgumentError do
            ActiveRecord::Base.on_replica_by_default = true
          end
        end

        it "will :include things via has_and_belongs associations correctly" do
          a = Account.where(id: 1001).includes(:people).first
          refute a.people.empty?
          assert_equal 'replica person', a.people.first.name
        end

        it "sets up has and belongs to many sharded-ness correctly" do
          if ActiveRecord::VERSION::MAJOR >= 4
            refute Account.const_get(:HABTM_People).is_sharded?
          end
        end

        it "supports .pluck" do
          assert_equal ["replica_name", "replica_name2"], Account.pluck(:name)
        end

        it "supports implicit joins" do
          accounts = Account.includes(:account_things)
          accounts = accounts.references(:account_things) if ActiveRecord::VERSION::MAJOR >= 4
          assert_equal ["replica_name", "replica_name2"], accounts.order('account_things.id').map(&:name).sort
        end

        it "supports joins" do
          accounts = Account.joins('LEFT OUTER JOIN account_things ON account_things.account_id = accounts.id').map(&:name).sort
          assert_equal ["replica_name", "replica_name2"], accounts
        end

        it "does not support implicit joins between an unsharded and a sharded table" do
          accounts = Account.includes(:tickets).order('tickets.id')
          accounts = accounts.references(:tickets) if ActiveRecord::VERSION::MAJOR >= 4
          assert_raises(ActiveRecord::StatementInvalid) { accounts.first }
        end

        it "does not support explicit joins between an unsharded and a sharded table" do
          accounts = Account.joins('LEFT OUTER JOIN tickets ON tickets.account_id = accounts.id')
          assert_raises(ActiveRecord::StatementInvalid) { accounts.first }
        end

        after do
          Account.on_replica_by_default = false
          Person.on_replica_by_default = false
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

        ActiveRecord::Base.on_shard(0) do
          account.tickets.create! title: 'primary ticket'

          Ticket.on_replica do
            account.tickets.create! title: 'replica ticket'
          end

          assert_equal "primary ticket", account.tickets.first.title
          assert_equal "replica ticket", account.tickets.on_replica.first.title
        end
      end
    end
  end

  if ActiveRecord::VERSION::MAJOR < 5

    it "raises an exception if a connection is not found" do
      ActiveRecord::Base.on_shard(0) do
        ActiveRecord::Base.connection_handler.remove_connection(Ticket)
        assert_raises(ActiveRecord::ConnectionNotEstablished) do
          ActiveRecord::Base.connection_handler.retrieve_connection_pool(Ticket)
          assert_using_database('ars_test_shard0', Ticket)
        end
      end
    end

  end
end
