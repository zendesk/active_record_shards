module ActiveRecordShards
  module ConnectionSwitcher
    def connection_specification_name
      name = current_shard_selection.resolve_connection_name(sharded: is_sharded?, configurations: configurations)

      unless configurations[name] || name == "primary"
        raise ActiveRecord::AdapterNotSpecified, "No database defined by #{name} in your database config. (configurations: #{configurations.keys.inspect})"
      end

      name
    end

    private

    def ensure_shard_connection
      # See if we've connected before. If not, call `#establish_connection`
      # so that ActiveRecord can resolve connection_specification_name to an
      # ARS connection.
      spec_name = current_shard_selection.resolve_connection_name(sharded: true, configurations: configurations)

      pool = connection_handler.retrieve_connection_pool(spec_name)
      if pool.nil?
        resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(configurations)
        spec = resolver.spec(spec_name.to_sym, spec_name)
        connection_handler.establish_connection(spec)
      end
    end
  end
end
