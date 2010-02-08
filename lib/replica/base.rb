module ActiveRecord # :nodoc:
  class Base # :nodoc:
    module Replica

      # Executes queries using the slave database. Fails over to master if no slave is found.
      # if you want to execute a block of code on the slave you can go:
      #   Account.with_slave do
      #     Account.first
      #   end
      # the first account will be found on the slave DB
      #
      # For one-liners you can simply do
      #   Account.with_slave.first
      #
      # this is the same as:
      #   Account.with_replica(:slave) do
      #     Account.first
      #   end
      def with_slave(&block)
        with_replica(:slave, &block)
      end

      # See with_slave
      def with_master(&block)
        with_replica(nil, &block)
      end

      def with_slave_if(condition, &block)
        condition ? with_slave(&block) : with_master(&block)
      end

      def with_slave_unless(condition, &block)
        with_slave_if(!condition, &block)
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

      # Specify which database to use.
      #
      # Example:
      # database.yml
      #   test_slave:
      #     adapter: mysql
      #     ...
      #
      # Account.with_replica(:slave) { Account.count }
      # Account.with_replica(:slave).count
      #
      def with_replica(replica_name, &block)
        if block_given?
          with_replica_block(replica_name, &block)
        else
          Proxy.new(self, replica_name)
        end
      end

      def with_replica_block(replica_name, &block)
        old_replica_name = current_replica_name
        begin
          self.current_replica_name = replica_name
        rescue ActiveRecord::AdapterNotSpecified => e
          self.current_replica_name = old_replica_name
          logger.warn("Failed to establish replica connection: #{e.message} - defaulting to master")
        end
        yield
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
          raise AdapterNotSpecified.new("No database defined by #{name} in database.yml") if spec.nil?

          connection_handler.establish_connection(connection_pool_name, ConnectionSpecification.new(spec, "#{spec['adapter']}_connection"))
        end

        def connected_to_replica?
          connection_handler.connection_pools.has_key?(connection_pool_name)
        end

        def replica_key
          @replica_key ||= "#{name}_replica"
        end

        class Proxy
          def initialize(target, replica)
            @target = target
            @replica = replica
          end

          def method_missing(method, *args, &block)
            @target.with_replica_block(@replica) { @target.send(method, *args, &block) }
          end
        end
    end
  end
end
