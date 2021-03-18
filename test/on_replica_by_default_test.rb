# frozen_string_literal: true

require_relative 'helper'
require 'models'

describe ".on_replica_by_default" do
  with_phenix

  before do
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)

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

  it "reload() on the replica" do
    account = Account.find(1000)
    assert_equal 'replica_name', account.reload.name
  end

  it "do exists? on the replica" do
    assert Account.exists?(1001)
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
    refute_empty(a.people)
    assert_equal 'replica person', a.people.first.name
  end

  it "sets up has and belongs to many sharded-ness correctly" do
    refute Account.const_get(:HABTM_People).is_sharded?
  end

  it "supports .pluck" do
    assert_equal ["replica_name", "replica_name2"], Account.pluck(:name)
  end

  it "supports implicit joins" do
    accounts = Account.includes(:account_things).references(:account_things)
    assert_equal ["replica_name", "replica_name2"], accounts.order('account_things.id').map(&:name).sort
  end

  it "supports joins" do
    accounts = Account.joins('LEFT OUTER JOIN account_things ON account_things.account_id = accounts.id').map(&:name).sort
    assert_equal ["replica_name", "replica_name2"], accounts
  end

  it "does not support implicit joins between an unsharded and a sharded table" do
    accounts = Account.includes(:tickets).references(:tickets).order('tickets.id')
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
