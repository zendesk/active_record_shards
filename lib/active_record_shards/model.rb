# frozen_string_literal: true

module ActiveRecordShards
  module Model
    def not_sharded
      message = "Calling not_sharded is deprecated. "\
        "Please ensure to still read from the "\
        "account db slave after removing the "\
        "call."
      if ActiveRecord::Base.logger
        ActiveRecord::Base.logger.warn(message)
      else
        Kernel.warn(message)
      end
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
      def initialize_slave
        @from_slave = !!self.class.current_slave_selection
      end

      def from_slave?
        @from_slave
      end
    end

    def self.extended(base)
      base.include(InstanceMethods)
      base.after_initialize :initialize_slave
    end
  end
end
