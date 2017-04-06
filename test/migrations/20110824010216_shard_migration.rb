# frozen_string_literal: true
class ShardMigration < ActiveRecord::Migration[4.2]
  shard :all

  def self.up
    add_column :tickets, :sharded_column, :integer
  end

  def self.down
    remove_column :tickets, :sharded_column
  end
end
