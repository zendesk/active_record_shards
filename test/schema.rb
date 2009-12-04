ActiveRecord::Schema.define(:version => 1) do

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tickets", :force => true do |t|
    t.string   "title"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end