# frozen_string_literal: true

class ShardMigration < BaseMigration
  shard :all

  def self.up
    add_column(:tickets, :sharded_column, :integer)
  end

  def self.down
    remove_column(:tickets, :sharded_column)
  end
end
