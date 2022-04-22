# frozen_string_literal: true

class UnshardedApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :default, reading: :default_replica }
end

class ShardedApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to shards: {
    shard_0: { writing: :shard_0, reading: :shard_0_replica },
    shard_1: { writing: :shard_1, reading: :shard_1_replica }
  }
end

class Account < UnshardedApplicationRecord
  # attributes: id, name, updated_at, created_at

  has_many :tickets
  has_many :account_things
  has_and_belongs_to_many :people, join_table: 'account_people'
end

class AccountThing < UnshardedApplicationRecord
  scope(:enabled, -> { where(enabled: true) })
end

class AccountInherited < Account
end

class Ticket < ShardedApplicationRecord
  # attributes: id, title, account_id, updated_at, created_at
  belongs_to :account
end

class Person < UnshardedApplicationRecord
end

class User < Person
  # Makes `User.new` a bit more complicated. Don't change without changing the
  # corresponding tests.
  default_scope { where(type: 'User') }
end
