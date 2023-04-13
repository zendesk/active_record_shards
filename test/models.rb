# frozen_string_literal: true

class Account < ActiveRecord::Base
  # attributes: id, name, updated_at, created_at
  not_sharded

  has_many :tickets
  has_many :account_things
  has_and_belongs_to_many :people, join_table: "account_people"
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
  default_scope { where(type: "User") }
end
