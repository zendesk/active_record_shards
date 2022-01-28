# frozen_string_literal: true

require_relative '../helper'

describe "ActiveRecordShards::ConfigurationParser.explode" do
  let(:yaml) do
    <<~YAML
      test:
        adapter: mysql
        encoding: utf8
        database: ars_test
        port: 123
        username: root
        password:
        host: main_host
        replica:
          host: main_replica_host
        shards:
          500:
            database: ars_test_shard_500
            host: shard_500_host
            replica:
              host: shard_500_replica_host
          501:
            database: ars_test_shard_501
            host: shard_501_host
            replica:
              database: ars_test_shard_501_replica
    YAML
  end

  let(:exploded_conf) do
    ActiveRecordShards::ConfigurationParser.explode(YAML.safe_load(yaml))
  end

  it "expands configuration for the main primary" do
    config = exploded_conf["test"]

    shared_assertions(config)
    assert_equal "main_host", config["host"]
    assert_equal "ars_test", config["database"]
  end

  it "expands configuration for the main replica" do
    config = exploded_conf["test_replica"]

    shared_assertions(config)
    assert_equal "main_replica_host", config["host"]
    assert_equal "ars_test", config["database"]
  end

  it "expands configuration for shard 500's primary" do
    config = exploded_conf["test_shard_500"]

    shared_assertions(config)
    assert_equal "shard_500_host", config["host"]
    assert_equal "ars_test_shard_500", config["database"]
  end

  it "expands configuration for shard 500's replica" do
    config = exploded_conf["test_shard_500_replica"]

    shared_assertions(config)
    assert_equal "shard_500_replica_host", config["host"]
    assert_equal "ars_test_shard_500", config["database"]
  end

  it "expands configuration for shard 501's primary" do
    config = exploded_conf["test_shard_501"]

    shared_assertions(config)
    assert_equal "shard_501_host", config["host"]
    assert_equal "ars_test_shard_501", config["database"]
  end

  it "expands configuration for shard 501's replica" do
    config = exploded_conf["test_shard_501_replica"]

    shared_assertions(config)
    assert_equal "shard_501_host", config["host"]
    assert_equal "ars_test_shard_501_replica", config["database"]
  end

  def shared_assertions(config)
    assert_equal "mysql", config["adapter"]
    assert_equal "utf8", config["encoding"]
    assert_equal 123, config["port"]
    assert_equal "root", config["username"]
    assert_nil config["password"]
    assert_equal [500, 501], config["shard_names"]
  end

  describe "legacy YAML format (with `slave` keys)" do
    let(:yaml) do
      <<~YAML
        test:
          adapter: mysql
          encoding: utf8
          database: ars_test
          port: 123
          username: root
          password:
          host: main_host
          slave:
            host: main_replica_host
          shards:
            500:
              database: ars_test_shard_500
              host: shard_500_host
              slave:
                host: shard_500_replica_host
            501:
              database: ars_test_shard_501
              host: shard_501_host
              slave:
                database: ars_test_shard_501_replica
      YAML
    end

    it "expands configuration for the main primary" do
      config = exploded_conf["test"]

      shared_assertions(config)
      assert_equal "main_host", config["host"]
      assert_equal "ars_test", config["database"]
    end

    it "expands configuration for the main replica" do
      config = exploded_conf["test_replica"]

      shared_assertions(config)
      assert_equal "main_replica_host", config["host"]
      assert_equal "ars_test", config["database"]
    end

    it "expands configuration for shard 500's primary" do
      config = exploded_conf["test_shard_500"]

      shared_assertions(config)
      assert_equal "shard_500_host", config["host"]
      assert_equal "ars_test_shard_500", config["database"]
    end

    it "expands configuration for shard 500's replica" do
      config = exploded_conf["test_shard_500_replica"]

      shared_assertions(config)
      assert_equal "shard_500_replica_host", config["host"]
      assert_equal "ars_test_shard_500", config["database"]
    end

    it "expands configuration for shard 501's primary" do
      config = exploded_conf["test_shard_501"]

      shared_assertions(config)
      assert_equal "shard_501_host", config["host"]
      assert_equal "ars_test_shard_501", config["database"]
    end

    it "expands configuration for shard 501's replica" do
      config = exploded_conf["test_shard_501_replica"]

      shared_assertions(config)
      assert_equal "shard_501_host", config["host"]
      assert_equal "ars_test_shard_501_replica", config["database"]
    end
  end

  describe "already-expanded configuration (with `*_slave` keys" do
    let(:exploder) do
      Class.new do
        class << self
          attr_accessor :configurations
        end
        extend(ActiveRecordShards::ConfigurationParser)
      end
    end

    it "copies the *_slave configs to *_replica configs" do
      yaml = <<~YAML
        test:
          adapter: mysql
          database: ars_test
          username: root
          password:
          host: main_host
        test_slave:
          adapter: mysql
          database: ars_test
          username: root
          password:
          host: main_slave_host
        test_shard_500_slave:
          adapter: mysql
          database: ars_test
          username: root
          password:
          host: shard_500_slave_host
      YAML
      exploder.configurations = YAML.safe_load(yaml)
      conf = exploder.configurations

      assert_equal %w[test test_replica test_shard_500_replica test_shard_500_slave test_slave], conf.keys.sort
      assert_equal conf["test_slave"], conf["test_replica"]
      assert_equal conf["test_shard_500_slave"], conf["test_shard_500_replica"]
    end

    # Your database config is a mess.
    it "doesn't copy *_slave configs if already expanded from a nested slave/replica config" do
      yaml = <<~YAML
        test:
          adapter: mysql
          database: ars_test
          username: root
          password:
          host: main_host
          slave:
            host: replica_host_one
        test_slave:
          adapter: mysql
          database: ars_test
          username: root
          password:
          host: replica_host_two
      YAML
      exploder.configurations = YAML.safe_load(yaml)
      conf = exploder.configurations

      assert_equal %w[test test_replica test_slave], conf.keys.sort
      refute_equal conf["test_slave"], conf["test_replica"]
      assert_equal "replica_host_one", conf["test_replica"]["host"]
      assert_equal "replica_host_two", conf["test_slave"]["host"]
    end
  end
end
