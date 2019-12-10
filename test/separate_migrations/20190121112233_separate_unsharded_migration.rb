# frozen_string_literal: true

class SeparateUnshardedMigration < BaseMigration
  shard :none

  def self.up
    create_table :unsharded_table do |t|
      t.string :name
    end
  end

  def self.down
  end
end
