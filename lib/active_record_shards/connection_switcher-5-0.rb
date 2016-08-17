module ActiveRecordShards
  module ConnectionSwitcher
    def connection_specification_name
      name = current_shard_selection.resolve_connection_name(sharded: is_sharded?, configurations: configurations)

      raise "No configuration found for #{name}" unless configurations[name] || name == "primary"
      name
    end

    private

    def ensure_shard_connection
      # See if we've connected before. If not, call `#establish_connection`
      # so that ActiveRecord can resolve connection_specification_name to an
      # ARS connection.
      spec_name = connection_specification_name

      pool = connection_handler.retrieve_connection_pool(spec_name)
      if pool.nil?
        resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new configurations
        spec = resolver.spec(spec_name.to_sym, spec_name)
        connection_handler.establish_connection spec
      end
    end
  end
end
