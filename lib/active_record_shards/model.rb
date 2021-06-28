# frozen_string_literal: true

module ActiveRecordShards
  module Model
    def not_sharded
      if self != ActiveRecord::Base && self != base_class
        raise "You should only call not_sharded on direct descendants of ActiveRecord::Base"
      end

      self.sharded = false
    end

    def is_sharded? # rubocop:disable Naming/PredicateName
      if self == ActiveRecord::Base
        sharded != false && supports_sharding?
      elsif self == base_class
        if sharded.nil?
          ActiveRecord::Base.is_sharded?
        else
          sharded != false
        end
      else
        base_class.is_sharded?
      end
    end

    def on_replica_by_default?
      if self == ActiveRecord::Base
        false
      else
        base = base_class
        if base.instance_variable_defined?(:@on_replica_by_default)
          base.instance_variable_get(:@on_replica_by_default)
        end
      end
    end

    def on_replica_by_default=(value)
      if self == ActiveRecord::Base
        raise ArgumentError, "Cannot set on_replica_by_default on ActiveRecord::Base"
      else
        base_class.instance_variable_set(:@on_replica_by_default, value)
      end
    end

    module InstanceMethods
      def initialize_shard_and_replica
        @from_replica = !!self.class.current_shard_selection.options[:replica]
        @from_shard = self.class.current_shard_selection.options[:shard]
      end

      def from_replica?
        @from_replica
      end

      def from_shard
        @from_shard
      end
    end

    def self.extended(base)
      base.send(:include, InstanceMethods)
      base.after_initialize :initialize_shard_and_replica
    end

    private

    attr_accessor :sharded
  end
end
