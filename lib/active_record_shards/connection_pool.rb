ActiveRecord::ConnectionAdapters::ConnectionHandler.class_eval do
  # The only difference here is that we use klass.connection_pool_name
  # instead of klass.name as the pool key
  def retrieve_connection_pool(klass)
    pool = (@class_to_pool || @connection_pools)[klass.connection_pool_name]
    return pool if pool
    return nil if ActiveRecord::Base == klass
    retrieve_connection_pool klass.superclass
  end

  def remove_connection(klass)
    # rails 2: @connection_pools is a hash of klass.name => pool
    # rails 3: @connection_pools is a hash of pool.spec => pool
    #          @class_to_pool is a hash of klass.name => pool
    #
    if @class_to_pool
      pool = @class_to_pool.delete(klass.connection_pool_name)
      @connection_pools.delete(pool.spec) if pool
    else
      pool = @connection_pools.delete(klass.connection_pool_name)
      @connection_pools.delete_if { |key, value| value == pool }
    end

    return nil unless pool

    pool.disconnect! if pool
    pool.spec.config if pool
  end
end

ActiveRecord::Base.singleton_class.class_eval do
  def establish_connection_with_connection_pool_name(spec = nil)
    case spec
    when ActiveRecord::Base::ConnectionSpecification
      connection_handler.establish_connection(connection_pool_name, spec)
    else
      establish_connection_without_connection_pool_name(spec)
    end
  end
  alias_method_chain :establish_connection, :connection_pool_name
end

# backport improved connection fetching from rails 3.2
if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0
  class ActiveRecord::Base
    def self.arel_engine
      @arel_engine ||= begin
        if self == ActiveRecord::Base
          ActiveRecord::Base
        else
          connection_handler.retrieve_connection_pool(self) ? self : superclass.arel_engine
        end
      end
    end
  end
end
