# frozen_string_literal: true

class ActiveRecord::Base # rubocop:disable Style/ClassAndModuleChildren
  # TODO: Overwrite connects to to validate input
  connects_to shards: {
    default: { writing: :primary, reading: :primary_replica },
    shard_0: { writing: :shard_0, reading: :shard_0_replica },
    shard_1: { writing: :shard_1, reading: :shard_1_replica }
  }
end

class Account < ActiveRecord::Base
  # attributes: id, name, updated_at, created_at
  not_sharded

  has_many :tickets
  has_many :account_things
  has_and_belongs_to_many :people, join_table: 'account_people'
end

class AccountThing < ActiveRecord::Base
  not_sharded

  scope(:enabled, -> { where(enabled: true) })
end

class AccountInherited < Account
end

class Ticket < ActiveRecord::Base
  # attributes: id, title, account_id, updated_at, created_at
  belongs_to :account
end

class Person < ActiveRecord::Base
  not_sharded
end

class User < Person
  # Makes `User.new` a bit more complicated. Don't change without changing the
  # corresponding tests.
  default_scope { where(type: 'User') }
end
