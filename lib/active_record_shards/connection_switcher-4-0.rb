module ActiveRecordShards
  module ConnectionSwitcher
    # Name of the connection pool. Used by ConnectionHandler to retrieve the current connection pool.
    def connection_pool_name # :nodoc:
      name = current_shard_selection.shard_name(self)

      # e.g. if "production_slave" is not defined in `Configuration`, fall back to "production"
      if configurations[name].nil? && on_slave?
        current_shard_selection.shard_name(self, false)
      else
        name
      end
    end

    private

    def ensure_shard_connection
      establish_shard_connection unless connected_to_shard?
    end

    def establish_shard_connection
      name = connection_pool_name
      spec = configurations[name]

      if spec.nil?
        raise ActiveRecord::AdapterNotSpecified, "No database defined by #{name} in your database config. (configurations: #{configurations.keys.inspect})"
      end

      specification_cache[name] ||= begin
        resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new configurations
        resolver.spec(spec)
      end

      connection_handler.establish_connection(self, specification_cache[name])
    end

    def specification_cache
      @@specification_cache ||= {}
    end

    # Helper method to clear global state when testing.
    def clear_specification_cache
      @@specification_cache = {}
    end

    def connection_pool_key
      specification_cache[connection_pool_name]
    end

    def connected_to_shard?
      specs_to_pools = Hash[connection_handler.connection_pool_list.map { |pool| [pool.spec, pool] }]

      specs_to_pools.key?(connection_pool_key)
    end
  end
end
