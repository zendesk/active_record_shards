# frozen_string_literal: true
class FailureMigration < BaseMigration
  shard :all

  def self.up
    $fail_at_two ||= 0
    $fail_at_two += 1
    raise "FAIL FAIL FAIL" if $fail_at_two == 2
    add_column :tickets, :sharded_column, :integer
  end

  def self.down
    remove_column :tickets, :sharded_column
  end
end
