ActiveRecord::ConnectionAdapters::ConnectionHandler.class_eval do
  def retrieve_connection_pool(klass)
    class_to_pool[klass.connection_pool_name] ||= pool_for(klass)
  end
end
