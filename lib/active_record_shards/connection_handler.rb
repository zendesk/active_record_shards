# frozen_string_literal: true
ActiveRecord::ConnectionAdapters::ConnectionHandler.class_eval do
  if ActiveRecord::VERSION::MAJOR >= 4
    def retrieve_connection_pool(klass)
      class_to_pool[klass.connection_pool_name] ||= pool_for(klass)
    end
  else
    def retrieve_connection_pool(klass)
      (@class_to_pool || @connection_pools)[klass.connection_pool_name]
    end
  end
end
