# frozen_string_literal: true

module ActiveRecordShards
  module AssociationCollectionConnectionSelection
    def on_replica_if(condition)
      condition ? on_replica : self
    end

    def on_replica_unless(condition)
      on_replica_if(!condition)
    end

    def on_primary_if(condition)
      condition ? on_primary : self
    end

    def on_primary_unless(condition)
      on_primary_if(!condition)
    end

    def on_replica
      PrimaryReplicaProxy.new(self, :replica)
    end

    def on_primary
      PrimaryReplicaProxy.new(self, :primary)
    end

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
  end
end
