module ActiveRecordShards
  module AssociationCollectionConnectionSelection
    def on_slave_if(condition)
      condition ? on_slave : self
    end

    def on_slave_unless(condition)
      on_slave_if(!condition)
    end

    def on_slave
      SlaveProxy.new(self)
    end

    class SlaveProxy
      def initialize(association_collection)
        @association_collection = association_collection
      end

      def method_missing(method, *args, &block)
        @association_collection.proxy_reflection.klass.on_slave_block { @association_collection.send(method, *args, &block) }
      end
    end
  end
end
