require File.expand_path('helper', File.dirname(__FILE__))

class ConfigurationParserTest < ActiveSupport::TestCase
  context "exploding the database.yml" do
    setup do
      @exploded_conf = ActiveRecordShards::ConfigurationParser.explode(YAML::load(IO.read(File.dirname(__FILE__) + '/database_parse_test.yml')))
    end

    context "main slave" do
      setup { @conf = @exploded_conf['test_slave'] }
      should "be exploded" do
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

    context "shard a" do
      context "master" do
        setup { @conf = @exploded_conf['test_shard_a'] }
        should "be exploded" do
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

      context "slave" do
        setup { @conf = @exploded_conf['test_shard_a_slave'] }
        should "be exploded" do
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

    context "shard b" do
      context "master" do
        setup { @conf = @exploded_conf['test_shard_b'] }
        should "be exploded" do
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

      context "slave" do
        setup { @conf = @exploded_conf['test_shard_b_slave'] }
        should "be exploded" do
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
