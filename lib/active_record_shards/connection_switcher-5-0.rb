module ActiveRecordShards
  module ConnectionSwitcher
    def connection_specification_name
      name = current_shard_selection.resolve_connection_name(sharded: is_sharded?, configurations: self.configurations)

      raise "No configuration found for #{name}" unless configurations[name] || name == "primary"
      name
    end

    private

    def switch_connection(options)
      if options.any?
        if options.has_key?(:slave)
          current_shard_selection.on_slave = options[:slave]
        end

        if options.has_key?(:shard)
          current_shard_selection.shard = options[:shard]
        end

        probe_pool
      end
    end

    def probe_pool
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
