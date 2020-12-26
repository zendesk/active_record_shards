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

    def on_primary_if(condition)
      condition ? on_primary : self
    end
    alias_method :on_master_if, :on_primary_if

    def on_primary_unless(condition)
      on_primary_if(!condition)
    end
    alias_method :on_master_unless, :on_primary_unless

    def on_replica
      PrimaryReplicaProxy.new(self, :replica)
    end
    alias_method :on_slave, :on_replica

    def on_primary
      PrimaryReplicaProxy.new(self, :primary)
    end
    alias_method :on_master, :on_primary

    class PrimaryReplicaProxy
      def initialize(association_collection, which)
        @association_collection = association_collection
        @which = which
      end

      def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissingSuper, Style/MissingRespondToMissing
        reflection = @association_collection.proxy_association.reflection
        reflection.klass.on_cx_switch_block(@which) { @association_collection.send(method, *args, &block) }
      end
    end

    MasterSlaveProxy = PrimaryReplicaProxy
  end
end
