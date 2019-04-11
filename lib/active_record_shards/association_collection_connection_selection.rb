# frozen_string_literal: true

module ActiveRecordShards
  module AssociationCollectionConnectionSelection
    def on_replica_if(condition)
      condition ? on_replica : self
    end
    alias_method :on_slave_if, :on_replica_if

    def on_replica_unless(condition)
      on_replica_if(!condition)
    end
    alias_method :on_slave_unless, :on_replica_unless

    def on_master_if(condition)
      condition ? on_master : self
    end

    def on_master_unless(condition)
      on_master_if(!condition)
    end

    def on_replica
      MasterReplicaProxy.new(self, :replica)
    end
    alias_method :on_slave, :on_replica

    def on_master
      MasterReplicaProxy.new(self, :master)
    end

    class MasterReplicaProxy
      def initialize(association_collection, which)
        @association_collection = association_collection
        @which = which
      end

      def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissingSuper, Style/MissingRespondToMissing
        reflection = @association_collection.proxy_association.reflection
        reflection.klass.on_cx_switch_block(@which) { @association_collection.send(method, *args, &block) }
      end
    end

    MasterSlaveProxy = MasterReplicaProxy
  end
end
