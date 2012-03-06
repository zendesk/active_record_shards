require 'rubygems'
require 'bundler'
Bundler.setup
Bundler.require(:default, :development)

if defined?(Debugger)
  ::Debugger.start
  ::Debugger.settings[:autoeval] = true if ::Debugger.respond_to?(:settings)
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_record_shards'
require 'logger'

RAILS_ENV = "test"

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/test.log")
ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

def init_schema
  ActiveRecord::Base.configurations.each do |name, conf|
    `echo "drop DATABASE if exists #{conf['database']}" | mysql --user=#{conf['username']}`
    `echo "create DATABASE #{conf['database']}" | mysql --user=#{conf['username']}`
    ActiveRecord::Base.establish_connection(name)
    load(File.dirname(__FILE__) + "/schema.rb")
  end
end
init_schema

require 'models'

require 'active_support/test_case'
class ActiveSupport::TestCase
  def clear_databases
    ActiveRecord::Base.configurations.each do |name, conf|
      ActiveRecord::Base.establish_connection(name)
      ActiveRecord::Base.connection.execute("DELETE FROM accounts")
      ActiveRecord::Base.connection.execute("DELETE FROM tickets")
    end
    ActiveRecord::Base.establish_connection(RAILS_ENV)
  end
  setup :clear_databases

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
