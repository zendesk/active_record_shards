class ShardMigration < ActiveRecord::Migration
  shard :all

  def self.up
    add_column :emails, :sharded_column, :integer
  end

  def self.down
    remove_column :emails, :sharded_column
  end
end
