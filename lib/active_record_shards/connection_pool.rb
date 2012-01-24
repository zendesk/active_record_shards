ActiveRecord::ConnectionAdapters::ConnectionHandler.class_eval do
  # The only difference here is that we use klass.connection_pool_name
  # instead of klass.name as the pool key
  def retrieve_connection_pool(klass)
    pool = @class_to_pool[klass.connection_pool_name]
    return pool if pool
    return nil if ActiveRecord::Base == klass
    retrieve_connection_pool klass.superclass
  end

  def remove_connection(klass)
    pool = @class_to_pool[klass.connection_pool_name]
    @class_to_pool.delete_if { |key, value| value == pool }
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