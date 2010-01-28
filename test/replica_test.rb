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

      ActiveRecord::Base.with_slave { assert_using_master_db(Account) }
      Account.with_slave { assert_using_master_db(Account) }
      Ticket.with_slave  { assert_using_master_db(Account) }
    end

    should "successfully execute queries" do
      Account.create!
      assert_using_master_db(Account)

      assert_equal Account.count, ActiveRecord::Base.with_slave { Account.count }
      assert_equal Account.count, Account.with_slave { Account.count }
    end

  end

  context "with replica configuration" do

    should "successfully execute queries" do
      assert_using_master_db(Account)
      Account.create!

      assert_not_equal Account.count, ActiveRecord::Base.with_slave { Account.count }
      assert_not_equal Account.count, Account.with_slave { Account.count }
      assert_not_equal Account.count, Account.with_slave.count
      assert_equal Account.count, Ticket.with_slave { Account.count }
    end

    should "support model specific with_slave blocks" do
      assert_using_master_db(Account)
      assert_using_master_db(Ticket)

      Account.with_slave do
        assert_using_slave_db(Account)
        assert_using_master_db(Ticket)
      end

      assert_using_master_db(Account)
      assert_using_master_db(Ticket)
    end

    should "support global with_slave blocks" do
      assert_using_master_db(Account)
      assert_using_master_db(Ticket)

      ActiveRecord::Base.with_slave do
        assert_using_slave_db(Account)
        assert_using_slave_db(Ticket)
      end

      assert_using_master_db(Account)
      assert_using_master_db(Ticket)
    end

    should "support conditional methods" do
      assert_using_master_db(Account)

      Account.with_slave_if(true) do
        assert_using_slave_db(Account)
      end

      assert_using_master_db(Account)

      Account.with_slave_if(false) do
        assert_using_master_db(Account)
      end

      Account.with_slave_unless(true) do
        assert_using_master_db(Account)
      end

      Account.with_slave_unless(false) do
        assert_using_slave_db(Account)
      end

    end

    should_eventually "support nested with_* blocks" do

      assert_using_master_db(Account)
      assert_using_master_db(Ticket)

      ActiveRecord::Base.with_slave do
        assert_using_slave_db(Account)
        assert_using_slave_db(Ticket)

        Account.with_master do
          assert_using_master_db(Account)
          assert_using_slave_db(Ticket)
        end

        assert_using_slave_db(Account)
        assert_using_slave_db(Ticket)
      end

      assert_using_master_db(Account)
      assert_using_master_db(Ticket)
    end

  end
end
