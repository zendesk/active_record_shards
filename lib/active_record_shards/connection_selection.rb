module ActiveRecordShards
  module ConnectionSelection

    def on_slave_if(condition, &block)
      condition ? on_slave(&block) : yield
    end

    def on_slave_unless(condition, &block)
      on_slave_if(!condition, &block)
    end

    # Name of the connection pool. Used by ConnectionHandler to retrieve the current connection pool.
    def connection_pool_name # :nodoc:
      replica = current_replica_name
      if replica
        "#{name}_#{replica}"
      elsif self == ActiveRecord::Base
        name
      else
        superclass.connection_pool_name
      end
    end

    # Executes queries using the slave database. Fails over to master if no slave is found.
    # if you want to execute a block of code on the slave you can go:
    #   Account.on_slave do
    #     Account.first
    #   end
    # the first account will be found on the slave DB
    #
    # For one-liners you can simply do
    #   Account.on_slave.first
    def on_slave(&block)
      if block_given?
        on_slave_block(&block)
      else
        SlaveProxy.new(self)
      end
    end

    def on_slave_block(&block)
      old_replica_name = current_replica_name
      begin
        self.current_replica_name = :slave
      rescue ActiveRecord::AdapterNotSpecified => e
        self.current_replica_name = old_replica_name
        logger.warn("Failed to establish replica connection: #{e.message} - defaulting to master")
      end
      with_scope({:find => {:readonly => current_replica_name.present?}}, :merge, &block)
    ensure
      self.current_replica_name = old_replica_name
    end

    private

    def current_replica_name
      Thread.current[replica_key]
    end

    def current_replica_name=(new_replica_name)
      Thread.current[replica_key] = new_replica_name

      establish_replica_connection(new_replica_name) unless connected_to_replica?
    end

    def establish_replica_connection(replica_name)
      name = replica_name ? "#{RAILS_ENV}_#{replica_name}" : RAILS_ENV
      spec = configurations[name]
      raise ActiveRecord::AdapterNotSpecified.new("No database defined by #{name} in database.yml") if spec.nil?

      connection_handler.establish_connection(connection_pool_name, ActiveRecord::Base::ConnectionSpecification.new(spec, "#{spec['adapter']}_connection"))
    end

    def connected_to_replica?
      connection_handler.connection_pools.has_key?(connection_pool_name)
    end

    def replica_key
      @replica_key ||= "#{name}_replica"
    end

    class SlaveProxy
      def initialize(target)
        @target = target
      end

      def method_missing(method, *args, &block)
        @target.on_slave_block { @target.send(method, *args, &block) }
      end
    end
  end
end
