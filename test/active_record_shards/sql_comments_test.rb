# frozen_string_literal: true

require_relative '../helper'
require 'active_record_shards/sql_comments'
require 'active_record/connection_adapters/mysql2_adapter'

describe ActiveRecordShards::SqlComments do
  with_fresh_databases

  class CustomAdapter < ActiveRecord::ConnectionAdapters::Mysql2Adapter
    prepend ActiveRecordShards::SqlComments::Methods
  end

  before do
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
  end

  it "adds sql comment" do
    old_logger = ActiveRecord::Base.logger
    new_logger = StringIO.new
    ActiveRecord::Base.logger = Logger.new(new_logger)
    config = Account.connection.instance_variable_get(:@config)
    custom_connection = CustomAdapter.new(Mysql2::Client.new(config), nil, nil, config)

    Account.stub :connection, custom_connection do
      Account.first
    end

    assert_includes(new_logger.string, "/* unsharded primary */")
  ensure
    ActiveRecord::Base.logger = old_logger
  end
end
