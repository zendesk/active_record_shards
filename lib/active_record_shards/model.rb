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

    module InstanceMethods
      def after_initialize_with_slave
        after_initialize_without_slave if respond_to?(:after_initialize_without_slave)
        @from_slave = self.class.on_slave?
      end

      def from_slave?
        @from_slave
      end
    end

    def self.extended(base)
      base.send(:include, InstanceMethods)

      if base.method_defined?(:after_initialize)
        base.alias_method_chain :after_initialize, :slave
      else
        base.send(:alias_method, :after_initialize, :after_initialize_with_slave)
      end
      
    end
  end
end