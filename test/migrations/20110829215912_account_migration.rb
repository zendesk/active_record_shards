# frozen_string_literal: true
class AccountMigration < BaseMigration
  shard :none

  def self.up
    unless table_exists?(:accounts)
      create_table :accounts do |t|
        t.string :name
      end
    end
    add_column :accounts, :non_sharded_column, :integer
  end

  def self.down
    remove_column :accounts, :non_sharded_column
  end
end
