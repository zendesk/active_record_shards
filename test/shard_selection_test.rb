# frozen_string_literal: true
require_relative 'helper'

describe ActiveRecordShards::ShardSelection do
  require 'models'

  before do
    erb_config = IO.read("#{__dir__}/database.yml")
    yaml_config = ERB.new(erb_config).result
    db_config = YAML.load(yaml_config) # rubocop:disable Security/YAMLLoad
    ActiveRecord::Base.configurations = db_config
  end

  after do
    ActiveRecordShards::ShardSelection.default_shard = nil
  end

  describe "sharded model" do
    it "complains when no shard is selected" do
      shard_selection = ActiveRecordShards::ShardSelection.new

      assert_raises("Cannot find connection for sharded class when no shard is selected.") { connection_name(shard_selection, Ticket) }
    end

    it "complains when no shard is selected even if told to use the slave" do
      shard_selection = ActiveRecordShards::ShardSelection.new
      shard_selection.on_slave = true

      assert_raises("Cannot find connection for sharded class when no shard is selected.") { connection_name(shard_selection, Ticket) }
    end

    it "returns the correct sharded master connection name" do
      shard_selection = ActiveRecordShards::ShardSelection.new
      shard_selection.shard = 0

      assert_equal "test_shard_0", connection_name(shard_selection, Ticket)
    end

    it "returns the correct sharded slave connection name" do
      shard_selection = ActiveRecordShards::ShardSelection.new
      shard_selection.shard = 0
      shard_selection.on_slave = true

      assert_equal "test_shard_0_slave", connection_name(shard_selection, Ticket)
    end

    describe "with default_shard set" do
      it "returns the correct sharded master connection name" do
        ActiveRecordShards::ShardSelection.default_shard = 1
        shard_selection = ActiveRecordShards::ShardSelection.new

        assert_equal "test_shard_1", connection_name(shard_selection, Ticket)
      end

      it "returns the correct sharded slave connection name" do
        ActiveRecordShards::ShardSelection.default_shard = 1
        shard_selection = ActiveRecordShards::ShardSelection.new
        shard_selection.on_slave = true

        assert_equal "test_shard_1_slave", connection_name(shard_selection, Ticket)
      end

      it "returns the correct sharded master connection name when overriding shard number" do
        ActiveRecordShards::ShardSelection.default_shard = 1
        shard_selection = ActiveRecordShards::ShardSelection.new
        shard_selection.shard = 0

        assert_equal "test_shard_0", connection_name(shard_selection, Ticket)
      end

      it "returns the correct sharded slave connection name when overriding shard number" do
        ActiveRecordShards::ShardSelection.default_shard = 1
        shard_selection = ActiveRecordShards::ShardSelection.new
        shard_selection.on_slave = true
        shard_selection.shard = 0

        assert_equal "test_shard_0_slave", connection_name(shard_selection, Ticket)
      end
    end
  end

  describe "unsharded model" do
    it "returns the unsharded master connection name" do
      shard_selection = ActiveRecordShards::ShardSelection.new

      # Two different names for the same connection
      assert_includes ["primary", "test"], connection_name(shard_selection, Account)
    end

    it "returns the unsharded slave connection name" do
      shard_selection = ActiveRecordShards::ShardSelection.new
      shard_selection.on_slave = true

      assert_equal "test_slave", connection_name(shard_selection, Account)
    end
  end

  private

  def connection_name(shard_selection, klass)
    if ActiveRecord::VERSION::MAJOR < 5
      shard_selection.shard_name(klass)
    else
      shard_selection.resolve_connection_name(sharded: klass.is_sharded?, configurations: klass.configurations)
    end
  end
end
