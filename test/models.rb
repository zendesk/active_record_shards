class Account < ActiveRecord::Base
  # attributes: id, name, updated_at, created_at
  has_many :tickets
end

class Ticket < ActiveRecord::Base
  # attributes: id, title, account_id, updated_at, created_at
  belongs_to :account
end