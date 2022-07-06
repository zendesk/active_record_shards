# frozen_string_literal: true

require "bundler/setup"

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)

require "active_record"
require "active_record_shards"
require "mysql2"
require "benchmark/ips"
require "support/db_helper"

RAILS_ENV = "test"
NUMBER_OF_SHARDS = 300
ActiveRecord::Base.logger = Logger.new("/dev/null")

class Account < ActiveRecord::Base
  not_sharded

  has_many :tickets
end

class Ticket < ActiveRecord::Base
  belongs_to :account
end

erb_config = <<-ERB
  <% mysql = URI(ENV['MYSQL_URL'] || 'mysql://root@127.0.0.1:3306') %>

  mysql: &MYSQL
    encoding: utf8
    adapter: mysql2
    username: <%= mysql.user %>
    host: <%= mysql.host %>
    port: <%= mysql.port %>
    password: <%= mysql.password %>
    ssl_mode: :disabled

  test:
    <<: *MYSQL
    database: ars_test
    shard_names: <%= (0...NUMBER_OF_SHARDS).to_a %>
  test_replica:
    <<: *MYSQL
    database: ars_test_replica
  <% NUMBER_OF_SHARDS.times do |shard_id| %>
  test_shard_<%= shard_id %>:
    <<: *MYSQL
    database: ars_test_shard<%= shard_id %>
  test_shard_<%= shard_id %>_replica:
    <<: *MYSQL
    database: ars_test_shard<%= shard_id %>_replica
  <% end %>
ERB

config_io = StringIO.new(erb_config)
DbHelper.drop_databases
DbHelper.create_databases
DbHelper.load_database_schemas
DbHelper.load_database_configuration(config_io)

ActiveRecord::Base.establish_connection(:test)

def unsharded_primary
  ActiveRecord::Base.on_shard(nil) do
    ActiveRecord::Base.on_primary { Account.count }
  end
end

def unsharded_replica
  ActiveRecord::Base.on_shard(nil) do
    ActiveRecord::Base.on_replica { Account.count }
  end
end

def sharded_primary
  ActiveRecord::Base.on_shard(1) do
    ActiveRecord::Base.on_primary { Ticket.count }
  end
end

def sharded_replica
  ActiveRecord::Base.on_shard(1) do
    ActiveRecord::Base.on_replica { Ticket.count }
  end
end

def switch_around
  unsharded_primary
  unsharded_replica
  sharded_primary
  sharded_replica
end

Benchmark.ips do |x|
  x.report("#{ActiveRecord::VERSION::STRING} DB switching") { switch_around }
end

# Results using Ruby 2.7.5
#
#   5.1.7 DB switching    211.790  (± 3.8%) i/s
#   5.2.5 DB switching    213.797  (± 5.1%) i/s
#   6.0.4 DB switching    216.607  (± 4.2%) i/s

DbHelper.drop_databases
