class Account < ActiveRecord::Base
  # attributes: id, name, updated_at, created_at
end

class Ticket < ActiveRecord::Base
  # attributes: id, title, account_id, updated_at, created_at
end