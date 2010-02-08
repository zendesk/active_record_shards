module ActiveRecord # :nodoc:
  # The only difference here is that we use klass.connection_pool_name
  # instead of klass.name as the pool key
  module ConnectionAdapters # :nodoc:
    class ConnectionHandler # :nodoc:

      def retrieve_connection_pool(klass)
        pool = @connection_pools[klass.connection_pool_name]
        return pool if pool
        return nil if ActiveRecord::Base == klass
        retrieve_connection_pool klass.superclass
      end

      def remove_connection(klass)
        pool = @connection_pools[klass.connection_pool_name]
        @connection_pools.delete_if { |key, value| value == pool }
        pool.disconnect! if pool
        pool.spec.config if pool
      end

    end
  end
end
