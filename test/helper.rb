# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/rg'
require 'rake'

require 'mocha/minitest'
Bundler.require

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)
require 'active_support'
require 'active_record_shards'
require 'mysql2'
require 'support/tcp_proxy'
require 'logger'

require 'pry-byebug'

RAILS_ENV = "test"

ActiveRecord::Base.logger = Logger.new(__dir__ + "/test.log")
ActiveSupport.test_order = :sorted
ActiveSupport::Deprecation.behavior = :raise
ActiveRecordShards::Deprecation.behavior = :silence

BaseMigration = (ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration) # rubocop:disable Naming/ConstantName

require 'active_support/test_case'

# support multiple before/after blocks per example
module SpecDslPatch
  def before(_type = nil, &block)
    include(Module.new { super })
  end

  def after(_type = nil, &block)
    include(Module.new { super })
  end
end
Minitest::Spec.singleton_class.prepend(SpecDslPatch)

module RakeSpecHelpers
  def show_databases(config)
    client = Mysql2::Client.new(
      host: config['test']['host'],
      port: config['test']['port'],
      username: config['test']['username'],
      password: config['test']['password']
    )
    databases = client.query("SHOW DATABASES")
    databases.map { |d| d['Database'] }
  end

  def rake(name)
    Rake::Task[name].reenable
    Rake::Task[name].invoke
  end
end

module ConnectionSwitchingSpecHelpers
  def assert_using_primary_db
    assert_using_database('ars_test')
  end

  def assert_using_replica_db
    assert_using_database('ars_test_replica')
  end

  def assert_using_database(db_name, model = ActiveRecord::Base)
    assert_equal(db_name, model.connection.current_database)
  end
end

module SpecHelpers
  def self.mysql_url
    URI(ENV['MYSQL_URL'] || 'mysql://root@127.0.0.1:3306')
  end

  @@unsharded_primary_proxy ||= TCPProxy.start(
    remote_host: mysql_url.host,
    remote_port: mysql_url.port,
    local_port: '13306'
  )

  @@shard_1_primary_proxy ||= TCPProxy.start(
    remote_host: mysql_url.host,
    remote_port: mysql_url.port,
    local_port: '13307'
  )

  @@shard_2_primary_proxy ||= TCPProxy.start(
    remote_host: mysql_url.host,
    remote_port: mysql_url.port,
    local_port: '13308'
  )

  # Verifies that a block of code is not using any of the the primaries by
  # pausing the TCP proxies between Ruby and MySQL.
  def with_all_primaries_unavailable
    with_unsharded_primary_unavailable do
      with_sharded_primaries_unavailable do
        yield
      end
    end
  end

  # Verifies that a block of code is not using the unsharded primary by pausing
  # the TCP proxy between Ruby and MySQL.
  def with_unsharded_primary_unavailable
    @@unsharded_primary_proxy.pause do
      yield
    end
  end

  # Verifies that a block of code is not using the sharded primaries by pausing
  # the TCP proxies between Ruby and MySQL.
  def with_sharded_primaries_unavailable
    @@shard_1_primary_proxy.pause do
      @@shard_2_primary_proxy.pause do
        yield
      end
    end
  end

  def clear_global_connection_handler_state
    # Close active connections
    ActiveRecord::Base.connection_handler.clear_all_connections!

    # Use a fresh connection handler
    ActiveRecord::Base.connection_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new

    if ActiveRecord::VERSION::MAJOR == 4
      # Clear out our own global state
      ActiveRecord::Base.send(:clear_specification_cache)
    end
  end

  def table_exists?(name)
    if ActiveRecord::VERSION::MAJOR >= 5
      ActiveRecord::Base.connection.data_source_exists?(name)
    else
      ActiveRecord::Base.connection.table_exists?(name)
    end
  end

  def table_has_column?(table, column)
    !ActiveRecord::Base.connection.select_values("desc #{table}").grep(column).empty?
  end

  def migrator(direction = :up, path = 'migrations', target_version = nil)
    migration_path = File.join(__dir__, "support", path)
    if ActiveRecord::VERSION::MAJOR >= 6
      migrations = ActiveRecord::MigrationContext.new(migration_path, ActiveRecord::SchemaMigration).migrations
      ActiveRecord::Migrator.new(direction, migrations, ActiveRecord::SchemaMigration, target_version)
    elsif ActiveRecord::VERSION::STRING >= "5.2.0"
      migrations = ActiveRecord::MigrationContext.new(migration_path).migrations
      ActiveRecord::Migrator.new(direction, migrations, target_version)
    else
      migrations = ActiveRecord::Migrator.migrations(migration_path)
      ActiveRecord::Migrator.new(direction, migrations, target_version)
    end
  end
end
Minitest::Spec.include(SpecHelpers)

module RailsEnvSwitch
  def switch_rails_env(env)
    before do
      silence_warnings { Object.const_set("RAILS_ENV", env) }
      ActiveRecord::Base.establish_connection(::RAILS_ENV.to_sym)
    end
    after do
      silence_warnings { Object.const_set("RAILS_ENV", 'test') }
      ActiveRecord::Base.establish_connection(::RAILS_ENV.to_sym)
      tmp_sharded_model = Class.new(ActiveRecord::Base)
      assert_equal('ars_test', tmp_sharded_model.connection.current_database)
    end
  end
end

module DbHelper
  class << self
    def client
      @client ||= begin
        config = URI(ENV["MYSQL_URL"] || "mysql://root@127.0.0.1:3306")
        Mysql2::Client.new(
          username: config.user,
          password: config.password,
          host: config.host,
          port: config.port
        )
      end
    end

    def each_database(&_block)
      Dir.glob("test/schemas/*.sql").each do |schema_path|
        database_name = File.basename(schema_path, ".sql").to_s
        yield(database_name, schema_path)
      end
    end

    def mysql(commands)
      commands.split(/\s*;\s*/).reject(&:empty?).each do |command|
        client.query(command)
      end
    end

    def drop_databases
      each_database do |database_name, _schema_path|
        DbHelper.mysql("DROP DATABASE IF EXISTS #{database_name}")
      end
    end

    def create_databases
      each_database do |database_name, _schema_path|
        DbHelper.mysql("CREATE DATABASE IF NOT EXISTS #{database_name}")
      end
    end

    def load_database_schemas
      each_database do |database_name, schema_path|
        DbHelper.mysql("USE #{database_name}")
        DbHelper.mysql(File.read(schema_path))
      end
    end

    def load_database_configuration(path = 'test/database.yml')
      # Load the database configuration into ActiveRecord
      erb_config = IO.read(path)
      yaml_config = ERB.new(erb_config).result
      ActiveRecord::Base.configurations = YAML.load(yaml_config) # rubocop:disable Security/YAMLLoad
    end
  end

  # Create all databases and then tear them down after test
  def with_fresh_databases
    before do
      DbHelper.drop_databases
      DbHelper.create_databases
      DbHelper.load_database_schemas

      clear_global_connection_handler_state
      DbHelper.load_database_configuration
    end

    after do
      DbHelper.drop_databases
    end
  end
end
Minitest::Spec.extend(DbHelper)
