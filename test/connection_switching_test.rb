require File.expand_path('helper', File.dirname(__FILE__))

class ConnectionSwitchingTest < ActiveSupport::TestCase
  context "shard switching" do
    should "only switch connection on sharded models" do
      assert_using_database('ars_test', Ticket)
      assert_using_database('ars_test', Account)

      ActiveRecord::Base.on_shard(0) do
        assert_using_database('ars_test_shard0', Ticket)
        assert_using_database('ars_test', Account)
      end
    end

    should "switch to shard and back" do
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

    context "on_first_shard" do
      should "use the first shard" do
        ActiveRecord::Base.on_first_shard {
          assert_using_database('ars_test_shard0')
        }
      end
    end

    context "on_all_shards" do
      setup do
        @shard_0_master = ActiveRecord::Base.on_shard(0) {ActiveRecord::Base.connection}
        @shard_1_master = ActiveRecord::Base.on_shard(1) {ActiveRecord::Base.connection}
        assert_not_equal(@shard_0_master.select_value("SELECT DATABASE()"), @shard_1_master.select_value("SELECT DATABASE()"))

        @database_names = []
        @database_shards = []
        ActiveRecord::Base.on_all_shards do |shard|
          @database_names << ActiveRecord::Base.connection.select_value("SELECT DATABASE()")
          @database_shards << shard
        end
      end

      should "execute the block on all shard masters" do
        assert_equal(2, @database_names.size)
        assert_contains(@database_names, @shard_0_master.select_value("SELECT DATABASE()"))
        assert_contains(@database_names, @shard_1_master.select_value("SELECT DATABASE()"))
        assert_equal(2, @database_shards.size)
        assert_contains(@database_shards, "0")
        assert_contains(@database_shards, "1")
      end
    end
  end

  context "default shard selection" do
    context "of nil" do
      setup do
        ActiveRecord::Base.default_shard = nil
      end

      should "use unsharded db for sharded models" do
        assert_using_database('ars_test', Ticket)
        assert_using_database('ars_test', Account)
      end
    end

    context "value" do
      setup do
        ActiveRecord::Base.default_shard = 0
      end

      teardown do
        ActiveRecord::Base.default_shard = nil
      end

      should "use default shard db for sharded models" do
        assert_using_database('ars_test_shard0', Ticket)
        assert_using_database('ars_test', Account)
      end

      should "still be able to switch to shard nil" do
        ActiveRecord::Base.on_shard(nil) do
          assert_using_database('ars_test', Ticket)
          assert_using_database('ars_test', Account)
        end
      end
    end
  end

  context "ActiveRecord::Base.columns" do
    setup do
      ActiveRecord::Base.default_shard = nil
    end

    context "for unsharded models" do
      should "use the non-sharded connection" do
        assert_using_database('ars_test', Account)
        Account.connection.execute("alter table accounts add column foo int")

        assert Account.column_names.include?('foo')
      end

      teardown do
        ActiveRecord::Base.connection.execute("alter table accounts drop column foo")
        Account.reset_column_information
      end
    end

    context "for sharded models" do
      setup do
        ActiveRecord::Base.on_first_shard do
          ActiveRecord::Base.connection.execute("alter table tickets add column foo int")
        end
      end

      teardown do
        ActiveRecord::Base.on_first_shard do
          ActiveRecord::Base.connection.execute("alter table tickets drop column foo")
          Ticket.reset_column_information
        end
      end

      should "get colmns from the first shard" do
        assert Ticket.column_names.include?('foo')
      end
    end
  end

  context "ActiveRecord::Base.table_exists?" do
    setup do
      ActiveRecord::Base.default_shard = nil
    end

    context "for unsharded models" do
      should "use the unsharded connection" do
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

    context "for sharded models" do
      should "try the first shard" do
        class ShardedModel < ActiveRecord::Base
        end

        ActiveRecord::Base.on_first_shard do
          ShardedModel.connection.execute("create table sharded_models (id int)")
        end

        assert ShardedModel.table_exists?
      end
    end
  end

  context "in an unsharded environment" do
    setup do
      silence_warnings { ::RAILS_ENV = 'test2' }
      ActiveRecord::Base.establish_connection(::RAILS_ENV)
      assert_using_database('ars_test2', Ticket)
    end

    teardown do
      silence_warnings { ::RAILS_ENV = 'test' }
      ActiveRecord::Base.establish_connection(::RAILS_ENV)
      assert_using_database('ars_test', Ticket)
    end

    context "shard switching" do
      should "just stay on the main db" do
        assert_using_database('ars_test2', Ticket)
        assert_using_database('ars_test2', Account)

        ActiveRecord::Base.on_shard(0) do
          assert_using_database('ars_test2', Ticket)
          assert_using_database('ars_test2', Account)
        end
      end
    end

    context "on_all_shards" do
      setup do
        @database_names = []
        ActiveRecord::Base.on_all_shards do
          @database_names << ActiveRecord::Base.connection.select_value("SELECT DATABASE()")
        end
      end

      should "execute the block on all shard masters" do
        @database_names
        assert_equal([ActiveRecord::Base.connection.select_value("SELECT DATABASE()")], @database_names)
      end
    end
  end

  context "slave driving" do
    context "without slave configuration" do

      setup do
        ActiveRecord::Base.configurations.delete('test_slave')
        ActiveRecord::Base.connection_handler.connection_pools.clear
        ActiveRecord::Base.establish_connection('test')
      end

      should "default to the master database" do
        Account.create!

        ActiveRecord::Base.on_slave { assert_using_master_db }
        Account.on_slave { assert_using_master_db }
        Ticket.on_slave  { assert_using_master_db }
      end

      should "successfully execute queries" do
        Account.create!
        assert_using_master_db

        assert_equal Account.count, ActiveRecord::Base.on_slave { Account.count }
        assert_equal Account.count, Account.on_slave { Account.count }
      end

    end

    context "with slave configuration" do

      should "successfully execute queries" do
        assert_using_master_db
        Account.create!

        assert_equal(1, Account.count)
        assert_equal(0, ActiveRecord::Base.on_slave { Account.count })
      end

      should "support global on_slave blocks" do
        assert_using_master_db
        assert_using_master_db

        ActiveRecord::Base.on_slave do
          assert_using_slave_db
          assert_using_slave_db
        end

        assert_using_master_db
        assert_using_master_db
      end

      should "support conditional methods" do
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

      context "a model loaded with the slave" do
        setup do
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'master_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          assert(Account.find(1000))
          assert_equal('master_name', Account.find(1000).name)

          Account.on_slave.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'slave_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")

          @model = Account.on_slave.find(1000)
          assert(@model)
          assert_equal('slave_name', @model.name)
        end

        should "read from master on reload" do
          @model.reload
          assert_equal('master_name', @model.name)
        end

        should "be marked as read only" do
          assert(@model.readonly?)
        end

        should "be marked as comming from the slave" do
          assert(@model.from_slave?)
        end
      end

      context "a model loaded with the master" do
        setup do
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'master_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          @model = Account.first
          assert(@model)
          assert_equal('master_name', @model.name)
        end

        should "not be marked as read only" do
          assert(!@model.readonly?)
        end

        should "not be marked as comming from the slave" do
          assert(!@model.from_slave?)
        end
      end

      # TODO: make all this stuff rails 3 compatible.
      context "with finds routed to the slave by default" do
        setup do
          Account.on_slave_by_default = true
          Account.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'master_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          Account.on_slave.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1000, 'slave_name', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
          Account.on_slave.connection.execute("INSERT INTO accounts (id, name, created_at, updated_at) VALUES(1001, 'slave_name2', '2009-12-04 20:18:48', '2009-12-04 20:18:48')")
        end

        should "find() by default on the slave" do
          account = Account.find(1000)
          assert_equal 'slave_name', account.name
        end

        should "count() by default on the slave" do
          count = Account.all.size
          assert_equal 2, count
        end

        should "reload() on the master" do
          account = Account.find(1000)
          assert_equal 'master_name', account.reload.name
        end

        should "Allow override using on_master" do
          model = Account.on_master.find(1000)
          assert_equal "master_name", model.name
        end

        should "not override on_master with on_slave" do
          model = Account.on_master { Account.on_slave.find(1000) }
          assert_equal "master_name", model.name
        end

        should "override on_slave with on_master" do
          model = Account.on_slave { Account.on_master.find(1000) }
          assert_equal "master_name", model.name
        end

        should "propogate the default_slave setting to inherited classes" do
          assert AccountInherited.on_slave_by_default?
        end

        teardown do
          Account.on_slave_by_default = false
        end
      end
    end

    context "slave proxy" do
      should "successfully execute queries" do
        assert_using_master_db
        Account.create!

        assert_not_equal Account.count, Account.on_slave.count
      end

      should "work on association collections" do
        assert_using_master_db
        account = Account.create!

        account.tickets.create! :title => 'master ticket'

        Ticket.on_slave {
          account.tickets.create! :title => 'slave ticket'
        }

        assert_equal "master ticket", account.tickets.first.title
        assert_equal "slave ticket", account.tickets.on_slave.first.title
      end
    end
  end

  context "alternative connections" do
    should "not interfere with other connections" do
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
end
