# frozen_string_literal: true
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table "tickets", force: true do |t|
    t.string   "title"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: true do |t|
    t.text     "body"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ticket_comments", force: true, id: false do |t|
    t.integer "ticket_id"
    t.integer "comment_id"
  end
end
