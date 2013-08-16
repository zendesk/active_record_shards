class Account < ActiveRecord::Base
  # attributes: id, name, updated_at, created_at
  not_sharded

  has_many :tickets
  has_many :account_things
end

class AccountThing < ActiveRecord::Base
  not_sharded

  if respond_to?(:where)
    scope :enabled, where(:enabled => true)
  end
end

class Email < ActiveRecord::Base
  not_sharded
  establish_connection_override :alternative
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
end

