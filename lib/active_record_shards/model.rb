# frozen_string_literal: true

module ActiveRecordShards
  module Model
    module ClassMethods
      def not_sharded
        self.sharded = false
      end

      def sharded=(value)
        if self != ActiveRecord::Base && self != base_class
          raise ArgumentError, "You should only set sharded on base or abstract classes"
        end
        super(value)
      end

      def is_sharded? # rubocop:disable Naming/PredicateName
        sharded
      end

      def on_slave_by_default?
        if self == ActiveRecord::Base
          false
        else
          base = base_class
          if base.instance_variable_defined?(:@on_slave_by_default)
            base.instance_variable_get(:@on_slave_by_default)
          end
        end
      end

      def on_slave_by_default=(value)
        if self == ActiveRecord::Base
          raise ArgumentError, "Cannot set on_slave_by_default on ActiveRecord::Base"
        else
          base_class.instance_variable_set(:@on_slave_by_default, value)
        end
      end
    end

    def initialize_shard_and_slave
      @from_slave = !!self.class.current_shard_selection.options[:slave]
      @from_shard = self.class.current_shard_selection.options[:shard]
    end

    def from_slave?
      @from_slave
    end

    def from_shard
      @from_shard
    end

    def self.included(base)
      base.class_attribute :sharded, instance_accessor: false, instance_predicate: false
      base.singleton_class.prepend(ClassMethods)
      base.after_initialize :initialize_shard_and_slave
      base.sharded = true
    end
  end
end
