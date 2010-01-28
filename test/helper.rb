require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'replica'
require 'models'

RAILS_ENV = "test"

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/test.log")
ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

ActiveRecord::Base.establish_connection('test_slave')
load(File.dirname(__FILE__) + "/schema.rb")

ActiveRecord::Base.establish_connection('test')
load(File.dirname(__FILE__) + "/schema.rb")


class Test::Unit::TestCase

  def assert_using_master_db(klass)
    assert_equal('replica_test', klass.connection.instance_variable_get(:@config)[:database])
  end

  def assert_using_slave_db(klass)
    assert_equal('replica_test_slave', klass.connection.instance_variable_get(:@config)[:database])
  end

end
