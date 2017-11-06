module ActiveRecordShards
  module BaseConfig
    def connection_config
      { shard: nil, sharded: false }
    end

    def connection_specification_name
      name = connection_resolver.resolve_connection_name(connection_config)

      unless configurations[name] || name == "primary"
        raise ActiveRecord::AdapterNotSpecified, "No database defined by #{name} in your database config. (configurations: #{configurations.inspect})"
      end

      name
    end

    def connection_resolver
      Thread.current[:connection_resolver] ||=
        ActiveRecordShards::ConnectionResolver.new(configurations)
    end

    def reset_connection_resolver
      Thread.current[:connection_resolver] = nil
    end
  end
end
