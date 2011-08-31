# See ticket 130214
# Setting up an odd initial three year term for box.net to be paid by credit card by the normal means
class AccountMigration < ActiveRecord::Migration
  shard :none

  def self.up
    add_column :accounts, :non_sharded_column, :integer
  end

  def self.down
    remove_column :accounts, :non_sharded_column
  end
end
