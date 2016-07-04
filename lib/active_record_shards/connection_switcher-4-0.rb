module ActiveRecordShards
  module ConnectionSwitcher

    # Name of the connection pool. Used by ConnectionHandler to retrieve the current connection pool.
    def connection_pool_name # :nodoc:
      name = current_shard_selection.shard_name(self)

      if configurations[name].nil? && on_slave?
        current_shard_selection.shard_name(self, false)
      else
        name
      end
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

        establish_shard_connection unless connected_to_shard?
      end
    end

    def establish_shard_connection
      name = connection_pool_name
      spec = configurations[name]

      raise ActiveRecord::AdapterNotSpecified.new("No database defined by #{name} in database.yml") if spec.nil?

      # in 3.2 rails is asking for a connection pool in a map of these ConnectionSpecifications.  If we want to re-use connections,
      # we need to re-use specs.

      # note that since we're subverting the standard establish_connection path, we have to handle the funky autoloading of the
      # connection adapter ourselves.
      specification_cache[name] ||= begin
        if ActiveRecord::VERSION::STRING >= '4.1.0'
          resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new configurations
          resolver.spec(spec)
        else
          resolver = ActiveRecordShards::ConnectionSpecification::Resolver.new spec, configurations
          resolver.spec
        end
      end

      if ActiveRecord::VERSION::MAJOR >= 4
        connection_handler.establish_connection(self, specification_cache[name])
      else
        connection_handler.establish_connection(connection_pool_name, specification_cache[name])
      end
    end

    def specification_cache
      @@specification_cache ||= {}
    end

    def connection_pool_key
      specification_cache[connection_pool_name]
    end

    def connected_to_shard?
      if ActiveRecord::VERSION::MAJOR >= 4
        specs_to_pools = Hash[connection_handler.connection_pool_list.map { |pool| [pool.spec, pool] }]
      else
        specs_to_pools = connection_handler.connection_pools
      end

      specs_to_pools.has_key?(connection_pool_key)
    end

    def autoload_adapter(adapter_name)
      begin
        gem "activerecord-#{adapter_name}-adapter"
        require "active_record/connection_adapters/#{adapter_name}_adapter"
      rescue LoadError
        begin
          require "active_record/connection_adapters/#{adapter_name}_adapter"
        rescue LoadError
          raise "Please install the #{adapter_name} adapter: `gem install activerecord-#{adapter_name}-adapter` (#{$!})"
        end
      end

      if !ActiveRecord::Base.respond_to?(adapter_name + "_connection")
        raise AdapterNotFound, "database configuration specifies nonexistent #{adapter_name} adapter"
      end
    end
  end
end
