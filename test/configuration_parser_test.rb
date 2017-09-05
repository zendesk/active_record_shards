# frozen_string_literal: true
require_relative 'helper'

describe ActiveRecordShards::ConfigurationParser do
  describe "exploding the database.yml" do
    before do
      @exploded_conf = ActiveRecordShards::ConfigurationParser.explode(YAML.safe_load(IO.read(File.dirname(__FILE__) + '/database_parse_test.yml')))
    end

    describe "main slave" do
      before { @conf = @exploded_conf["test_slave"] }
      it "be exploded" do
        @conf["shard_names"] = @conf["shard_names"].to_set
        assert_equal({
          "adapter"     => "mysql",
          "encoding"    => "utf8",
          "database"    => "ars_test",
          "port"        => 123,
          "username"    => "root",
          "password"    => nil,
          "host"        => "main_slave_host",
          "shard_names" => ["a", "b"].to_set
        }, @conf)
      end
    end

    describe "shard a" do
      describe "master" do
        before { @conf = @exploded_conf["test_shard_a"] }
        it "be exploded" do
          @conf["shard_names"] = @conf["shard_names"].to_set
          assert_equal({
            "adapter"     => "mysql",
            "encoding"    => "utf8",
            "database"    => "ars_test_shard_a",
            "port"        => 123,
            "username"    => "root",
            "password"    => nil,
            "host"        => "shard_a_host",
            "shard_names" => ["a", "b"].to_set
          }, @conf)
        end
      end

      describe "slave" do
        before { @conf = @exploded_conf["test_shard_a_slave"] }
        it "be exploded" do
          @conf["shard_names"] = @conf["shard_names"].to_set
          assert_equal({
            "adapter"     => "mysql",
            "encoding"    => "utf8",
            "database"    => "ars_test_shard_a",
            "port"        => 123,
            "username"    => "root",
            "password"    => nil,
            "host"        => "shard_a_slave_host",
            "shard_names" => ["a", "b"].to_set
          }, @conf)
        end
      end
    end

    describe "shard b" do
      describe "master" do
        before { @conf = @exploded_conf["test_shard_b"] }
        it "be exploded" do
          @conf["shard_names"] = @conf["shard_names"].to_set
          assert_equal({
            "adapter"     => "mysql",
            "encoding"    => "utf8",
            "database"    => "ars_test_shard_b",
            "port"        => 123,
            "username"    => "root",
            "password"    => nil,
            "host"        => "shard_b_host",
            "shard_names" => ["a", "b"].to_set
          }, @conf)
        end
      end

      describe "slave" do
        before { @conf = @exploded_conf["test_shard_b_slave"] }
        it "be exploded" do
          @conf["shard_names"] = @conf["shard_names"].to_set
          assert_equal({
            "adapter"     => "mysql",
            "encoding"    => "utf8",
            "database"    => "ars_test_shard_b_slave",
            "port"        => 123,
            "username"    => "root",
            "password"    => nil,
            "host"        => "shard_b_host",
            "shard_names" => ["a", "b"].to_set
          }, @conf)
        end
      end
    end
  end
end
