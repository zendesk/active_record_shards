# frozen_string_literal: true

# ActiveRecord expects adapter definition to be under active_record/connection_adapter in the LOAD_PATH, see
# https://github.com/rails/rails/blob/fdf3f0b9306ba8145e6e3acb84a50e5d23dfe48c/activerecord/lib/active_record/connection_adapters/connection_specification.rb#L168

require "active_record"
require "active_record/connection_adapters/mysql2_adapter"
require "mysql2"

module ActiveRecord
  class Base
    def self.mysql2_fake_connection(config)
      # Based on `mysql2_connection`: https://github.com/rails/rails/blob/fdf3f0b9306ba8145e6e3acb84a50e5d23dfe48c/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L12
      config = config.symbolize_keys
      config[:flags] ||= 0

      if config[:flags].is_a?(Array)
        config[:flags].push("FOUND_ROWS")
      else
        config[:flags] |= Mysql2::Client::FOUND_ROWS
      end

      client = Mysql2::Client.new(config)
      ConnectionAdapters::Mysql2FakeAdapter.new(client, logger, nil, config)
    end
  end

  module ConnectionAdapters
    class Mysql2FakeAdapter < Mysql2Adapter
    end
  end
end
