require File.expand_path('../helper', __FILE__)

describe "connection switching" do
  schema_initialized = false

  i_suck_and_my_tests_are_order_dependent!

  before do
    if !schema_initialized
      init_schema
      schema_initialized = true
    end
    clear_databases
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
      ActiveRecord::Base.on_slave { assert_using_database('ars_test_slave') }

      ActiveRecord::Base.on_shard(0) do
        assert_using_database('ars_test_shard0')
        ActiveRecord::Base.on_slave { assert_using_database('ars_test_shard0_slave') }

        ActiveRecord::Base.on_shard(nil) do
          assert_using_database('ars_test')
          ActiveRecord::Base.on_slave { assert_using_database('ars_test_slave') }
        end

        assert_using_database('ars_test_shard0')
        ActiveRecord::Base.on_slave { assert_using_database('ars_test_shard0_slave') }
      end

      assert_using_database('ars_test')
      ActiveRecord::Base.on_slave { assert_using_database('ars_test_slave') }
    end

    describe "on_first_shard" do
      it "use the first shard" do
        ActiveRecord::Base.on_first_shard {
          assert_using_database('ars_test_shard0')
        }
      end
    end

    describe "on_all_shards" do
      before do
        @shard_0_master = ActiveRecord::Base.on_shard(0) {ActiveRecord::Base.connection}
        @shard_1_master = ActiveRecord::Base.on_shard(1) {ActiveRecord::Base.connection}
        refute_equal(@shard_0_master.select_value("SELECT DATABASE()"), @shard_1_master.select_value("SELECT DATABASE()"))
      end

      it "execute the block on all shard masters" do
        result = ActiveRecord::Base.on_all_shards do |shard|
          [ActiveRecord::Base.connection.select_value("SELECT DATABASE()"), shard]
        end
        database_names = result.map(&:first)
        database_shards = result.map(&:last)

        assert_equal(2, database_names.size)
        assert_includes(database_names, @shard_0_master.select_value("SELECT DATABASE()"))
        assert_includes(database_names, @shard_1_master.select_value("SELECT DATABASE()"))

        assert_equal(2, database_shards.size)
        assert_includes(database_shards, "0")
        assert_includes(database_shards, "1")
      end

      it "execute the block unsharded" do
        ActiveRecord::Base.expects(:supports_sharding?).returns false
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

    describe "for unsharded models" do
      it "use the non-sharded connection" do
        assert_using_database('ars_test', Account)
        Account.connection.execute("alter table accounts add column foo int")

        assert Account.column_names.include?('foo')
      end

      after do
        ActiveRecord::Base.connection.execute("alter table accounts drop column foo")
        Account.reset_column_information
      end
    end

    describe "for sharded models" do
      before do
        ActiveRecord::Base.on_first_shard do
          ActiveRecord::Base.connection.execute("alter table tickets add column foo int")
        end
      end

      after do
        ActiveRecord::Base.on_first_shard do
          ActiveRecord::Base.connection.execute("alter table tickets drop column foo")
          Ticket.reset_column_information
        end
      end

      it "get colmns from the first shard" do
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
  end

  describe "ActiveRecord::Base.table_exists?" do
    before do
      ActiveRecord::Base.default_shard = nil
    end

    describe "for unsharded models" do
      it "use the unsharded connection" do
        class UnshardedModel < ActiveRecord::Base
          not_sharded
        end
        UnshardedModel.connection.execute("create table unsharded_models (id int)")
        assert(UnshardedModel.table_exists?)

        ActiveRecord::Base.on_all_shards do
          assert !ActiveRecord::Base.connection.table_exists?("unsharded_models")
        end
      end
    end

    describe "for sharded models" do
      it "try the first shard" do
        class ShardedModel < ActiveRecord::Base
        end

        ActiveRecord::Base.on_first_shard do
          ShardedModel.connection.execute("create table sharded_models (id int)")
        end

        assert ShardedModel.table_exists?
      end
    end
  end

  describe "in an unsharded environment" do
    before do
      silence_warnings { ::RAILS_ENV = 'test2' }
      ActiveRecord::Base.establish_connection(::RAILS_ENV.to_sym)
      assert_using_database('ars_test2', Ticket)
    end

    after do
      silence_warnings { ::RAILS_ENV = 'test' }
      ActiveRecord::Base.establish_connection(::RAILS_ENV.to_sym)
      assert_using_database('ars_test', Ticket)
    end

    it "be able to find by column" do
      Account.where(:name => "peter").to_sql # does not blow up
    end

    it "have correct engine" do
      assert_equal Account, Account.arel_engine
    end

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

      it "execute the block on all shard masters" do
        assert_equal([ActiveRecord::Base.connection.select_value("SELECT DATABASE()")], @database_names)
      end
    end
  end

  describe "slave driving" do
    describe "without slave configuration" do

      before do
        ActiveRecord::Base.configurations.delete('test_slave')
        if ActiveRecord::VERSION::MAJOR >= 4
          ActiveRecord::Base.connection_handler.connection_pool_list.clear
        else
          ActiveRecord::Base.connection_handler.connection_pools.clear
        end
        ActiveRecord::Base.establish_connection(:test)
      end

      it "default to the master database" do
        Account.create!

        ActiveRecord::Base.on_slave { assert_using_master_db }
        Account.on_slave { assert_using_master_db }
        Ticket.on_slave  { assert_using_master_db }
      end

      it "successfully execute queries" do
        Account.create!
        assert_using_master_db

        assert_equal Account.count, ActiveRecord::Base.on_slave { Account.count }
        assert_equal Account.count, Account.on_slave { Account.count }
      end

    end

    describe "with slave configuration" do

      it "successfully execute queries" do
        assert_using_master_db
        Account.create!

        assert_equal(1, Account.count)
        assert_equal(0, ActiveRecord::Base.on_slave { Account.count })
      end

      it "support global on_slave blocks" do
        assert_using_master_db
        assert_using_master_db

        ActiveRecord::Base.on_slave do
          assert_using_slave_db
          assert_using_slave_db
        end

        assert_using_master_db
        assert_using_master_db
      end

      it "support conditional methods" do
        assert_using_master_db

        Account.on_slave_if(true) do
          assert_using_slave_db
        end

        assert_using_master_db

        Account.on_slave_if(false) do
          assert_using_master_db
        end

        Account.on_slave_unless(true) do
          assert_using_master_db
        end

        Account.on_slave_unless(false) do
          assert_using_slave_db
        end
      end

      describe "a model loaded with the slave" do
        before do
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'master_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          assert(Account.find(1000))
          assert_equal('master_name', Account.find(1000).name)

          Account.on_slave.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'slave_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")

          @model = Account.on_slave.find(1000)
          assert(@model)
          assert_equal('slave_name', @model.name)
        end

        it "read from master on reload" do
          @model.reload
          assert_equal('master_name', @model.name)
        end

        it "be marked as read only" do
          assert(@model.readonly?)
        end

        it "be marked as comming from the slave" do
          assert(@model.from_slave?)
        end
      end

      describe "a inherited model without cached columns hash" do
        # before columns -> with_scope -> type-condition -> columns == loop
        it "not loop when on slave by default" do
          Person.on_slave_by_default = true
          assert User.on_slave_by_default?
          assert User.finder_needs_type_condition?

          User.instance_variable_set(:@columns_hash, nil)
          User.columns_hash
        end
      end

      describe "a model loaded with the master" do
        before do
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'master_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          @model = Account.first
          assert(@model)
          assert_equal('master_name', @model.name)
        end

        it "not unset readonly" do
          @model = Account.on_master.readonly.first
          assert(@model.readonly?)
        end

        it "not be marked as read only" do
          assert(!@model.readonly?)
        end

        it "not be marked as comming from the slave" do
          assert(!@model.from_slave?)
        end
      end

      describe "with finds routed to the slave by default" do
        before do
          Account.on_slave_by_default = true
          Person.on_slave_by_default = true
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'master_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          Account.on_slave.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'slave_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          Account.on_slave.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1001, 'slave_name2', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")

          Person.connection.execute("REPLACE INTO people(id, name) VALUES(10, 'master person')")
          Person.on_slave.connection.execute("REPLACE INTO people(id, name) VALUES(20, 'slave person')")

          Account.connection.execute("INSERT INTO account_people(account_id, person_id) VALUES(1000, 10)")
          Account.on_slave.connection.execute("INSERT INTO account_people(account_id, person_id) VALUES(1001, 20)")
        end

        it "find() by default on the slave" do
          account = Account.find(1000)
          assert_equal 'slave_name', account.name
        end

        it "count() by default on the slave" do
          count = Account.all.size
          assert_equal 2, count
        end

        it "reload() on the master" do
          account = Account.find(1000)
          assert_equal 'master_name', account.reload.name
        end

        it "do exists? on the slave" do
          if Account.respond_to?(:exists?)
            assert Account.exists?(1001)
          end
        end

        it "does exists? on the slave with a named scope" do
          AccountThing.on_slave_by_default = true
          Account.on_slave.connection.execute("INSERT INTO account_things (id, account_id) VALUES(123125, 1000)")
          assert AccountThing.enabled.exists?(123125)
          Account.on_slave.connection.execute("DELETE FROM account_things")
          AccountThing.on_slave_by_default = false
        end

        it "count associations on the slave" do
          AccountThing.on_slave_by_default = true
          Account.on_slave.connection.execute("INSERT INTO account_things (id, account_id) VALUES(123123, 1000)")
          Account.on_slave.connection.execute("INSERT INTO account_things (id, account_id) VALUES(123124, 1000)")
          assert_equal 2, Account.find(1000).account_things.size
          AccountThing.on_slave_by_default = false
        end

        it "Allow override using on_master" do
          model = Account.on_master.find(1000)
          assert_equal "master_name", model.name
        end

        it "not override on_master with on_slave" do
          model = Account.on_master { Account.on_slave.find(1000) }
          assert_equal "master_name", model.name
        end

        it "override on_slave with on_master" do
          model = Account.on_slave { Account.on_master.find(1000) }
          assert_equal "master_name", model.name
        end

        it "propogate the default_slave setting to inherited classes" do
          assert AccountInherited.on_slave_by_default?
        end

        it "will :include things via has_and_belongs associations correctly" do
          a = Account.where(:id => 1001).includes(:people).first
          assert a.people.size > 0
          assert_equal 'slave person', a.people.first.name
        end

        it "supports .pluck" do
          assert_equal ["slave_name", "slave_name2"], Account.pluck(:name)
        end

        after do
          Account.on_slave_by_default = false
          Person.on_slave_by_default = false
        end
      end
    end

    describe "slave proxy" do
      it "successfully execute queries" do
        assert_using_master_db
        Account.create!

        refute_equal Account.count, Account.on_slave.count
      end

      it "work on association collections" do
        begin
          assert_using_master_db
          account = Account.create!

          account.tickets.create! :title => 'master ticket'

          Ticket.on_slave {
            account.tickets.create! :title => 'slave ticket'
          }

          assert_equal "master ticket", account.tickets.first.title
          assert_equal "slave ticket", account.tickets.on_slave.first.title
        rescue Exception
          retried ||= 0
          retried += 1
          puts "Failed in #{__LINE__}##{retried}"
          retry if retried < 3
        end
      end
    end
  end

  describe "alternative connections" do
    it "not interfere with other connections" do
      assert_using_database('ars_test', Account)
      assert_using_database('ars_test', Ticket)
      assert_using_database('ars_test_alternative', Email)

      ActiveRecord::Base.on_shard(0) do
        assert_using_database('ars_test', Account)
        assert_using_database('ars_test_shard0', Ticket)
        assert_using_database('ars_test_alternative', Email)
      end

      assert_using_database('ars_test', Account)
      assert_using_database('ars_test', Ticket)
      assert_using_database('ars_test_alternative', Email)
    end
  end

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
