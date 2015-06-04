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
    injected_module = Module.new
    method_names.each do |method_name|
      injected_module.send(:define_method, method_name) do |*args|
        unless args[0].is_a? ConnectionPoolNameDecorator
          name = if args[0].is_a? String
                   args[0]
                 else
                   args[0].connection_pool_name
                 end
          args[0] = ConnectionPoolNameDecorator.new(name)
        end
        super(*args)
      end
    end
    ActiveRecord::ConnectionAdapters::ConnectionHandler.send(:prepend, injected_module)
  end
end
