# frozen_string_literal: true

require_relative 'helper'
require 'models'

describe ".on_replica_by_default" do
  with_phenix

  before do
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)

    Account.on_replica_by_default = true
    Person.on_replica_by_default = true

    Account.connection.execute(
      "INSERT INTO accounts (id, name, created_at, updated_at) VALUES (1000, 'Primary account', NOW(), NOW())"
    )
    Account.on_replica.connection.execute(
      "INSERT INTO accounts (id, name, created_at, updated_at) VALUES (1000, 'Replica account', NOW(), NOW())"
    )
    Account.on_replica.connection.execute(
      "INSERT INTO accounts (id, name, created_at, updated_at) VALUES (1001, 'Replica account 2', NOW(), NOW())"
    )

    Person.connection.execute(
      "REPLACE INTO people(id, name) VALUES (10, 'Primary person')"
    )
    Person.on_replica.connection.execute(
      "REPLACE INTO people(id, name) VALUES (20, 'Replica person')"
    )

    Account.connection.execute(
      "INSERT INTO account_people(account_id, person_id) VALUES (1000, 10)"
    )
    Account.on_replica.connection.execute(
      "INSERT INTO account_people(account_id, person_id) VALUES (1001, 20)"
    )
  end

  after do
    Account.on_replica_by_default = false
    Person.on_replica_by_default = false
  end

  it "executes `find` on the replica" do
    account = Account.find(1000)
    assert_equal "Replica account", account.name
  end

  it "executes `count` on the replica" do
    count = Account.count
    assert_equal 2, count
  end

  it "executes `reload` on the replica" do
    account = Account.find(1000)
    assert_equal "Replica account", account.reload.name
  end

  it "executes `exists?` on the replica" do
    assert Account.exists?(1001)
  end

  it "executes `exists?` on the replica with a named scope" do
    AccountThing.on_replica_by_default = true
    AccountThing.on_replica.connection.execute("INSERT INTO account_things (id, account_id) VALUES (123125, 1000)")

    assert AccountThing.enabled.exists?(123125)
    AccountThing.on_replica_by_default = false
  end

  it "counts associations on the replica" do
    AccountThing.on_replica_by_default = true
    AccountThing.on_replica.connection.execute("INSERT INTO account_things (id, account_id) VALUES (123123, 1000)")
    AccountThing.on_replica.connection.execute("INSERT INTO account_things (id, account_id) VALUES (123124, 1000)")

    assert_equal 2, Account.find(1000).account_things.count
    AccountThing.on_replica_by_default = false
  end

  it "allows overriding with `on_primary`" do
    model = Account.on_primary.find(1000)
    assert_equal "Primary account", model.name
  end

  it "does not allow overriding `on_primary` with `on_replica`" do
    model = Account.on_primary { Account.on_replica.find(1000) }
    assert_equal "Primary account", model.name
  end

  it "allows overriding `on_replica` with `on_primary`" do
    model = Account.on_replica { Account.on_primary.find(1000) }
    assert_equal "Primary account", model.name
  end

  it "propagates the `on_replica_by_default?` reader to inherited classes" do
    assert AccountInherited.on_replica_by_default?
  end

  it "is false on ActiveRecord::Base" do
    refute ActiveRecord::Base.on_replica_by_default?
  end

  it "propagates the `on_replica_by_default` writer to inherited classes" do
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

  it "`includes` things via has_and_belongs_to_many associations correctly" do
    a = Account.where(id: 1001).includes(:people).first
    refute_empty(a.people)
    assert_equal "Replica person", a.people.first.name
  end

  it "sets up has_and_belongs_to_many sharded-ness correctly" do
    refute Account.const_get(:HABTM_People).is_sharded?
  end

  it "executes `pluck` on the replica" do
    assert_equal ["Replica account", "Replica account 2"], Account.pluck(:name)
  end

  it "supports implicit joins" do
    accounts = Account.includes(:account_things).references(:account_things)
    account_names = accounts.order("account_things.id").map(&:name).sort
    assert_equal ["Replica account", "Replica account 2"], account_names
  end

  it "supports explicit joins" do
    accounts = Account.joins("LEFT OUTER JOIN account_things ON account_things.account_id = accounts.id")
    account_names = accounts.map(&:name).sort
    assert_equal ["Replica account", "Replica account 2"], account_names
  end

  it "does not support implicit joins between an unsharded and a sharded table" do
    accounts = Account.includes(:tickets).references(:tickets).order("tickets.id")
    assert_raises(ActiveRecord::StatementInvalid) { accounts.first }
  end

  it "does not support explicit joins between an unsharded and a sharded table" do
    accounts = Account.joins("LEFT OUTER JOIN tickets ON tickets.account_id = accounts.id")
    assert_raises(ActiveRecord::StatementInvalid) { accounts.first }
  end
end