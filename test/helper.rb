require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/rg'

require 'mocha/mini_test'
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

RAILS_ENV = "test"

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/test.log")
ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveSupport.test_order = :sorted if ActiveSupport.respond_to?(:test_order=)

def recreate_databases
  ActiveRecord::Base.configurations.each do |name, conf|
    `echo "drop DATABASE if exists #{conf['database']}" | mysql --user=#{conf['username']}`
    `echo "create DATABASE #{conf['database']}" | mysql --user=#{conf['username']}`
  end
end

def init_schema
  recreate_databases
  ActiveRecord::Base.configurations.each do |name, conf|
    ActiveRecord::Base.establish_connection(name.to_sym)
    load(File.dirname(__FILE__) + "/schema.rb")
  end
end

init_schema

require 'models'

require 'active_support/test_case'
class Minitest::Spec
  def clear_databases
    ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

    ActiveRecord::Base.configurations.each do |name, conf|
      ActiveRecord::Base.establish_connection(name.to_sym)
      ActiveRecord::Base.connection.execute("DELETE FROM accounts") rescue nil
      ActiveRecord::Base.connection.execute("DELETE FROM tickets") rescue nil
    end
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
  end

  def show_databases(config)
    client = Mysql2::Client.new(host: config['test']['host'],
      username: config['test']['username'])
    databases = client.query("SHOW DATABASES")
    databases.map{ |d| d['Database'] }
  end

  def rake(name)
    Rake::Task[name].reenable
    Rake::Task[name].invoke
  end

  def assert_using_master_db
    assert_using_database('ars_test')
  end

  def assert_using_slave_db
    assert_using_database('ars_test_slave')
  end

  def assert_using_database(db_name, model = ActiveRecord::Base)
    assert_equal(db_name, model.connection.current_database)
  end

  def table_has_column?(table, column)
    !ActiveRecord::Base.connection.select_values("desc #{table}").grep(column).empty?
  end
end
