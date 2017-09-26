# frozen_string_literal: true
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table "tickets", force: true do |t|
    t.string   "title"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
