# frozen_string_literal: true
ActiveRecord::ConnectionAdapters::ConnectionHandler.class_eval do
  remove_method :retrieve_connection_pool
  def retrieve_connection_pool(klass)
    class_to_pool[klass.connection_pool_name] ||= pool_for(klass)
  end
end
