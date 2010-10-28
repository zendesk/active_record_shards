require 'helper'

class ReplicaTest < ActiveRecord::TestCase

  context "without replica configuration" do

    setup do
      ActiveRecord::Base.configurations.delete('test_slave')
      ActiveRecord::Base.connection_handler.connection_pools.clear
      ActiveRecord::Base.establish_connection('test')
    end

    should "default to the master database" do
      Account.create!

      ActiveRecord::Base.on_slave { assert_using_master_db(Account) }
      Account.on_slave { assert_using_master_db(Account) }
      Ticket.on_slave  { assert_using_master_db(Account) }
    end

    should "successfully execute queries" do
      Account.create!
      assert_using_master_db(Account)

      assert_equal Account.count, ActiveRecord::Base.on_slave { Account.count }
      assert_equal Account.count, Account.on_slave { Account.count }
    end

  end

  context "with replica configuration" do

    should "successfully execute queries" do
      assert_using_master_db(Account)
      Account.create!

      assert_not_equal Account.count, ActiveRecord::Base.on_slave { Account.count }
      assert_not_equal Account.count, Account.on_slave { Account.count }
      assert_equal Account.count, Ticket.on_slave { Account.count }
    end

    should "support model specific on_slave blocks" do
      assert_using_master_db(Account)
      assert_using_master_db(Ticket)

      Account.on_slave do
        assert_using_slave_db(Account)
        assert_using_master_db(Ticket)
      end

      assert_using_master_db(Account)
      assert_using_master_db(Ticket)
    end

    should "support global on_slave blocks" do
      assert_using_master_db(Account)
      assert_using_master_db(Ticket)

      ActiveRecord::Base.on_slave do
        assert_using_slave_db(Account)
        assert_using_slave_db(Ticket)
      end

      assert_using_master_db(Account)
      assert_using_master_db(Ticket)
    end

    should "support conditional methods" do
      assert_using_master_db(Account)

      Account.on_slave_if(true) do
        assert_using_slave_db(Account)
      end

      assert_using_master_db(Account)

      Account.on_slave_if(false) do
        assert_using_master_db(Account)
      end

      Account.on_slave_unless(true) do
        assert_using_master_db(Account)
      end

      Account.on_slave_unless(false) do
        assert_using_slave_db(Account)
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
    end
  end

  context "replica proxy" do
    should "successfully execute queries" do
      assert_using_master_db(Account)
      Account.create!

      assert_not_equal Account.count, Account.on_slave.count
    end

    should "work association collections" do
      assert_using_master_db(Account)
      account = Account.create!

      Ticket.connection.expects(:select_all).with("SELECT * FROM `tickets` WHERE (`tickets`.account_id = #{account.id})  LIMIT 1", anything).returns([])
      Ticket.on_slave.connection.expects(:select_all).with("SELECT * FROM `tickets` WHERE (`tickets`.account_id = #{account.id})  LIMIT 1", anything).returns([])

      account.tickets.first
      account.tickets.on_slave.first
    end
  end
end
