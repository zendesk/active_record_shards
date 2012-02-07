module ActiveRecordShards
  module AssociationCollectionConnectionSelection
    def on_slave_if(condition)
      condition ? on_slave : self
    end

    def on_slave_unless(condition)
      on_slave_if(!condition)
    end

    def on_master_if(condition)
      condition ? on_master : self
    end

    def on_master_unless(condition)
      on_master_if(!condition)
    end

    def on_slave
      MasterSlaveProxy.new(self, :slave)
    end

    def on_master
      MasterSlaveProxy.new(self, :master)
    end

    class MasterSlaveProxy
      def initialize(association_collection, which)
        @association_collection = association_collection
        @which = which
      end

      def method_missing(method, *args, &block)
        # would love to not rely on version here, unfortunately @association_collection
        # is a sensitive little bitch of an object.
        if ActiveRecord::VERSION::MAJOR >= 3
          reflection = @association_collection.proxy_association.reflection
        else
          reflection = @association_collection.proxy_reflection
        end

        reflection.klass.on_cx_switch_block(@which) { @association_collection.send(method, *args, &block) }
      end
    end
  end
end
