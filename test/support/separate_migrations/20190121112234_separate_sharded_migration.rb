# frozen_string_literal: true

class SeparateShardedMigration < BaseMigration
  shard :all

  def self.up
    create_table :sharded_table do |t|
      t.string :name
    end
  end

  def self.down
  end
end
