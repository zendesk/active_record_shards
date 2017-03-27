# frozen_string_literal: true
class RootAndAllMigration < BaseMigration
  shard :root_and_all

  def self.up
    add_column :accounts, :root_and_all_column, :integer
  end

  def self.down
    remove_column :accounts, :root_and_all_column
  end
end
