# frozen_string_literal: true
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/rg'
require 'rake'

require 'mocha/minitest'
Bundler.require

if defined?(Debugger)
  ::Debugger.start
  ::Debugger.settings[:autoeval] = true if ::Debugger.respond_to?(:settings)
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_support'
require 'active_record_shards'
require 'logger'
require 'phenix'

RAILS_ENV = "test".freeze

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/test.log")
ActiveSupport.test_order = :sorted if ActiveSupport.respond_to?(:test_order=)
ActiveSupport::Deprecation.behavior = :raise

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
  def assert_using_master_db
    assert_using_database('ars_test')
  end

  def assert_using_slave_db
    assert_using_database('ars_test_slave')
  end

  def assert_using_database(db_name, model = ActiveRecord::Base)
    assert_equal(db_name, model.connection.current_database)
  end
end

module SpecHelpers
  def table_exists?(name)
    if ActiveRecord::VERSION::MAJOR == 5
      ActiveRecord::Base.connection.data_source_exists?(name)
    else
      ActiveRecord::Base.connection.table_exists?(name)
    end
  end

  def table_has_column?(table, column)
    !ActiveRecord::Base.connection.select_values("desc #{table}").grep(column).empty?
  end

  def migrator(direction = :up, path = 'migrations', target_version = nil)
    migration_path = File.join(File.dirname(__FILE__), "/", path)
    if ActiveRecord::VERSION::STRING >= "5.2.0"
      migrations = ActiveRecord::MigrationContext.new(migration_path).migrations
      ActiveRecord::Migrator.new(direction, migrations, target_version)
    elsif ActiveRecord::VERSION::MAJOR >= 4
      migrations = ActiveRecord::Migrator.migrations(migration_path)
      ActiveRecord::Migrator.new(direction, migrations, target_version)
    else
      ActiveRecord::Migrator.new(direction, migration_path, target_version)
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
      assert_using_database('ars_test', Ticket)
    end
  end
end

module PhenixHelper
  # create all databases and then tear them down after test
  # avoid doing any shard switching while preparing our databases
  def with_phenix
    before do
      ActiveRecord::Base.stubs(:with_default_shard).yields

      # Populate unsharded databases
      Phenix.configure do |config|
        config.schema_path = File.join(Dir.pwd, 'test', 'unsharded_schema.rb')
        config.skip_database = lambda do |name, _|
          %w[test_shard_0 test_shard_0_slave test_shard_1 test_shard_1_slave].include?(name)
        end
      end
      Phenix.rise!(with_schema: true)

      # Populate sharded databases
      Phenix.configure do |config|
        config.schema_path = File.join(Dir.pwd, 'test', 'sharded_schema.rb')
        config.skip_database = lambda do |name, _|
          %w[test test_slave test2 test2_slave].include?(name)
        end
      end
      Phenix.rise!(with_schema: true)

      ActiveRecord::Base.unstub(:with_default_shard)
    end

    after do
      Phenix.burn!
    end
  end
end
Minitest::Spec.extend(PhenixHelper)
