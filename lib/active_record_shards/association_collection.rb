module ActiveRecord # :nodoc:
  module Associations
    class AssociationCollection < AssociationProxy #:nodoc:
      module Replica
        def on_slave
          with_replica(:slave)
        end

        def on_slave_if(condition)
          condition ? on_slave : self
        end

        def on_slave_unless(condition)
          on_slave_if(!condition)
        end

        def with_replica(replica_name)
          Proxy.new(self, replica_name)
        end

        class Proxy
          def initialize(association_collection, replica)
            @association_collection = association_collection
            @replica = replica
          end

          def method_missing(method, *args, &block)
            @association_collection.proxy_reflection.klass.with_replica_block(@replica) { @association_collection.send(method, *args, &block) }
          end
        end
      end
    end
  end
end
