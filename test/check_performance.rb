# frozen_string_literal: true

require "bundler/setup"

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)

require "active_record"
require "active_record_shards"
require "mysql2"
require 'benchmark/ips'

RAILS_ENV = "test"

# ActiveRecord::Base.logger = Logger.new(__dir__ + "/test.log")
ActiveRecord::Base.logger = Logger.new("/dev/null")

class Account < ActiveRecord::Base
  # attributes: id, name, updated_at, created_at
  not_sharded

  has_many :tickets
end

class Ticket < ActiveRecord::Base
  # attributes: id, title, account_id, updated_at, created_at
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
  shard_names: [0, 1]

test_replica:
  <<: *MYSQL
  database: ars_test_replica

test_shard_0:
  <<: *MYSQL
  database: ars_test_shard0

test_shard_0_replica:
  <<: *MYSQL
  database: ars_test_shard0_replica

test_shard_1:
  <<: *MYSQL
  database: ars_test_shard1

test_shard_1_replica:
  <<: *MYSQL
  database: ars_test_shard1_replica
ERB

yaml_config = ERB.new(erb_config).result
ActiveRecord::Base.configurations = YAML.load(yaml_config)
ActiveRecord::Base.logger.debug "1"

ActiveRecord::Base.establish_connection(:test)
ActiveRecord::Base.logger.debug "2"

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
  x.time = 8
  x.report("#{ActiveRecord::VERSION::STRING} DB switching") { switch_around }
end
=begin
Before optimizing
Rails 5.2.5: 269 i/s
Rails 6.0.4: 255 i/s
=end
