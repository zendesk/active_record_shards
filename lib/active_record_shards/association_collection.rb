module ActiveRecord # :nodoc:
  module Associations
    class AssociationCollection < AssociationProxy #:nodoc:
      module Replica
        def with_slave
          with_replica(:slave)
        end

        def with_master
          with_replica(nil)
        end

        def with_slave_if(condition)
          condition ? with_slave : with_master
        end

        def with_slave_unless(condition)
          with_slave_if(!condition)
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
