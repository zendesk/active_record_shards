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

  describe "without primary config replacement" do
    before do
      @exploded_conf = ActiveRecordShards::ConfigurationParser.explode(YAML.safe_load(yaml))
    end

    it "expands configuration for the main primary" do
      config = @exploded_conf["test"]

      shared_assertions(config)
      assert_equal "main_host", config["host"]
      assert_equal "ars_test", config["database"]
    end

    it "expands configuration for the main replica" do
      config = @exploded_conf["test_replica"]

      shared_assertions(config)
      assert_equal "main_replica_host", config["host"]
      assert_equal "ars_test", config["database"]
    end

    it "expands configuration for shard 500's primary" do
      config = @exploded_conf["test_shard_500"]

      shared_assertions(config)
      assert_equal "shard_500_host", config["host"]
      assert_equal "ars_test_shard_500", config["database"]
    end

    it "expands configuration for shard 500's replica" do
      config = @exploded_conf["test_shard_500_replica"]

      shared_assertions(config)
      assert_equal "shard_500_replica_host", config["host"]
      assert_equal "ars_test_shard_500", config["database"]
    end

    it "expands configuration for shard 501's primary" do
      config = @exploded_conf["test_shard_501"]

      shared_assertions(config)
      assert_equal "shard_501_host", config["host"]
      assert_equal "ars_test_shard_501", config["database"]
    end

    it "expands configuration for shard 501's replica" do
      config = @exploded_conf["test_shard_501_replica"]

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
  end

  describe "with primary config replacement" do
    before do
      @yaml_with_full_replica_config =
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
              adapter: mysql2
              database: replica_database
              host: main_replica_host
              password: replica_password
              port: 12345
              username: replica_username
            shards:
              500:
                database: ars_test_shard_500
                host: shard_500_host
                replica:
                  adapter: mysql2
                  database: shard_500_replica_database
                  host: shard_500_replica_host
                  password: shard_500_replica_password
                  port: 12345
                  username: shard_500_replica_username
        YAML
    end

    it "changes one configuration with its replica configuration" do
      ActiveRecordShards.replace_with_replica_configuration "test"
      exploded_conf = ActiveRecordShards::ConfigurationParser.explode(YAML.safe_load(@yaml_with_full_replica_config))

      assert_equal exploded_conf["test"]["adapter"], "mysql2"
      assert_equal exploded_conf["test"]["database"], "replica_database"
      assert_equal exploded_conf["test"]["host"], "main_replica_host"
      assert_equal exploded_conf["test"]["password"], "replica_password"
      assert_equal exploded_conf["test"]["port"], 12345
      assert_equal exploded_conf["test"]["username"], "replica_username"
    end

    it "changes multiple configurations with their replica configuration" do
      ActiveRecordShards.replace_with_replica_configuration "test", "test_shard_500"
      exploded_conf = ActiveRecordShards::ConfigurationParser.explode(YAML.safe_load(@yaml_with_full_replica_config))

      assert_equal exploded_conf["test"]["adapter"], "mysql2"
      assert_equal exploded_conf["test"]["database"], "replica_database"
      assert_equal exploded_conf["test"]["host"], "main_replica_host"
      assert_equal exploded_conf["test"]["password"], "replica_password"
      assert_equal exploded_conf["test"]["port"], 12345
      assert_equal exploded_conf["test"]["username"], "replica_username"

      assert_equal exploded_conf["test_shard_500"]["adapter"], "mysql2"
      assert_equal exploded_conf["test_shard_500"]["database"], "shard_500_replica_database"
      assert_equal exploded_conf["test_shard_500"]["host"], "shard_500_replica_host"
      assert_equal exploded_conf["test_shard_500"]["password"], "shard_500_replica_password"
      assert_equal exploded_conf["test_shard_500"]["port"], 12345
      assert_equal exploded_conf["test_shard_500"]["username"], "shard_500_replica_username"
    end

    after do
      ActiveRecordShards.class_variable_set(:@@configs_to_replace_with_replicas, [])
    end
  end
end
