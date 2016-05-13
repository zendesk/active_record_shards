# frozen_string_literal: true
module ActiveRecordShards
  ConnectionPoolNameDecorator = Struct.new(:name)

  # It overrides given connection handler methods (they differ depend on
  # Rails version).
  #
  # It takes the first argument, ActiveRecord::Base object or
  # String (connection_pool_name), converts it in Struct object and
  # passes to the original method.
  #
  # Example:
  #   methods_to_override = [:establish_connection, :remove_connection]
  #   ActiveRecordShards.override_connection_handler_methods(methods_to_override)
  #
  def self.override_connection_handler_methods(method_names)
    method_names.each do |method_name|
      ActiveRecord::ConnectionAdapters::ConnectionHandler.class_eval do
        define_method("#{method_name}_with_connection_pool_name") do |*args|
          unless args[0].is_a? ConnectionPoolNameDecorator
            name = if args[0].is_a? String
                     args[0]
                   else
                     args[0].connection_pool_name
                   end
            args[0] = ConnectionPoolNameDecorator.new(name)
          end
          send("#{method_name}_without_connection_pool_name", *args)
        end
        alias_method :"#{method_name}_without_connection_pool_name", method_name
        alias_method method_name, :"#{method_name}_with_connection_pool_name"
      end
    end
  end
end
