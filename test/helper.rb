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
require 'support/db_helper'
require 'logger'

require 'pry-byebug'

RAILS_ENV = "test"
ENV["RAILS_ENV"] = RAILS_ENV

ActiveRecord::Base.logger = Logger.new(__dir__ + "/test.log")
ActiveSupport.test_order = :sorted
ActiveSupport::Deprecation.behavior = :silence

BaseMigration = ActiveRecord::Migration[4.2]

require 'active_support/test_case'

# support multiple before/after blocks per example
module SpecDslPatch
  def before(_type = nil, &block)
    prepend(
      Module.new do
        define_method(:setup) do
          super()
          instance_exec(&block)
        end
      end
    )
  end

  def after(_type = nil, &block)
    prepend(
      Module.new do
        define_method(:teardown) do
          instance_exec(&block)
          super()
        end
      end
    )
  end
end
Minitest::Spec.singleton_class.prepend(SpecDslPatch)

module RakeSpecHelpers
  def show_databases(config)
    client = Mysql2::Client.new(
      host: config['host'],
      port: config['port'],
      username: config['username'],
      password: config['password']
    )
    databases = client.query("SHOW DATABASES")
    databases.map { |d| d['Database'] }
  end

  def rake(name, reenable_all: true)
    if reenable_all
      Rake.application.tasks.each(&:reenable)
    else
      Rake::Task[name].reenable
    end
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
  def clear_global_connection_handler_state
    # Close active connections
    ActiveRecord::Base.connection_handler.clear_all_connections!

    # Use a fresh connection handler
    # ActiveRecord::Base.connection_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
  end

  def table_exists?(name)
    ActiveRecord::Base.connection.data_source_exists?(name)
  end

  def table_has_column?(table, column)
    !ActiveRecord::Base.connection.select_values("desc #{table}").grep(column).empty?
  end

  def migrator(direction = :up, path = 'migrations', target_version = nil)
    migration_path = File.join(__dir__, "support", path)
    migrations = ActiveRecord::MigrationContext.new(migration_path, ActiveRecord::SchemaMigration).migrations
    ActiveRecord::Migrator.new(direction, migrations, ActiveRecord::SchemaMigration, target_version)
  end
end
Minitest::Spec.include(SpecHelpers)

Minitest::Spec.extend(DbHelper)
