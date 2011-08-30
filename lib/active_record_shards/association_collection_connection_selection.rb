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
        case @which
          when :slave
            @association_collection.proxy_reflection.klass.on_slave_block { @association_collection.send(method, *args, &block) }
          when :master
            @association_collection.proxy_reflection.klass.on_master_block { @association_collection.send(method, *args, &block) }
        end
      end
    end
  end
end
