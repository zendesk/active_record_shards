# frozen_string_literal: true
class Account < ActiveRecord::Base
  # attributes: id, name, updated_at, created_at

  has_many :tickets
  has_many :account_things
  has_and_belongs_to_many :people, join_table: 'account_people'
end

class AccountThing < ActiveRecord::Base
  if respond_to?(:where)
    scope(:enabled, -> { where(enabled: true) })
  else
    named_scope :enabled, conditions: { enabled: true }
  end
end

class AccountInherited < Account
end

class Ticket < ActiveRecordShards::ShardedModel
  # attributes: id, title, account_id, updated_at, created_at
  belongs_to :account
  has_and_belongs_to_many :comments, join_table: 'ticket_comments'
end

class Person < ActiveRecord::Base
end

class User < Person
end

class Comment < ActiveRecordShards::ShardedModel
  # attributes: id, body, account_id, updated_at, created_at
  belongs_to :account
end
