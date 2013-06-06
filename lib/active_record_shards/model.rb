module ActiveRecordShards
  module Model
    def not_sharded
      if self == ActiveRecord::Base || self != base_class
        raise "You should only call not_sharded on direct descendants of ActiveRecord::Base"
      end
      @sharded = false
    end

    def is_sharded?
      if self == ActiveRecord::Base
        true
      elsif self == base_class
        @sharded != false
      else
        base_class.is_sharded?
      end
    end

    def on_slave_by_default?
      if self == ActiveRecord::Base
        false
      elsif self == base_class
        @on_slave_by_default
      else
        base_class.on_slave_by_default?
      end
    end

    def on_slave_by_default=(val)
      @on_slave_by_default = val
    end

    module InstanceMethods
      def after_initialize_with_slave
        after_initialize_without_slave if respond_to?(:after_initialize_without_slave)
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

      if ActiveRecord::VERSION::MAJOR >= 3
        base.after_initialize :after_initialize_with_slave
      else
        if base.method_defined?(:after_initialize)
          base.alias_method_chain :after_initialize, :slave
        else
          base.send(:alias_method, :after_initialize, :after_initialize_with_slave)
        end
      end
    end
  end
end
