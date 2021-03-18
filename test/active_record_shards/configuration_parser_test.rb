# frozen_string_literal: true

require_relative '../helper'

describe ActiveRecordShards::ConfigurationParser do
  describe "exploding the database.yml" do
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

    before do
      @exploded_conf = ActiveRecordShards::ConfigurationParser.explode(YAML.safe_load(yaml))
    end

    describe "main replica" do
      before { @conf = @exploded_conf["test_replica"] }

      it "explodes" do
        @conf["shard_names"] = @conf["shard_names"].to_set
        assert_equal({
          "adapter"     => "mysql",
          "encoding"    => "utf8",
          "database"    => "ars_test",
          "port"        => 123,
          "username"    => "root",
          "password"    => nil,
          "host"        => "main_replica_host",
          "shard_names" => [500, 501].to_set
        }, @conf)
      end
    end

    describe "shard a" do
      describe "primary" do
        before { @conf = @exploded_conf["test_shard_500"] }
        it "be exploded" do
          @conf["shard_names"] = @conf["shard_names"].to_set
          assert_equal({
            "adapter"     => "mysql",
            "encoding"    => "utf8",
            "database"    => "ars_test_shard_500",
            "port"        => 123,
            "username"    => "root",
            "password"    => nil,
            "host"        => "shard_500_host",
            "shard_names" => [500, 501].to_set
          }, @conf)
        end
      end

      describe "replica" do
        before { @conf = @exploded_conf["test_shard_500_replica"] }
        it "be exploded" do
          @conf["shard_names"] = @conf["shard_names"].to_set
          assert_equal({
            "adapter"     => "mysql",
            "encoding"    => "utf8",
            "database"    => "ars_test_shard_500",
            "port"        => 123,
            "username"    => "root",
            "password"    => nil,
            "host"        => "shard_500_replica_host",
            "shard_names" => [500, 501].to_set
          }, @conf)
        end
      end
    end

    describe "shard b" do
      describe "primary" do
        before { @conf = @exploded_conf["test_shard_501"] }
        it "be exploded" do
          @conf["shard_names"] = @conf["shard_names"].to_set
          assert_equal({
            "adapter"     => "mysql",
            "encoding"    => "utf8",
            "database"    => "ars_test_shard_501",
            "port"        => 123,
            "username"    => "root",
            "password"    => nil,
            "host"        => "shard_501_host",
            "shard_names" => [500, 501].to_set
          }, @conf)
        end
      end

      describe "replica" do
        before { @conf = @exploded_conf["test_shard_501_replica"] }
        it "be exploded" do
          @conf["shard_names"] = @conf["shard_names"].to_set
          assert_equal({
            "adapter"     => "mysql",
            "encoding"    => "utf8",
            "database"    => "ars_test_shard_501_replica",
            "port"        => 123,
            "username"    => "root",
            "password"    => nil,
            "host"        => "shard_501_host",
            "shard_names" => [500, 501].to_set
          }, @conf)
        end
      end
    end
  end
end
