# frozen_string_literal: true

module ActiveRecordShards
  module Model
    def not_sharded
      ActiveRecord::Base.logger.warn("Calling not_sharded is deprecated. "\
                                     "Please ensure to still read from the "\
                                     "account db slave after removing the "\
                                     "call.")
    end

    def is_sharded? # rubocop:disable Naming/PredicateName
      false
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

    module InstanceMethods
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
    end

    def self.extended(base)
      base.send(:include, InstanceMethods)
      base.after_initialize :initialize_shard_and_slave
    end
  end
end
